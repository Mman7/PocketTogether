import {
  DocumentReference,
  DocumentSnapshot,
  Firestore,
  QuerySnapshot,
  Transaction,
} from 'firebase-admin/firestore';

export interface ExpenseRepository {
  roomRef(roomId: string): DocumentReference;
  expenseRef(roomId: string, expenseId: string): DocumentReference;
  readRoom(transaction: Transaction, roomRef: DocumentReference): Promise<DocumentSnapshot>;
  readExpense(transaction: Transaction, expenseRef: DocumentReference): Promise<DocumentSnapshot>;
  create(transaction: Transaction, reference: DocumentReference, expense: Record<string, unknown>): void;
  update(transaction: Transaction, reference: DocumentReference, expense: Record<string, unknown>): void;
  delete(transaction: Transaction, reference: DocumentReference): void;
  listExpenses(roomId: string): Promise<QuerySnapshot>;
}

export function createExpenseRepository(db: Firestore): ExpenseRepository {
  const roomRef = (roomId: string): DocumentReference => db.collection('rooms').doc(roomId);
  const expenseRef = (roomId: string, expenseId: string): DocumentReference =>
    roomRef(roomId).collection('expenses').doc(expenseId);

  return {
    roomRef,
    expenseRef,
    readRoom: (transaction, reference) => transaction.get(reference),
    readExpense: (transaction, reference) => transaction.get(reference),
    create: (transaction, reference, expense) => {
      transaction.create(reference, expense);
    },
    update: (transaction, reference, expense) => {
      transaction.update(reference, expense);
    },
    delete: (transaction, reference) => {
      transaction.delete(reference);
    },
    listExpenses: (roomId) => roomRef(roomId).collection('expenses').get(),
  };
}