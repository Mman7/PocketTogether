import { getApp, getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';

import { ExpenseService } from './expense.service';
import {
  parseExpenseIds,
  parseExpenseInput,
  parseRebuildRoomId,
} from './expense.schema';

const app = getApps().length === 0 ? initializeApp() : getApp();
const service = new ExpenseService(getFirestore(app));

function requireUid(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in to continue.');
  return uid;
}

export async function createExpenseHandler(
  request: CallableRequest<unknown>,
): Promise<{ expenseId: string }> {
  const uid = requireUid(request);
  return service.create(parseExpenseInput(request.data, uid, true), uid);
}

export async function updateExpenseHandler(
  request: CallableRequest<unknown>,
): Promise<{ expenseId: string }> {
  const uid = requireUid(request);
  return service.update(parseExpenseInput(request.data, uid, false), uid);
}

export async function deleteExpenseHandler(
  request: CallableRequest<unknown>,
): Promise<{ expenseId: string }> {
  const uid = requireUid(request);
  const { roomId, expenseId } = parseExpenseIds(request.data);
  return service.delete(roomId, expenseId, uid);
}

export async function rebuildExpenseSummariesHandler(
  request: CallableRequest<unknown>,
): Promise<{ roomId: string; expenseCount: number }> {
  requireAdmin(request);
  return service.rebuild(parseRebuildRoomId(request.data));
}

function requireAdmin(request: CallableRequest<unknown>): void {
  requireUid(request);
  if (request.auth?.token['admin'] !== true) {
    throw new HttpsError('permission-denied', 'Administrator access is required.');
  }
}