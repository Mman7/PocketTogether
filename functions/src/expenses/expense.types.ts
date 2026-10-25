import { Timestamp } from 'firebase-admin/firestore';

export interface ExpenseInput {
  roomId: string;
  expenseId: string;
  amountInCents: number;
  category: string;
  note?: string;
  paidByUserId: string;
  createdByUserId: string;
  transferMethod?: string;
  transferToUserId?: string;
  splitAmountsInCents: Record<string, number>;
  expenseDate: Timestamp;
}

export interface PersistedExpense {
  amountInCents: number;
  category: string;
  paidByUserId: string;
  createdByUserId: string;
  expenseDate: Timestamp;
  splitAmountsInCents: Record<string, number>;
  note?: string;
  transferMethod?: string;
  transferToUserId?: string;
  createdAt?: Timestamp;
  updatedAt?: Timestamp;
}

export interface SummaryTarget {
  path: string[];
  field: 'totalExpenseInCents' | 'totalPaidInCents';
  delta: number;
}

export interface RebuildResult {
  roomId: string;
  expenseCount: number;
}