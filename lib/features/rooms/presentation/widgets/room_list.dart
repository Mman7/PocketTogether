import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../models/room.dart';

class RoomList extends StatelessWidget {
  const RoomList({
    required this.rooms,
    required this.isLoading,
    required this.errorMessage,
    required this.lastVisitedRoomId,
    required this.onRetry,
    required this.onRoomTap,
    super.key,
  });

  final List<Room> rooms;
  final bool isLoading;
  final String? errorMessage;
  final String? lastVisitedRoomId;
  final VoidCallback onRetry;
  final ValueChanged<Room> onRoomTap;

  @override
  Widget build(BuildContext context) {
    Room? lastVisitedRoom;
    for (final room in rooms) {
      if (room.id == lastVisitedRoomId) {
        lastVisitedRoom = room;
        break;
      }
    }
    final otherRooms = rooms
        .where((room) => room.id != lastVisitedRoom?.id)
        .toList();

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (errorMessage != null) {
      return _RoomListError(message: errorMessage!, onRetry: onRetry);
    }
    if (rooms.isEmpty) return const _RoomsEmptyState();

    return Column(
      children: [
        if (lastVisitedRoom != null) ...[
          RoomCard(
            room: lastVisitedRoom,
            isLastVisited: true,
            onTap: () => onRoomTap(lastVisitedRoom!),
          ),
          const SizedBox(height: 12),
        ],
        for (final room in otherRooms) ...[
          RoomCard(
            room: room,
            isLastVisited: false,
            onTap: () => onRoomTap(room),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class RoomCard extends StatelessWidget {
  const RoomCard({
    required this.room,
    required this.isLastVisited,
    required this.onTap,
    super.key,
  });

  final Room room;
  final bool isLastVisited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final description = room.description?.trim();
    return SurfaceCard(
      onTap: onTap,
      color: isLastVisited ? const Color(0xFFF0F8FF) : AppColors.white,
      borderColor: isLastVisited ? AppColors.primary : AppColors.border,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.paleBlue,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.groups_rounded,
                  size: 25,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description == null || description.isEmpty
                          ? 'Shared room'
                          : description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(label: room.currency ?? 'Room'),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: AppColors.paleBlue),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.tag_rounded, size: 15, color: AppColors.primary),
              const SizedBox(width: 7),
              const Text(
                'Room ID',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  room.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomsEmptyState extends StatelessWidget {
  const _RoomsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const SurfaceCard(
      child: Column(
        children: [
          Icon(Icons.groups_outlined, color: AppColors.primary, size: 30),
          SizedBox(height: 8),
          Text('No rooms yet', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 3),
          Text(
            'Create a room to start sharing expenses.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _RoomListError extends StatelessWidget {
  const _RoomListError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
