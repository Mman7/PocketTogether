import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../models/room_member.dart';

class RoomMembersPage extends StatelessWidget {
  const RoomMembersPage({
    required this.roomName,
    required this.members,
    super.key,
  });

  final String roomName;
  final List<RoomMember> members;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$roomName members')),
      body: members.isEmpty
          ? const Center(child: Text('No members found in this room.'))
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                for (final member in members) ...[
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        MemberAvatar(
                          name: member.displayName,
                          size: 42,
                          color: member.isOwner
                              ? AppColors.paleBlue
                              : AppColors.paleCyan,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (member.email != null)
                                Text(
                                  member.email!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        StatusPill(label: member.isOwner ? 'Owner' : 'Member'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                ],
              ],
            ),
    );
  }
}
