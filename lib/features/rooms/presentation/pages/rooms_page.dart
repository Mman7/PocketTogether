import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocket_together/features/profile/presentation/cubit/profile_state.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/mock_data.dart';
import '../../../auth/models/auth_user.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../../expenses/presentation/pages/history_page.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../data/room_repository.dart';
import '../cubit/room_cubit.dart';
import '../cubit/room_state.dart';
import '../../models/room.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import 'room_dashboard_page.dart';
import 'room_entry_pages.dart';

class RoomsPage extends StatefulWidget {
  const RoomsPage({
    required this.onSignOut,
    required this.profileRepository,
    required this.roomRepository,
    this.currentUser,
    super.key,
  });

  final Future<void> Function() onSignOut;
  final ProfileRepository profileRepository;
  final RoomRepository roomRepository;
  final AuthUser? currentUser;

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  int _selectedTab = 0;
  late final RoomCubit _roomCubit;

  @override
  void initState() {
    super.initState();
    _roomCubit = RoomCubit(widget.roomRepository)
      ..loadRooms(widget.currentUser?.uid);
  }

  @override
  void dispose() {
    _roomCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              ProfileCubit(widget.profileRepository)
                ..load(widget.currentUser?.uid),
        ),
        BlocProvider<RoomCubit>.value(value: _roomCubit),
      ],
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final profileName = state.profile?.displayName.trim();
          final authName = widget.currentUser?.displayName?.trim();
          final emailName = widget.currentUser?.email?.trim().split('@').first;
          final displayName = switch (true) {
            _ when profileName?.isNotEmpty == true => profileName!,
            _ when authName?.isNotEmpty == true => authName!,
            _ when emailName?.isNotEmpty == true => emailName!,
            _ => 'there',
          };
          final selectedPage = switch (_selectedTab) {
            0 => BlocBuilder<RoomCubit, RoomState>(
              builder: (context, roomState) =>
                  _buildRooms(displayName, roomState),
            ),
            1 => const HistoryPage(),
            2 => const StatisticsPage(),
            _ => ProfilePage(
              user: widget.currentUser,
              onSignOut: widget.onSignOut,
            ),
          };

          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: selectedPage,
                ),
              ),
            ),
            bottomNavigationBar: _buildNavigation(),
          );
        },
      ),
    );
  }

  Widget _buildRooms(String displayName, RoomState roomState) {
    return CustomScrollView(
      key: const PageStorageKey('rooms-home'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          sliver: SliverList.list(
            children: [
              _buildHeader(displayName),
              const SizedBox(height: 20),
              _buildObligationCard(),
              const SizedBox(height: 26),
              SectionHeading(
                'Your rooms',
                trailing: StatusPill(label: '${roomState.rooms.length}'),
              ),
              const SizedBox(height: 14),
              if (roomState.isLoadingRooms)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (roomState.roomsErrorMessage != null)
                _RoomListError(
                  message: roomState.roomsErrorMessage!,
                  onRetry: () => context.read<RoomCubit>().loadRooms(
                    widget.currentUser?.uid,
                  ),
                )
              else if (roomState.rooms.isEmpty)
                const _RoomsEmptyState()
              else
                for (final room in roomState.rooms) ...[
                  _RoomCard(room: room, onTap: () => _openRoom(room)),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 76),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String displayName) {
    return Row(
      children: [
        MemberAvatar(name: displayName, size: 44, color: Color(0xFFD9E8FF)),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PocketTogether',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 1),
              Text(
                'Good evening, $displayName 👋',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Activity and notifications',
          onPressed: () => _showMessage('Your activity is all caught up.'),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        IconButton(
          tooltip: 'Members',
          onPressed: () => _showMessage('Choose a room to see its members.'),
          icon: const Icon(Icons.groups_2_outlined),
        ),
      ],
    );
  }

  Widget _buildObligationCard() {
    return SurfaceCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2168EE), Color(0xFF388BFA)],
      ),
      shadowColor: Color(0x332373F4),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 320) {
                return const Row(
                  children: [
                    StatusPill(label: '3 active rooms'),
                    Spacer(),
                  ],
                );
              }
              return Row(
                children: [
                  StatusPill(
                    label: '3 active trips & groups',
                    textColor: Colors.white,
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                  Spacer(),
                  Text('Updated just now', style: _captionStyle),
                ],
              );
            },
          ),
          const SizedBox(height: 19),
          const Text(
            'Your shared obligation',
            style: TextStyle(color: AppColors.white, fontSize: 13),
          ),
          const SizedBox(height: 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'RM 428.10',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: AppColors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              StatusPill(
                label: 'In balance',
                textColor: Colors.white,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Create room',
                  icon: Icons.add_rounded,
                  onPressed: _showCreateRoom,
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showJoinRoom,
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Join room'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    foregroundColor: AppColors.white,
                    backgroundColor: Color(0x24FFFFFF),
                    side: const BorderSide(color: Color(0x38FFFFFF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.control),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    const labels = ['Rooms', 'History', 'Statistics', 'Profile'];
    const icons = [
      Icons.group_work_outlined,
      Icons.receipt_long_outlined,
      Icons.bar_chart_rounded,
      Icons.person_outline_rounded,
    ];
    return NavigationBar(
      selectedIndex: _selectedTab,
      onDestinationSelected: (index) => setState(() => _selectedTab = index),
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.paleBlue,
      height: 68,
      destinations: [
        for (var index = 0; index < labels.length; index++)
          NavigationDestination(icon: Icon(icons[index]), label: labels[index]),
      ],
    );
  }

  void _openRoom(Room room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _RoomPreviewPage(room: room),
      ),
    );
  }

  void _showCreateRoom() {
    _showRoomEntrySheet(isCreate: true);
  }

  void _showJoinRoom() {
    _showRoomEntrySheet(isCreate: false);
  }

  void _showRoomEntrySheet({required bool isCreate}) {
    final ownerId = widget.currentUser?.uid;
    if (isCreate && (ownerId == null || ownerId.isEmpty)) {
      _showMessage('Sign in to create a room.');
      return;
    }

    final Widget page = isCreate
        ? BlocProvider<RoomCubit>.value(
            value: _roomCubit,
            child: CreateRoomPage(ownerId: ownerId!),
          )
        : const JoinRoomPage();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static const _captionStyle = TextStyle(fontSize: 11, color: AppColors.white);
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onTap});

  final Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final description = room.description?.trim();
    return SurfaceCard(
      onTap: onTap,
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

class _RoomPreviewPage extends StatelessWidget {
  const _RoomPreviewPage({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    return RoomDashboardPage(
      room: RoomMock(
        name: room.name,
        subtitle: room.description ?? 'Shared room',
        emoji: '🏠',
        currency: room.currency ?? 'MYR',
        total: '—',
        members: [
          for (final member in roomMembers) member.name.split(' ').first,
        ],
        activity: 'Room created',
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
