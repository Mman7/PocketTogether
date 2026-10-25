import { setGlobalOptions } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import {
  createRoomHandler,
  createRoomInviteHandler,
  deleteRoomHandler,
  getRoomMembersHandler,
  joinRoomHandler,
  removeRoomMemberHandler,
} from './rooms';
import {
  createExpense,
  deleteExpense,
  rebuildExpenseSummaries,
  updateExpense,
} from './expenses/expense.functions';


setGlobalOptions({ maxInstances: 10, region: 'us-central1' });

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

export { createExpense, deleteExpense, rebuildExpenseSummaries, updateExpense };