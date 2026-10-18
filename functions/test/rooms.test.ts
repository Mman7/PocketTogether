import assert from 'node:assert/strict';
import test from 'node:test';

import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';

import {
  createRoomHandler,
  createRoomInviteHandler,
  joinRoomHandler,
} from '../src/rooms';

type TestRequest = CallableRequest<Record<string, unknown>>;

function request(
  data: Record<string, unknown>,
  uid?: string,
): TestRequest {
  return {
    data,
    auth: uid === undefined ? undefined : { uid, token: {} },
  } as TestRequest;
}

async function expectHttpsError(
  operation: Promise<unknown>,
  code: string,
): Promise<void> {
  await assert.rejects(operation, (error: unknown) => {
    return error instanceof HttpsError && error.code === code;
  });
}

test('room callables reject unauthenticated requests', async () => {
  await expectHttpsError(createRoomHandler(request({ name: 'Trip' })), 'unauthenticated');
  await expectHttpsError(
    createRoomInviteHandler(request({ roomId: 'room-id' })),
    'unauthenticated',
  );
  await expectHttpsError(joinRoomHandler(request({ inviteCode: 'ABCDEFGH' })), 'unauthenticated');
});

test('createRoom validates the room name before accessing Firestore', async () => {
  await expectHttpsError(
    createRoomHandler(request({ name: '' }, 'owner-id')),
    'invalid-argument',
  );
  await expectHttpsError(
    createRoomHandler(request({ name: 'x'.repeat(81) }, 'owner-id')),
    'invalid-argument',
  );
});

test('joinRoom validates invite code shape before accessing Firestore', async () => {
  await expectHttpsError(
    joinRoomHandler(request({ inviteCode: 'too-short' }, 'member-id')),
    'invalid-argument',
  );
});

test('createRoomInvite requires a room id', async () => {
  await expectHttpsError(
    createRoomInviteHandler(request({}, 'owner-id')),
    'invalid-argument',
  );
});
