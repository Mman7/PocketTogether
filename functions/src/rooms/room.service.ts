import { randomInt } from 'node:crypto';

import { getApp, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import {
  FieldValue,
  Firestore,
  Timestamp,
  getFirestore,
} from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { notifyRoomMembers } from '../notifications/notification.service';
import {
  InviteCodeCollision,
  Profile,
  RoomResult,
} from './room.types';
import {
  deleteQueryInBatches,
  validateRoomExists,
  validateRoomOwnership,
} from './room.repository';

const app = getApps().length === 0 ? initializeApp() : getApp();
const firestore = getFirestore(app);

const inviteAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const inviteLength = 8;
const inviteLifetimeMs = 1 * 24 * 60 * 60 * 1000;
const maxInviteAttempts = 8;

export interface RoomService {
  getProfile(uid: string): Promise<Profile>;
  createRoom(name: string, currency: string, uid: string): Promise<RoomResult>;
  createRoomInvite(roomId: string, uid: string): Promise<Pick<RoomResult, 'inviteCode' | 'expiresAt'>>;
  deleteRoom(roomId: string, uid: string): Promise<{ roomId: string }>;
  renameRoom(roomId: string, name: string, uid: string): Promise<{ roomId: string; name: string }>;
  removeRoomMember(
    roomId: string,
    memberId: string,
    uid: string,
    eventId: string,
  ): Promise<{ roomId: string; memberId: string }>;
  getRoomMembers(roomId: string, uid: string): Promise<Array<Record<string, unknown>>>;
  joinRoom(
    inviteCode: string,
    uid: string,
    eventId: string,
  ): Promise<{ roomId: string; status: 'joined' | 'already-member' }>;
}

function generateInviteCode(): string {
  return Array.from(
    { length: inviteLength },
    () => inviteAlphabet[randomInt(inviteAlphabet.length)],
  ).join('');
}

export function createRoomService(db: Firestore = firestore): RoomService {
  const getProfile = async (uid: string): Promise<Profile> => {
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
  };

  const service: RoomService = {
    getProfile,

  async createRoom(
    name: string,
    currency: string,
    uid: string,
  ): Promise<RoomResult> {
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
            userId: uid,
            role: 'owner',
            joinedAt: now,
          });
          transaction.create(
            roomRef.collection('activityLogs').doc(`room_created_${roomRef.id}`),
            {
              type: 'room_created',
              actorUserId: uid,
              targetType: 'room',
              targetId: roomRef.id,
              createdAt: now,
              metadata: { roomName: name },
            },
          );
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
  },

  async createRoomInvite(
    roomId: string,
    uid: string,
  ): Promise<Pick<RoomResult, 'inviteCode' | 'expiresAt'>> {
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
          const roomData = roomSnapshot.data() ?? {};
          await validateRoomOwnership(roomData, uid);
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
  },

  async deleteRoom(roomId: string, uid: string): Promise<{ roomId: string }> {
    const roomRef = db.collection('rooms').doc(roomId);
    const roomData = await validateRoomExists(db, roomId);
    await validateRoomOwnership(roomData, uid);

    await Promise.all([
      deleteQueryInBatches(db, roomRef.collection('members')),
      deleteQueryInBatches(db, roomRef.collection('expenses')),
      deleteQueryInBatches(db, roomRef.collection('activityLogs')),
      deleteQueryInBatches(
        db,
        db.collection('roomInvites').where('roomId', '==', roomId),
      ),
    ]);
    await db.batch().delete(roomRef).commit();

    return { roomId };
  },

  async renameRoom(
    roomId: string,
    name: string,
    uid: string,
  ): Promise<{ roomId: string; name: string }> {
    const roomRef = db.collection('rooms').doc(roomId);
    await db.runTransaction(async (transaction) => {
      const roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) {
        throw new HttpsError('not-found', 'This room is no longer available.');
      }
      const roomData = roomSnapshot.data() ?? {};
      await validateRoomOwnership(roomData, uid);

      const previousName = roomSnapshot.get('name');
      transaction.update(roomRef, {
        name,
        updatedAt: FieldValue.serverTimestamp(),
      });
      transaction.create(
        roomRef.collection('activityLogs').doc(`room_renamed_${Date.now()}_${uid}`),
        {
          type: 'room_renamed',
          actorUserId: uid,
          targetType: 'room',
          targetId: roomId,
          createdAt: FieldValue.serverTimestamp(),
          metadata: {
            previousName: typeof previousName === 'string' ? previousName : '',
            roomName: name,
          },
        },
      );
    });

    return { roomId, name };
  },

  async removeRoomMember(
    roomId: string,
    memberId: string,
    uid: string,
    eventId: string,
  ): Promise<{ roomId: string; memberId: string }> {
    if (memberId === uid) {
      throw new HttpsError(
        'failed-precondition',
        'The room owner cannot be removed.',
      );
    }

    const roomRef = db.collection('rooms').doc(roomId);
    await db.runTransaction(async (transaction) => {
      const roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) {
        throw new HttpsError('not-found', 'This room is no longer available.');
      }
      const roomData = roomSnapshot.data() ?? {};
      await validateRoomOwnership(roomData, uid);

      const memberRef = roomRef.collection('members').doc(memberId);
      const memberSnapshot = await transaction.get(memberRef);
      if (!memberSnapshot.exists) {
        throw new HttpsError('not-found', 'That member is no longer in the room.');
      }
      transaction.delete(memberRef);
      transaction.update(roomRef, {
        memberIds: FieldValue.arrayRemove(memberId),
        updatedAt: FieldValue.serverTimestamp(),
      });
      transaction.create(
        roomRef.collection('activityLogs').doc(`member_removed_${eventId || memberId}`),
        {
          type: 'member_removed',
          actorUserId: uid,
          targetType: 'member',
          targetId: memberId,
          memberUserId: memberId,
          createdAt: FieldValue.serverTimestamp(),
          metadata: {
            memberUserId: memberId,
            memberDisplayName:
              typeof memberSnapshot.get('displayName') === 'string'
                ? memberSnapshot.get('displayName')
                : memberId,
          },
        },
      );
    });

    return { roomId, memberId };
  },

  async getRoomMembers(
    roomId: string,
    uid: string,
  ): Promise<Array<Record<string, unknown>>> {
    const roomRef = db.collection('rooms').doc(roomId);
    const roomSnapshot = await roomRef.get();
    if (!roomSnapshot.exists) {
      throw new HttpsError('not-found', 'This room is no longer available.');
    }
    const memberIds = roomSnapshot.get('memberIds');
    if (!Array.isArray(memberIds) || !memberIds.includes(uid)) {
      throw new HttpsError('permission-denied', 'You are not a member of this room.');
    }

    const memberSnapshot = await roomRef.collection('members').get();
    const profileSnapshots = await db.getAll(
      ...memberSnapshot.docs.map((member) =>
        db.collection('users').doc(member.id),
      ),
    );
    const profilesById = new Map(
      profileSnapshots.map((profile) => [profile.id, profile.data() ?? {}]),
    );

    return Promise.all(
      memberSnapshot.docs.map(async (member) => {
        const profile = profilesById.get(member.id) ?? {};
        const profileName =
          typeof profile['displayName'] === 'string'
            ? profile['displayName'].trim()
            : '';
        const displayName =
          profileName || (await getProfile(member.id)).displayName;
        const memberData = member.data();
        return {
          userId: member.id,
          displayName,
          role: memberData['role'] ?? 'member',
          joinedAt:
            memberData['joinedAt'] instanceof Timestamp
              ? memberData['joinedAt'].toDate().toISOString()
              : null,
        };
      }),
    );
  },

  async joinRoom(
    inviteCode: string,
    uid: string,
    eventId: string,
  ): Promise<{ roomId: string; status: 'joined' | 'already-member' }> {
    const inviteRef = db.collection('roomInvites').doc(inviteCode);

    const result: { roomId: string; status: 'joined' | 'already-member' } =
      await db.runTransaction(async (transaction) => {
        const inviteSnapshot = await transaction.get(inviteRef);
        if (!inviteSnapshot.exists) {
          throw new HttpsError('not-found', 'That invite code is invalid.');
        }
        const invite = inviteSnapshot.data() ?? {};
        if (invite['isActive'] !== true) {
          throw new HttpsError('failed-precondition', 'This invite has been revoked.');
        }
        if (
          !(invite['expiresAt'] instanceof Timestamp) ||
          invite['expiresAt'].toMillis() <= Date.now()
        ) {
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
          userId: uid,
          role: 'member',
          joinedAt: now,
        });
        transaction.update(roomRef, {
          memberIds: FieldValue.arrayUnion(uid),
          updatedAt: now,
        });
        transaction.create(
          roomRef.collection('activityLogs').doc(`member_joined_${eventId || uid}`),
          {
            type: 'member_joined',
            actorUserId: uid,
            targetType: 'member',
            targetId: uid,
            memberUserId: uid,
            createdAt: now,
            metadata: { memberUserId: uid },
          },
        );
        return { roomId, status: 'joined' };
      });

    if (result.status === 'joined') {
      try {
        const room = await db
          .collection('rooms')
          .doc(result.roomId)
          .get();
        const roomName = typeof room.get('name') === 'string' ? room.get('name') : 'your room';
        await notifyRoomMembers(
          db,
          result.roomId,
          uid,
          `member_joined_${uid}`,
          {
            title: `New member in ${roomName}`,
            body: 'A new member joined the room.',
            data: { type: 'member_joined', roomId: result.roomId },
          },
        );
      } catch (error) {
        console.error('Unable to deliver member notification', {
          roomId: result.roomId,
          error,
        });
      }
    }
    return result;
  },
  };

  return service;
}
