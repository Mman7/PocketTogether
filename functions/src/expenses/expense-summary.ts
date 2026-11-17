import {
  DocumentReference,
  FieldValue,
  Firestore,
  Timestamp,
  Transaction,
} from 'firebase-admin/firestore';

import { ExpenseInput, PersistedExpense, SummaryTarget } from './expense.types';

export interface ExpenseSummary {
  contribution(expense: ExpenseInput | PersistedExpense, direction: 1 | -1): SummaryTarget[];
  apply(transaction: Transaction, roomRef: DocumentReference, target: SummaryTarget): void;
  existing(roomRef: DocumentReference): Promise<DocumentReference[]>;
  persistRebuilt(
    roomRef: DocumentReference,
    existing: DocumentReference[],
    targets: SummaryTarget[],
  ): Promise<void>;
}

/**
 * Calculates integer-cent summary deltas and persists them in the caller's
 * transaction. Summaries use `FieldValue.increment` so they stay atomic with
 * the expense write that produced them.
 */
export function createExpenseSummary(db?: Firestore): ExpenseSummary {
  return {
    contribution(expense, direction): SummaryTarget[] {
      const delta = checkedDelta(expense.amountInCents, direction);
      const month = monthId(expense.expenseDate);
      return [
        { path: ['stats', 'summary'], field: 'totalExpenseInCents', delta },
        { path: ['monthlyStats', month], field: 'totalExpenseInCents', delta },
        {
          path: ['members', expense.paidByUserId, 'stats', 'summary'],
          field: 'totalPaidInCents',
          delta,
        },
        {
          path: ['members', expense.paidByUserId, 'monthlyStats', month],
          field: 'totalPaidInCents',
          delta,
        },
      ];
    },

    apply(transaction, roomRef, target): void {
      transaction.set(
        reference(roomRef, target),
        {
          [target.field]: FieldValue.increment(target.delta),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    },

    async existing(roomRef): Promise<DocumentReference[]> {
      const references: DocumentReference[] = [
        ...(await roomRef.collection('stats').get()).docs.map((snapshot) => snapshot.ref),
        ...(await roomRef.collection('monthlyStats').get()).docs.map((snapshot) => snapshot.ref),
      ];
      const members = await roomRef.collection('members').get();
      for (const member of members.docs) {
        references.push(
          ...(await member.ref.collection('stats').get()).docs.map((snapshot) => snapshot.ref),
          ...(await member.ref.collection('monthlyStats').get()).docs.map((snapshot) => snapshot.ref),
        );
      }
      return references;
    },

    async persistRebuilt(roomRef, existing, targets): Promise<void> {
      // Firestore caps a write batch at 500 operations; 400 leaves headroom.
      if (!db) throw new Error('Firestore is required to persist rebuilt summaries.');
      const firestore = db;
      let batch = firestore.batch();
      let writes = 0;
      const commit = async (): Promise<void> => {
        if (writes === 0) return;
        await batch.commit();
        batch = firestore.batch();
        writes = 0;
      };
      for (const ref of existing) {
        batch.delete(ref);
        writes++;
        if (writes === 400) await commit();
      }
      for (const target of targets) {
        batch.set(reference(roomRef, target), {
          [target.field]: target.delta,
          updatedAt: FieldValue.serverTimestamp(),
        });
        writes++;
        if (writes === 400) await commit();
      }
      await commit();
    },
  };
}

function reference(roomRef: DocumentReference, target: SummaryTarget): DocumentReference {
  if (target.path[0] === 'members') {
    return roomRef
      .collection('members')
      .doc(target.path[1])
      .collection(target.path[2])
      .doc(target.path[3]);
  }
  return roomRef.collection(target.path[0]).doc(target.path[1]);
}

function monthId(date: Timestamp): string {
  const value = date.toDate();
  return `${value.getUTCFullYear()}-${String(value.getUTCMonth() + 1).padStart(2, '0')}`;
}

function checkedDelta(amount: number, direction: 1 | -1): number {
  const delta = amount * direction;
  if (!Number.isSafeInteger(delta)) {
    throw new Error('Expense summary delta exceeds the safe integer limit.');
  }
  return delta;
}