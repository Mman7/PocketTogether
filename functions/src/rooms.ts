import { randomInt } from 'node:crypto';

import { getApp, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import {
  FieldValue,
  Firestore,
  Timestamp,
  getFirestore,
} from 'firebase-admin/firestore';
import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';

const app = getApps().length === 0 ? initializeApp() : getApp();
const firestore = getFirestore(app);
const inviteAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const inviteLength = 8;
const inviteLifetimeMs = 7 * 24 * 60 * 60 * 1000;
const maxInviteAttempts = 8;

interface CreateRoomData {
  name?: unknown;
  currency?: unknown;
}

interface CreateRoomInviteData {
  roomId?: unknown;
}

interface JoinRoomData {
  inviteCode?: unknown;
}

interface Profile {
  displayName: string;
}

interface RoomResult {
  roomId: string;
  inviteCode: string;
  expiresAt: string;
}

class InviteCodeCollision extends Error {}

function requireUid(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  if (uid === undefined || uid.length === 0) {
    throw new HttpsError('unauthenticated', 'Sign in to continue.');
  }
  return uid;
}

function generateInviteCode(): string {
  return Array.from(
    { length: inviteLength },
    () => inviteAlphabet[randomInt(inviteAlphabet.length)],
  ).join('');
}

function asRecord(value: unknown): Record<string, unknown> {
  return typeof value === 'object' && value !== null
    ? (value as Record<string, unknown>)
    : {};
}

async function getProfile(uid: string, db: Firestore): Promise<Profile> {
  const profileSnapshot = await db.collection('users').doc(uid).get();
  const profile = profileSnapshot.data() ?? {};
  let displayName =
    typeof profile['displayName'] === 'string'
      ? profile['displayName'].trim()
      : '';

  if (displayName.length === 0) {
    try {
      const authUser = await getAuth(app).getUser(uid);
      displayName =
        authUser.displayName?.trim() ?? authUser.email?.split('@')[0] ?? '';
    } catch {
      displayName = '';
    }
  }

  return { displayName: displayName || 'Member' };
}

function validateInviteCode(value: unknown): string {
  if (typeof value !== 'string') {
    throw new HttpsError('invalid-argument', 'Enter a valid invite code.');
  }
  const code = value.trim().toUpperCase();
  if (!/^[A-Z0-9]{6,8}$/.test(code)) {
    throw new HttpsError('invalid-argument', 'Enter a valid invite code.');
  }
  return code;
}

function validExpiry(value: unknown): value is Timestamp {
  return value instanceof Timestamp;
}

export async function createRoomHandler(
  request: CallableRequest<CreateRoomData>,
  db: Firestore = firestore,
): Promise<RoomResult> {
  const uid = requireUid(request);
  console.log('createRoomHandler called', { uid });
  const data = asRecord(request.data);
  const name = typeof data['name'] === 'string' ? data['name'].trim() : '';
  if (name.length < 1 || name.length > 80) {
    throw new HttpsError(
      'invalid-argument',
      'Room name must be between 1 and 80 characters.',
    );
  }
  const currency =
    typeof data['currency'] === 'string' && /^[A-Z]{3}$/.test(data['currency'])
      ? data['currency']
      : 'MYR';
  const { displayName } = await getProfile(uid, db);
  const roomRef = db.collection('rooms').doc();

  for (let attempt = 0; attempt < maxInviteAttempts; attempt += 1) {
    const inviteCode = generateInviteCode();
    const inviteRef = db.collection('roomInvites').doc(inviteCode);
    const expiresAt = Timestamp.fromMillis(Date.now() + inviteLifetimeMs);
    try {
      await db.runTransaction(async (transaction) => {
        const existingInvite = await transaction.get(inviteRef);
        if (existingInvite.exists) throw new InviteCodeCollision();

        const now = FieldValue.serverTimestamp();
        transaction.create(roomRef, {
          name,
          createdBy: uid,
          ownerId: uid,
          currency,
          createdAt: now,
          updatedAt: now,
          memberIds: [uid],
        });
        transaction.create(roomRef.collection('members').doc(uid), {
          displayName,
          role: 'owner',
          joinedAt: now,
        });
        transaction.create(inviteRef, {
          roomId: roomRef.id,
          createdBy: uid,
          createdAt: now,
          expiresAt,
          isActive: true,
        });
      });
      return {
        roomId: roomRef.id,
        inviteCode,
        expiresAt: expiresAt.toDate().toISOString(),
      };
    } catch (error) {
      if (error instanceof InviteCodeCollision) continue;
      throw error;
    }
  }

  throw new HttpsError(
    'resource-exhausted',
    'Unable to generate an invite code. Please try again.',
  );
}

export async function createRoomInviteHandler(
  request: CallableRequest<CreateRoomInviteData>,
  db: Firestore = firestore,
): Promise<Pick<RoomResult, 'inviteCode' | 'expiresAt'>> {
  const uid = requireUid(request);
  const data = asRecord(request.data);
  const roomId = typeof data['roomId'] === 'string' ? data['roomId'].trim() : '';
  if (roomId.length === 0) {
    throw new HttpsError('invalid-argument', 'A room is required.');
  }

  const roomRef = db.collection('rooms').doc(roomId);
  for (let attempt = 0; attempt < maxInviteAttempts; attempt += 1) {
    const inviteCode = generateInviteCode();
    const inviteRef = db.collection('roomInvites').doc(inviteCode);
    const expiresAt = Timestamp.fromMillis(Date.now() + inviteLifetimeMs);
    try {
      await db.runTransaction(async (transaction) => {
        const [roomSnapshot, inviteSnapshot] = await Promise.all([
          transaction.get(roomRef),
          transaction.get(inviteRef),
        ]);
        if (!roomSnapshot.exists) {
          throw new HttpsError('not-found', 'This room is no longer available.');
        }
        if (roomSnapshot.get('createdBy') !== uid && roomSnapshot.get('ownerId') !== uid) {
          throw new HttpsError('permission-denied', 'Only the room owner can create invites.');
        }
        if (inviteSnapshot.exists) throw new InviteCodeCollision();

        transaction.create(inviteRef, {
          roomId,
          createdBy: uid,
          createdAt: FieldValue.serverTimestamp(),
          expiresAt,
          isActive: true,
        });
      });
      return { inviteCode, expiresAt: expiresAt.toDate().toISOString() };
    } catch (error) {
      if (error instanceof InviteCodeCollision) continue;
      throw error;
    }
  }

  throw new HttpsError(
    'resource-exhausted',
    'Unable to generate an invite code. Please try again.',
  );
}

export async function joinRoomHandler(
  request: CallableRequest<JoinRoomData>,
  db: Firestore = firestore,
): Promise<{ roomId: string; status: 'joined' | 'already-member' }> {
  const uid = requireUid(request);
  const code = validateInviteCode(asRecord(request.data)['inviteCode']);
  const { displayName } = await getProfile(uid, db);
  const inviteRef = db.collection('roomInvites').doc(code);

  return db.runTransaction(async (transaction) => {
    const inviteSnapshot = await transaction.get(inviteRef);
    if (!inviteSnapshot.exists) {
      throw new HttpsError('not-found', 'That invite code is invalid.');
    }
    const invite = inviteSnapshot.data() ?? {};
    if (invite['isActive'] !== true) {
      throw new HttpsError('failed-precondition', 'This invite has been revoked.');
    }
    if (!validExpiry(invite['expiresAt']) || invite['expiresAt'].toMillis() <= Date.now()) {
      throw new HttpsError('deadline-exceeded', 'This invite has expired.');
    }

    const roomId = invite['roomId'];
    if (typeof roomId !== 'string' || roomId.length === 0) {
      throw new HttpsError('failed-precondition', 'This invite is unavailable.');
    }
    const roomRef = db.collection('rooms').doc(roomId);
    const memberRef = roomRef.collection('members').doc(uid);
    const [roomSnapshot, memberSnapshot] = await Promise.all([
      transaction.get(roomRef),
      transaction.get(memberRef),
    ]);
    if (!roomSnapshot.exists) {
      throw new HttpsError('not-found', 'This room is no longer available.');
    }

    if (memberSnapshot.exists) {
      transaction.update(roomRef, {
        memberIds: FieldValue.arrayUnion(uid),
      });
      return { roomId, status: 'already-member' };
    }

    const now = FieldValue.serverTimestamp();
    transaction.create(memberRef, {
      displayName,
      role: 'member',
      joinedAt: now,
    });
    transaction.update(roomRef, {
      memberIds: FieldValue.arrayUnion(uid),
      updatedAt: now,
    });
    return { roomId, status: 'joined' };
  });
}