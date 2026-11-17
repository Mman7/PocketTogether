export interface CreateRoomData {
  name?: unknown;
  currency?: unknown;
}

export interface DeleteRoomData {
  roomId?: unknown;
}

export interface RenameRoomData {
  roomId?: unknown;
  name?: unknown;
}

export interface RemoveRoomMemberData {
  roomId?: unknown;
  memberId?: unknown;
  eventId?: unknown;
}

export interface GetRoomMembersData {
  roomId?: unknown;
}

export interface CreateRoomInviteData {
  roomId?: unknown;
}

export interface JoinRoomData {
  inviteCode?: unknown;
  eventId?: unknown;
}

export interface Profile {
  displayName: string;
}

export interface RoomResult {
  roomId: string;
  inviteCode: string;
  expiresAt: string;
}

export class InviteCodeCollision extends Error {}
