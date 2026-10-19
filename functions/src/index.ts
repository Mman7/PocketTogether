import { setGlobalOptions } from 'firebase-functions/v2';
import { onCall, HttpsError } from 'firebase-functions/v2/https';

import {
  createRoomHandler,
  createRoomInviteHandler,
  deleteRoomHandler,
  getRoomMembersHandler,
  joinRoomHandler,
  removeRoomMemberHandler,
} from './rooms';


setGlobalOptions({ maxInstances: 10, region: 'us-central1' });

export const helloFromLocal = onCall((request) => {
  const name = request.data?.name;

  if (typeof name !== "string" || !name.trim()) {
    throw new HttpsError(
      "invalid-argument",
      "Please provide a name"
    );
  }

  console.log("helloFromLocal called with:", name);

  return {
    message: `Hello, ${name}!`,
    source: "Firebase Functions Emulator",
  };
});

export const createRoom = onCall((request) => createRoomHandler(request));

export const createRoomInvite = onCall((request) =>
  createRoomInviteHandler(request),
);

export const deleteRoom = onCall((request) => deleteRoomHandler(request));

export const removeRoomMember = onCall((request) =>
  removeRoomMemberHandler(request),
);

export const getRoomMembers = onCall((request) =>
  getRoomMembersHandler(request),
);

export const joinRoom = onCall((request) => joinRoomHandler(request));