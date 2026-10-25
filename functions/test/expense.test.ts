import assert from 'node:assert/strict';
import test from 'node:test';

import { Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { parseExpenseInput } from '../src/expenses/expense.schema';
import { ExpenseSummary } from '../src/expenses/expense-summary';

const baseInput = {
  roomId: 'room-1',
  expenseId: 'expense-1',
  amountInCents: 5000,
  category: 'Food',
  paidByUserId: 'user-1',
  createdByUserId: 'user-1',
  splitAmountsInCents: { 'user-1': 3000, 'user-2': 2000 },
  expenseDate: Timestamp.fromDate(new Date('2026-10-31T23:30:00.000Z')),
};

test('schema validates cents and rejects unsafe or mismatched splits', () => {
  const parsed = parseExpenseInput(baseInput, 'user-1', true);
  assert.equal(parsed.amountInCents, 5000);

  assert.throws(
    () => parseExpenseInput({ ...baseInput, amountInCents: Number.MAX_SAFE_INTEGER + 1 }, 'user-1', true),
    (error: unknown) => error instanceof HttpsError && error.code === 'invalid-argument',
  );
  assert.throws(
    () => parseExpenseInput({ ...baseInput, splitAmountsInCents: { 'user-1': 1 } }, 'user-1', true),
    (error: unknown) => error instanceof HttpsError && error.code === 'invalid-argument',
  );
});

test('summary contributions use UTC month IDs and all four destinations', () => {
  const expense = parseExpenseInput(baseInput, 'user-1', true);
  const targets = new ExpenseSummary().contribution(expense, 1);

  assert.deepEqual(targets, [
    { path: ['stats', 'summary'], field: 'totalExpenseInCents', delta: 5000 },
    { path: ['monthlyStats', '2026-10'], field: 'totalExpenseInCents', delta: 5000 },
    {
      path: ['members', 'user-1', 'stats', 'summary'],
      field: 'totalPaidInCents',
      delta: 5000,
    },
    {
      path: ['members', 'user-1', 'monthlyStats', '2026-10'],
      field: 'totalPaidInCents',
      delta: 5000,
    },
  ]);
  assert.equal(
    new ExpenseSummary().contribution(expense, -1)[0].delta,
    -5000,
  );
});
