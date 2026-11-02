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
import { notifyRoomMembers } from '../notifications';
import { createHash } from 'node:crypto';

/**
 * Applies expense mutations and keeps derived summaries and activity logs in
 * sync with the source expense document.
 *
 * Each mutation uses a Firestore transaction so a retry cannot leave the
 * expense, counters, and activity log in different states. Callable input has
 * already been validated by the schema before it reaches this service.
 */
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
        // Callable retries are safe when the same expense ID carries the same
        // payload; a different payload is rejected instead of overwriting it.
        const previous = this.readPersisted(existing.data());
        if (!sameExpense(previous, input)) {
          throw new HttpsError('already-exists', 'This expense ID is already in use.');
        }
        return;
      }
      this.expenses.create(transaction, expenseRef, this.withCreateTimestamps(input));
      this.applyContribution(transaction, roomRef, input, 1);
      this.logActivity(transaction, roomRef, 'expense_created', uid, input.expenseId, `create_${input.expenseId}`, {
        expenseTitle: input.note ?? input.category,
        amountInCents: input.amountInCents,
        category: input.category,
      });
    });
    await this.notifyExpense(
      input,
      uid,
      'expense_created',
      `expense_created_${input.expenseId}`,
    );
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
      if (sameExpense(previous, input)) return;
      // Remove the old contribution before applying the new one so summary
      // counters remain correct when amount, payer, date, or split changes.
      const update: Record<string, unknown> = {
        ...input,
        updatedAt: FieldValue.serverTimestamp(),
      };
      if (previous.createdAt !== undefined) update.createdAt = previous.createdAt;
      this.expenses.update(transaction, expenseRef, update);
      this.applyContribution(transaction, roomRef, previous, -1);
      this.applyContribution(transaction, roomRef, input, 1);
      const metadata: Record<string, unknown> = {
        expenseTitle: input.note ?? input.category,
        category: input.category,
      };
      if (previous.amountInCents !== input.amountInCents) {
        metadata['previousAmountInCents'] = previous.amountInCents;
        metadata['newAmountInCents'] = input.amountInCents;
      }
      if (previous.note !== input.note) {
        metadata['previousExpenseTitle'] = previous.note ?? previous.category;
        metadata['newExpenseTitle'] = input.note ?? input.category;
      }
      this.logActivity(
        transaction,
        roomRef,
        'expense_updated',
        uid,
        input.expenseId,
        `update_${this.updateEventKey(input)}`,
        metadata,
      );
    });
    await this.notifyExpense(
      input,
      uid,
      'expense_updated',
      `expense_updated_${input.expenseId}_${this.updateEventKey(input)}`,
    );
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
      this.logActivity(transaction, roomRef, 'expense_deleted', uid, expenseId, `delete_${expenseId}`, {
        expenseTitle: previous.note ?? previous.category,
        amountInCents: previous.amountInCents,
        category: previous.category,
      });
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

  private logActivity(
    transaction: Transaction,
    roomRef: DocumentReference,
    type: 'expense_created' | 'expense_updated' | 'expense_deleted',
    actorUserId: string,
    expenseId: string,
    eventId: string,
    metadata: Record<string, unknown>,
  ): void {
    const activityRef = roomRef
      .collection('activityLogs')
      .doc(`${type}_${expenseId}_${eventId}`);
    transaction.create(activityRef, {
      type,
      actorUserId,
      targetType: 'expense',
      targetId: expenseId,
      expenseId,
      createdAt: FieldValue.serverTimestamp(),
      metadata,
    });
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

  private async notifyExpense(
    input: ExpenseInput,
    actorUserId: string,
    type: 'expense_created' | 'expense_updated',
    eventId: string,
  ): Promise<void> {
    try {
      const [room, profile] = await Promise.all([
        this.db.collection('rooms').doc(input.roomId).get(),
        this.db.collection('users').doc(actorUserId).get(),
      ]);
      const roomName = typeof room.get('name') === 'string' ? room.get('name') : 'your room';
      const actorName = typeof profile.get('displayName') === 'string'
        ? profile.get('displayName')
        : 'A member';
      const currency = typeof room.get('currency') === 'string' ? room.get('currency') : 'MYR';
      const amount = `${currency} ${(input.amountInCents / 100).toFixed(2)}`;
      await notifyRoomMembers(this.db, input.roomId, actorUserId, eventId, {
        title: type === 'expense_created' ? `New expense in ${roomName}` : `Expense updated in ${roomName}`,
        body: `${actorName} added ${input.category} - ${amount}`,
        data: {
          type,
          roomId: input.roomId,
          expenseId: input.expenseId,
        },
      });
    } catch (error) {
      console.error('Unable to deliver expense notification', { type, roomId: input.roomId, error });
    }
  }

  private updateEventKey(input: ExpenseInput): string {
    return createHash('sha256')
      .update(JSON.stringify({
        amountInCents: input.amountInCents,
        category: input.category,
        note: input.note,
        expenseDate: input.expenseDate.toMillis(),
        splitAmountsInCents: input.splitAmountsInCents,
      }))
      .digest('hex')
      .slice(0, 16);
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