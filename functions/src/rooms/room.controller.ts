import { getApp, getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';

import { createRoomService } from './room.service';
import {
  parseCreateRoomInput,
  parseDeleteRoomInput,
  parseRenameRoomInput,
  parseRemoveRoomMemberInput,
  parseGetRoomMembersInput,
  parseCreateRoomInviteInput,
  parseJoinRoomInput,
} from './room.schema';

const app = getApps().length === 0 ? initializeApp() : getApp();
const service = createRoomService(getFirestore(app));

function requireUid(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  if (uid === undefined || uid.length === 0) {
    throw new HttpsError('unauthenticated', 'Sign in to continue.');
  }
  return uid;
}

export async function createRoomHandler(
  request: CallableRequest<unknown>,
): Promise<{ roomId: string; inviteCode: string; expiresAt: string }> {
  const uid = requireUid(request);
  const { name, currency } = parseCreateRoomInput(request.data);
  return service.createRoom(name, currency, uid);
}

export async function createRoomInviteHandler(
  request: CallableRequest<unknown>,
): Promise<{ inviteCode: string; expiresAt: string }> {
  const uid = requireUid(request);
  const { roomId } = parseCreateRoomInviteInput(request.data);
  return service.createRoomInvite(roomId, uid);
}

export async function deleteRoomHandler(
  request: CallableRequest<unknown>,
): Promise<{ roomId: string }> {
  const uid = requireUid(request);
  const { roomId } = parseDeleteRoomInput(request.data);
  return service.deleteRoom(roomId, uid);
}

export async function renameRoomHandler(
  request: CallableRequest<unknown>,
): Promise<{ roomId: string; name: string }> {
  const uid = requireUid(request);
  const { roomId, name } = parseRenameRoomInput(request.data);
  return service.renameRoom(roomId, name, uid);
}

export async function removeRoomMemberHandler(
  request: CallableRequest<unknown>,
): Promise<{ roomId: string; memberId: string }> {
  const uid = requireUid(request);
  const { roomId, memberId, eventId } = parseRemoveRoomMemberInput(request.data);
  return service.removeRoomMember(roomId, memberId, uid, eventId);
}

export async function getRoomMembersHandler(
  request: CallableRequest<unknown>,
): Promise<Array<Record<string, unknown>>> {
  const uid = requireUid(request);
  const { roomId } = parseGetRoomMembersInput(request.data);
  return service.getRoomMembers(roomId, uid);
}

export async function joinRoomHandler(
  request: CallableRequest<unknown>,
): Promise<{ roomId: string; status: 'joined' | 'already-member' }> {
  const uid = requireUid(request);
  const { inviteCode, eventId } = parseJoinRoomInput(request.data);
  return service.joinRoom(inviteCode, uid, eventId);
}
