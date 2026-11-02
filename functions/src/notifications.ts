import { getApps, getApp, initializeApp } from 'firebase-admin/app';
import { FieldValue, Firestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

const app = getApps().length === 0 ? initializeApp() : getApp();
const messaging = getMessaging(app);
// TODO: Add emulator/integration coverage for token selection and send retries.

/** Payload sent to room members after a successful room mutation. */
export interface RoomNotification {
  title: string;
  body: string;
  data: Record<string, string>;
}

export async function notifyRoomMembers(
  db: Firestore,
  roomId: string,
  actorUserId: string,
  eventId: string,
  notification: RoomNotification,
): Promise<void> {
  // The event document makes repeated callable retries idempotent: only the
  // first transaction that claims an event is allowed to send notifications.
  const eventRef = db
    .collection('rooms')
    .doc(roomId)
    .collection('notificationEvents')
    .doc(eventId);
  const shouldSend = await db.runTransaction(async (transaction) => {
    const event = await transaction.get(eventRef);
    if (event.exists && event.get('status') === 'sent') return false;
    if (event.exists) {
      transaction.update(eventRef, { updatedAt: FieldValue.serverTimestamp() });
    } else {
      transaction.create(eventRef, {
        status: 'pending',
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    return true;
  });
  if (!shouldSend) return;

  const room = await db.collection('rooms').doc(roomId).get();
  const memberIds = room.get('memberIds');
  if (!Array.isArray(memberIds)) return;

  const tokenDocuments = (
    await Promise.all(
      memberIds
        .filter((memberId): memberId is string =>
          typeof memberId === 'string' && memberId !== actorUserId,
        )
        .map(async (memberId) =>
          db.collection('users').doc(memberId).collection('fcmTokens').get(),
        ),
    )
  ).flatMap((snapshot) => snapshot.docs);

  // FCM multicast accepts at most 500 registration tokens per request.
  for (let offset = 0; offset < tokenDocuments.length; offset += 500) {
    const batch = tokenDocuments.slice(offset, offset + 500);
    const tokens = batch
      .map((document) => document.get('token'))
      .filter((token): token is string => typeof token === 'string' && token.length > 0);
    if (tokens.length === 0) continue;

    const result = await messaging.sendEachForMulticast({
      tokens,
      notification: { title: notification.title, body: notification.body },
      data: notification.data,
    });
    await Promise.all(
      result.responses.map((response, index) => {
        if (response.success) return Promise.resolve();
        const code = response.error?.code;
        if (
          code !== 'messaging/registration-token-not-registered' &&
          code !== 'messaging/invalid-registration-token'
        ) {
          console.error('FCM delivery failed', { code });
          return Promise.resolve();
        }
        return batch[index].ref.delete();
      }),
    );
  }

  await eventRef.update({ status: 'sent', updatedAt: FieldValue.serverTimestamp() });
}
