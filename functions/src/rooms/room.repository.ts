import { Firestore, Query } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

const deleteBatchSize = 400;

export async function deleteQueryInBatches(
  db: Firestore,
  query: Query,
): Promise<void> {
  while (true) {
    const snapshot = await query.limit(deleteBatchSize).get();
    if (snapshot.empty) return;

    const batch = db.batch();
    for (const document of snapshot.docs) batch.delete(document.ref);
    await batch.commit();

    if (snapshot.size < deleteBatchSize) return;
  }
}

export async function validateRoomExists(
  db: Firestore,
  roomId: string,
): Promise<Record<string, unknown>> {
  const roomRef = db.collection('rooms').doc(roomId);
  const roomSnapshot = await roomRef.get();
  if (!roomSnapshot.exists) {
    throw new HttpsError('not-found', 'This room is no longer available.');
  }
  return roomSnapshot.data() ?? {};
}

export async function validateRoomOwnership(
  roomData: Record<string, unknown>,
  uid: string,
): Promise<void> {
  const createdBy = roomData['createdBy'];
  const ownerId = roomData['ownerId'];
  if (createdBy !== uid && ownerId !== uid) {
    throw new HttpsError('permission-denied', 'Only the room owner can perform this action.');
  }
}
