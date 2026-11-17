import { setGlobalOptions } from 'firebase-functions/v2';

import {
  createRoom,
  createRoomInvite,
  deleteRoom,
  getRoomMembers,
  joinRoom,
  renameRoom,
  removeRoomMember,
} from './rooms/room.functions';
import {
  createExpense,
  deleteExpense,
  rebuildExpenseSummaries,
  updateExpense,
} from './expenses/expense.functions';

setGlobalOptions({ maxInstances: 10, region: 'us-central1' });

// room functions
export {
  createRoom,
  createRoomInvite,
  deleteRoom,
  renameRoom,
  removeRoomMember,
  getRoomMembers,
  joinRoom,
};

// expense functions
export {
  createExpense,
  deleteExpense,
  rebuildExpenseSummaries,
  updateExpense,
};