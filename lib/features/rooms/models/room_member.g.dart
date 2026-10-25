// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomMember _$RoomMemberFromJson(Map<String, dynamic> json) => RoomMember(
  userId: json['userId'] as String,
  displayName: json['displayName'] as String,
  email: json['email'] as String?,
  role: $enumDecode(_$RoomRoleEnumMap, json['role']),
  joinedAt: json['joinedAt'] == null
      ? null
      : DateTime.parse(json['joinedAt'] as String),
);

Map<String, dynamic> _$RoomMemberToJson(RoomMember instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'email': instance.email,
      'role': _$RoomRoleEnumMap[instance.role]!,
      'joinedAt': instance.joinedAt?.toIso8601String(),
    };

const _$RoomRoleEnumMap = {RoomRole.owner: 'owner', RoomRole.member: 'member'};
