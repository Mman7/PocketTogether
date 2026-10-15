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
import '../../../statistics/presentation/pages/statistics_page.dart';
import 'room_dashboard_page.dart';
import 'room_entry_pages.dart';

class RoomsPage extends StatefulWidget {
  const RoomsPage({
    required this.onSignOut,
    required this.profileRepository,
    this.currentUser,
    super.key,
  });

  final Future<void> Function() onSignOut;
  final ProfileRepository profileRepository;
  final AuthUser? currentUser;

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ProfileCubit(widget.profileRepository)..load(widget.currentUser?.uid),
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
            0 => _buildRooms(displayName),
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

  Widget _buildRooms(String displayName) {
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
                trailing: StatusPill(label: '${rooms.length}'),
              ),
              const SizedBox(height: 14),
              for (final room in rooms) ...[
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

  void _openRoom(RoomMock room) {
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
    final page = isCreate ? const CreateRoomPage() : const JoinRoomPage();
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

  final RoomMock room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                child: Text(room.emoji, style: const TextStyle(fontSize: 25)),
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
                      room.subtitle,
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
              if (room.live)
                const StatusPill(label: 'Live', color: AppColors.paleCyan)
              else
                StatusPill(label: '${room.members.length} members'),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: AppColors.paleBlue),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total spent',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      room.total,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              AvatarStack(names: room.members),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.paleBlue.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    room.activity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomPreviewPage extends StatelessWidget {
  const _RoomPreviewPage({required this.room});

  final RoomMock room;

  @override
  Widget build(BuildContext context) {
    return RoomDashboardPage(room: room);
  }
}
