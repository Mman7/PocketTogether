import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class RoomActionsDrawer extends StatelessWidget {
  const RoomActionsDrawer({
    required this.roomName,
    required this.creatingInvite,
    required this.removingMember,
    required this.deletingRoom,
    required this.renamingRoom,
    required this.onGenerateInvite,
    required this.onRemoveMember,
    required this.onDeleteRoom,
    required this.onRenameRoom,
    super.key,
  });

  final String roomName;
  final bool creatingInvite;
  final bool removingMember;
  final bool deletingRoom;
  final bool renamingRoom;
  final Future<void> Function() onGenerateInvite;
  final Future<void> Function() onRemoveMember;
  final Future<void> Function() onDeleteRoom;
  final Future<void> Function() onRenameRoom;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.canvas,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
              child: Text(
                'PEOPLE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            _roomActionTile(
              icon: Icons.mail_outline_rounded,
              title: 'Generate invite',
              subtitle: 'Invite someone to this room',
              iconColor: AppColors.primary,
              enabled: !creatingInvite,
              loading: creatingInvite,
              onTap: () => _runAction(context, onGenerateInvite),
            ),
            _roomActionTile(
              icon: Icons.person_remove_outlined,
              title: 'Remove member',
              subtitle: 'Remove a member from this room',
              iconColor: AppColors.secondary,
              enabled: !removingMember,
              loading: removingMember,
              onTap: () => _runAction(context, onRemoveMember),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
              child: Text(
                'ROOM',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            _roomActionTile(
              icon: Icons.edit_outlined,
              title: 'Change room name',
              subtitle: 'Update the name shown to members',
              iconColor: AppColors.primary,
              enabled: !renamingRoom,
              loading: renamingRoom,
              onTap: () => _runAction(context, onRenameRoom),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
              child: Text(
                'DANGER ZONE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            _roomActionTile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete room',
              subtitle: 'Permanently delete this room',
              iconColor: AppColors.danger,
              titleColor: AppColors.danger,
              enabled: !deletingRoom,
              loading: deletingRoom,
              onTap: () => _runAction(context, onDeleteRoom),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 20),
      decoration: const BoxDecoration(
        color: AppColors.paleBlue,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.card),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Room actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.home_work_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  roomName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Owner controls',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    Navigator.of(context).pop();
    await action();
  }

  Widget _roomActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    required bool enabled,
    bool loading = false,
    Color? titleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadii.control),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor ?? AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
