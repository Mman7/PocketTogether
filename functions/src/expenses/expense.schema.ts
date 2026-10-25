import { Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';

import { ExpenseInput, PersistedExpense } from './expense.types';

const expenseDataSchema = z.object({
  roomId: z.string().trim().min(1),
  expenseId: z.string().trim().min(1),
  amountInCents: z.number().int().safe().positive(),
  category: z.string().trim().min(1).max(60),
  note: z.string().trim().max(500).optional().nullable(),
  paidByUserId: z.string().trim().min(1),
  createdByUserId: z.string().trim().min(1),
  transferMethod: z.string().trim().max(60).optional().nullable(),
  transferToUserId: z.string().trim().min(1).optional().nullable(),
  splitAmountsInCents: z.record(z.string().min(1), z.number().int().safe().positive()),
  expenseDate: z.unknown(),
});

function parseTimestamp(value: unknown): Timestamp {
  if (value instanceof Timestamp) return value;
  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    return Timestamp.fromDate(value);
  }
  if (typeof value === 'string') {
    const date = new Date(value);
    if (!Number.isNaN(date.getTime())) return Timestamp.fromDate(date);
  }
  throw new HttpsError('invalid-argument', 'A valid expense date is required.');
}

function invalidInput(error: z.ZodError): never {
  const message = error.issues[0]?.message ?? 'Expense input is invalid.';
  throw new HttpsError('invalid-argument', message);
}

export function parseExpenseInput(
  value: unknown,
  uid: string,
  requireCreator: boolean,
): ExpenseInput {
  const parsed = expenseDataSchema.safeParse(value);
  if (!parsed.success) invalidInput(parsed.error);
  const data = parsed.data;
  const expenseDate = parseTimestamp(data.expenseDate);
  const splitTotal = Object.values(data.splitAmountsInCents).reduce(
    (total, amount) => {
      if (!Number.isSafeInteger(total + amount)) {
        throw new HttpsError('invalid-argument', 'Split amounts exceed the safe integer limit.');
      }
      return total + amount;
    },
    0,
  );
  if (Object.keys(data.splitAmountsInCents).length === 0 || splitTotal !== data.amountInCents) {
    throw new HttpsError('invalid-argument', 'Split amounts must equal the expense amount.');
  }
  if (requireCreator && data.createdByUserId !== uid) {
    throw new HttpsError('permission-denied', 'You can only create your own expenses.');
  }
  const input: ExpenseInput = {
    roomId: data.roomId,
    expenseId: data.expenseId,
    amountInCents: data.amountInCents,
    category: data.category,
    paidByUserId: data.paidByUserId,
    createdByUserId: data.createdByUserId,
    splitAmountsInCents: data.splitAmountsInCents,
    expenseDate,
  };
  if (data.note != null) input.note = data.note;
  if (data.transferMethod != null) input.transferMethod = data.transferMethod;
  if (data.transferToUserId != null) input.transferToUserId = data.transferToUserId;
  return input;
}

export function parsePersistedExpense(value: Record<string, unknown>): PersistedExpense {
  const parsed = expenseDataSchema.omit({ roomId: true, expenseId: true }).safeParse(value);
  if (!parsed.success) invalidInput(parsed.error);
  const input = parseExpenseInput(
    { ...parsed.data, roomId: 'stored', expenseId: 'stored' },
    parsed.data.createdByUserId,
    false,
  );
  return {
    ...input,
    createdAt: value.createdAt instanceof Timestamp ? value.createdAt : undefined,
    updatedAt: value.updatedAt instanceof Timestamp ? value.updatedAt : undefined,
  };
}

export function parseRebuildRoomId(value: unknown): string {
  const parsed = z.object({ roomId: z.string().trim().min(1) }).safeParse(value);
  if (!parsed.success) invalidInput(parsed.error);
  return parsed.data.roomId;
}

export function parseExpenseIds(value: unknown): { roomId: string; expenseId: string } {
  const parsed = z.object({
    roomId: z.string().trim().min(1),
    expenseId: z.string().trim().min(1),
  }).safeParse(value);
  if (!parsed.success) invalidInput(parsed.error);
  return parsed.data;
}