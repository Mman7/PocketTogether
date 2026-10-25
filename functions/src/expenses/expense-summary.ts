import {
  DocumentReference,
  FieldValue,
  Firestore,
  Timestamp,
  Transaction,
} from 'firebase-admin/firestore';

import { ExpenseInput, PersistedExpense, SummaryTarget } from './expense.types';

/** Calculates summary deltas and persists them within the caller's transaction. */
export class ExpenseSummary {
  constructor(private readonly db?: Firestore) {}

  contribution(
    expense: ExpenseInput | PersistedExpense,
    direction: 1 | -1,
  ): SummaryTarget[] {
    const delta = this.checkedDelta(expense.amountInCents, direction);
    const month = this.monthId(expense.expenseDate);
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
  }

  apply(
    transaction: Transaction,
    roomRef: DocumentReference,
    target: SummaryTarget,
  ): void {
    transaction.set(
      this.reference(roomRef, target),
      {
        [target.field]: FieldValue.increment(target.delta),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  async existing(roomRef: DocumentReference): Promise<DocumentReference[]> {
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
  }

  async persistRebuilt(
    roomRef: DocumentReference,
    existing: DocumentReference[],
    targets: SummaryTarget[],
  ): Promise<void> {
    // Rebuilds use bounded batches; run them in a controlled maintenance window.
    const db = this.db;
    if (!db) throw new Error('Firestore is required to persist rebuilt summaries.');
    let batch = db.batch();
    let writes = 0;
    const commit = async (): Promise<void> => {
      if (writes === 0) return;
      await batch.commit();
      batch = db.batch();
      writes = 0;
    };
    for (const reference of existing) {
      batch.delete(reference);
      writes++;
      if (writes === 400) await commit();
    }
    for (const target of targets) {
      batch.set(this.reference(roomRef, target), {
        [target.field]: target.delta,
        updatedAt: FieldValue.serverTimestamp(),
      });
      writes++;
      if (writes === 400) await commit();
    }
    await commit();
  }

  private reference(roomRef: DocumentReference, target: SummaryTarget): DocumentReference {
    if (target.path[0] === 'members') {
      return roomRef
        .collection('members')
        .doc(target.path[1])
        .collection(target.path[2])
        .doc(target.path[3]);
    }
    return roomRef.collection(target.path[0]).doc(target.path[1]);
  }

  private monthId(date: Timestamp): string {
    const value = date.toDate();
    return `${value.getUTCFullYear()}-${String(value.getUTCMonth() + 1).padStart(2, '0')}`;
  }

  private checkedDelta(amount: number, direction: 1 | -1): number {
    const delta = amount * direction;
    if (!Number.isSafeInteger(delta)) {
      throw new Error('Expense summary delta exceeds the safe integer limit.');
    }
    return delta;
  }
}