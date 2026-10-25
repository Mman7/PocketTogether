import {
  DocumentReference,
  DocumentSnapshot,
  Firestore,
  Transaction,
} from 'firebase-admin/firestore';

export class ExpenseRepository {
  constructor(private readonly db: Firestore) {}

  roomRef(roomId: string): DocumentReference {
    return this.db.collection('rooms').doc(roomId);
  }

  expenseRef(roomId: string, expenseId: string): DocumentReference {
    return this.roomRef(roomId).collection('expenses').doc(expenseId);
  }

  readRoom(transaction: Transaction, roomRef: DocumentReference): Promise<DocumentSnapshot> {
    return transaction.get(roomRef);
  }

  readExpense(
    transaction: Transaction,
    expenseRef: DocumentReference,
  ): Promise<DocumentSnapshot> {
    return transaction.get(expenseRef);
  }

  create(
    transaction: Transaction,
    reference: DocumentReference,
    expense: Record<string, unknown>,
  ): void {
    transaction.create(reference, expense);
  }

  update(
    transaction: Transaction,
    reference: DocumentReference,
    expense: Record<string, unknown>,
  ): void {
    transaction.update(reference, expense);
  }

  delete(transaction: Transaction, reference: DocumentReference): void {
    transaction.delete(reference);
  }

  listExpenses(roomId: string): Promise<FirebaseFirestore.QuerySnapshot> {
    return this.roomRef(roomId).collection('expenses').get();
  }
}