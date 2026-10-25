import {
  DocumentReference,
  FieldValue,
  Firestore,
  Transaction,
} from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { ExpenseSummary } from './expense-summary';
import { ExpenseRepository } from './expense.repository';
import { parsePersistedExpense } from './expense.schema';
import {
  ExpenseInput,
  PersistedExpense,
  RebuildResult,
  SummaryTarget,
} from './expense.types';

export class ExpenseService {
  constructor(
    private readonly db: Firestore,
    private readonly expenses = new ExpenseRepository(db),
    private readonly summary = new ExpenseSummary(db),
  ) {}

  async create(input: ExpenseInput, uid: string): Promise<{ expenseId: string }> {
    const roomRef = this.expenses.roomRef(input.roomId);
    const expenseRef = this.expenses.expenseRef(input.roomId, input.expenseId);
    await this.db.runTransaction(async (transaction) => {
      await this.assertRoomMember(transaction, roomRef, uid, input);
      const existing = await this.expenses.readExpense(transaction, expenseRef);
      if (existing.exists) {
        const previous = this.readPersisted(existing.data());
        if (!sameExpense(previous, input)) {
          throw new HttpsError('already-exists', 'This expense ID is already in use.');
        }
        return;
      }
      this.expenses.create(transaction, expenseRef, this.withCreateTimestamps(input));
      this.applyContribution(transaction, roomRef, input, 1);
    });
    return { expenseId: input.expenseId };
  }

  async update(input: ExpenseInput, uid: string): Promise<{ expenseId: string }> {
    const roomRef = this.expenses.roomRef(input.roomId);
    const expenseRef = this.expenses.expenseRef(input.roomId, input.expenseId);
    await this.db.runTransaction(async (transaction) => {
      const snapshot = await this.expenses.readExpense(transaction, expenseRef);
      if (!snapshot.exists) throw new HttpsError('not-found', 'Expense not found.');
      const previous = this.readPersisted(snapshot.data());
      if (input.createdByUserId !== previous.createdByUserId) {
        throw new HttpsError('invalid-argument', 'The original expense creator cannot change.');
      }
      await this.assertRoomMember(transaction, roomRef, uid, input);
      const update: Record<string, unknown> = {
        ...input,
        updatedAt: FieldValue.serverTimestamp(),
      };
      if (previous.createdAt !== undefined) update.createdAt = previous.createdAt;
      this.expenses.update(transaction, expenseRef, update);
      this.applyContribution(transaction, roomRef, previous, -1);
      this.applyContribution(transaction, roomRef, input, 1);
    });
    return { expenseId: input.expenseId };
  }

  async delete(roomId: string, expenseId: string, uid: string): Promise<{ expenseId: string }> {
    const roomRef = this.expenses.roomRef(roomId);
    const expenseRef = this.expenses.expenseRef(roomId, expenseId);
    await this.db.runTransaction(async (transaction) => {
      const snapshot = await this.expenses.readExpense(transaction, expenseRef);
      if (!snapshot.exists) return;
      const previous = this.readPersisted(snapshot.data());
      await this.assertRoomMember(transaction, roomRef, uid, previous);
      this.expenses.delete(transaction, expenseRef);
      this.applyContribution(transaction, roomRef, previous, -1);
    });
    return { expenseId };
  }

  async rebuild(roomId: string): Promise<RebuildResult> {
    const roomRef = this.expenses.roomRef(roomId);
    const room = await roomRef.get();
    if (!room.exists) throw new HttpsError('not-found', 'Room not found.');
    const snapshots = await this.expenses.listExpenses(roomId);
    const expenses = snapshots.docs.map((snapshot) => this.readPersisted(snapshot.data()));
    const totals = new Map<string, SummaryTarget>();
    for (const expense of expenses) {
      for (const target of this.summary.contribution(expense, 1)) {
        const key = `${target.path.join('/')}:${target.field}`;
        const current = totals.get(key);
        if (current) {
          const total = current.delta + target.delta;
          if (!Number.isSafeInteger(total)) {
            throw new HttpsError('failed-precondition', 'Expense summaries exceed the safe integer limit.');
          }
          current.delta = total;
        }
        else totals.set(key, { ...target });
      }
    }
    await this.summary.persistRebuilt(
      roomRef,
      await this.summary.existing(roomRef),
      [...totals.values()],
    );
    return { roomId, expenseCount: expenses.length };
  }

  private applyContribution(
    transaction: Transaction,
    roomRef: DocumentReference,
    expense: ExpenseInput | PersistedExpense,
    direction: 1 | -1,
  ): void {
    for (const target of this.summary.contribution(expense, direction)) {
      this.summary.apply(transaction, roomRef, target);
    }
  }

  private async assertRoomMember(
    transaction: Transaction,
    roomRef: DocumentReference,
    uid: string,
    expense: ExpenseInput | PersistedExpense,
  ): Promise<void> {
    const room = await this.expenses.readRoom(transaction, roomRef);
    if (!room.exists) throw new HttpsError('not-found', 'Room not found.');
    const memberIds = room.get('memberIds');
    const participants = [expense.paidByUserId, ...Object.keys(expense.splitAmountsInCents)];
    if (!Array.isArray(memberIds) || !memberIds.includes(uid)) {
      throw new HttpsError('permission-denied', 'You are not a member of this room.');
    }
    if (participants.some((participant) => !memberIds.includes(participant))) {
      throw new HttpsError('invalid-argument', 'Every expense participant must be a room member.');
    }
  }

  private readPersisted(data: FirebaseFirestore.DocumentData | undefined): PersistedExpense {
    if (!data) throw new HttpsError('failed-precondition', 'Stored expense data is invalid.');
    try {
      return parsePersistedExpense(data);
    } catch (error) {
      if (error instanceof HttpsError) {
        throw new HttpsError('failed-precondition', 'Stored expense data is invalid.');
      }
      throw error;
    }
  }

  private withCreateTimestamps(input: ExpenseInput): Record<string, unknown> {
    const { roomId: _roomId, expenseId: _expenseId, ...expense } = input;
    return {
      ...expense,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };
  }
}

function sameExpense(previous: PersistedExpense, input: ExpenseInput): boolean {
  return previous.amountInCents === input.amountInCents &&
    previous.category === input.category &&
    previous.note === input.note &&
    previous.paidByUserId === input.paidByUserId &&
    previous.createdByUserId === input.createdByUserId &&
    previous.transferMethod === input.transferMethod &&
    previous.transferToUserId === input.transferToUserId &&
    previous.expenseDate.isEqual(input.expenseDate) &&
    sameSplits(previous.splitAmountsInCents, input.splitAmountsInCents);
}

function sameSplits(
  previous: Record<string, number>,
  next: Record<string, number>,
): boolean {
  const previousEntries = Object.entries(previous).sort(([a], [b]) => a.localeCompare(b));
  const nextEntries = Object.entries(next).sort(([a], [b]) => a.localeCompare(b));
  return JSON.stringify(previousEntries) === JSON.stringify(nextEntries);
}