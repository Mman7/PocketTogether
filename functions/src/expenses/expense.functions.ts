import { onCall } from 'firebase-functions/v2/https';

import {
  createExpenseHandler,
  deleteExpenseHandler,
  rebuildExpenseSummariesHandler,
  updateExpenseHandler,
} from './expense.controller';

export const createExpense = onCall((request) => createExpenseHandler(request));
export const updateExpense = onCall((request) => updateExpenseHandler(request));
export const deleteExpense = onCall((request) => deleteExpenseHandler(request));
export const rebuildExpenseSummaries = onCall((request) =>
  rebuildExpenseSummariesHandler(request),
);