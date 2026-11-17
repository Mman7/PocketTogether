import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';

const roomIdSchema = z.string().trim().min(1, 'A room is required.');
const roomNameSchema = z
  .string()
  .trim()
  .min(1, 'Room name must be between 1 and 20 characters.')
  .max(20, 'Room name must be between 1 and 20 characters.');
const currencySchema = z.string().regex(/^[A-Z]{3}$/, 'Currency must be a 3-letter code.').default('MYR');
const inviteCodeSchema = z
  .string()
  .trim()
  .toUpperCase()
  .regex(/^[A-Z0-9]{6,8}$/, 'Enter a valid invite code.');
const memberIdSchema = z.string().trim().min(1, 'A member is required.');

const createRoomSchema = z.object({ name: roomNameSchema, currency: currencySchema });
const deleteRoomSchema = z.object({ roomId: roomIdSchema });
const renameRoomSchema = z.object({ roomId: roomIdSchema, name: roomNameSchema });
const removeRoomMemberSchema = z.object({
  roomId: roomIdSchema,
  memberId: memberIdSchema,
  eventId: z.string().trim().default(''),
});
const getRoomMembersSchema = z.object({ roomId: roomIdSchema });
const createRoomInviteSchema = z.object({ roomId: roomIdSchema });
const joinRoomSchema = z.object({
  inviteCode: inviteCodeSchema,
  eventId: z.string().trim().default(''),
});

// Convert Zod's client-facing validation failures into callable errors.
function invalidInput(error: z.ZodError): never {
  const message = error.issues[0]?.message ?? 'Room input is invalid.';
  throw new HttpsError('invalid-argument', message);
}

function parse<T>(schema: z.ZodType<T>, value: unknown): T {
  const parsed = schema.safeParse(value);
  if (!parsed.success) invalidInput(parsed.error);
  return parsed.data;
}

export function validateRoomId(value: unknown): string {
  return parse(roomIdSchema, value);
}

export function validateRoomName(value: unknown): string {
  return parse(roomNameSchema, value);
}

export function validateCurrency(value: unknown): string {
  return parse(currencySchema, value);
}

export function validateInviteCode(value: unknown): string {
  return parse(inviteCodeSchema, value);
}

export function validateMemberId(value: unknown): string {
  return parse(memberIdSchema, value);
}

export function parseCreateRoomInput(data: unknown): { name: string; currency: string } {
  return parse(createRoomSchema, data);
}

export function parseDeleteRoomInput(data: unknown): { roomId: string } {
  return parse(deleteRoomSchema, data);
}

export function parseRenameRoomInput(data: unknown): { roomId: string; name: string } {
  return parse(renameRoomSchema, data);
}

export function parseRemoveRoomMemberInput(
  data: unknown,
): { roomId: string; memberId: string; eventId: string } {
  return parse(removeRoomMemberSchema, data);
}

export function parseGetRoomMembersInput(data: unknown): { roomId: string } {
  return parse(getRoomMembersSchema, data);
}

export function parseCreateRoomInviteInput(data: unknown): { roomId: string } {
  return parse(createRoomInviteSchema, data);
}

export function parseJoinRoomInput(data: unknown): { inviteCode: string; eventId: string } {
  return parse(joinRoomSchema, data);
}
