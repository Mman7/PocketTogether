import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocket_together/features/profile/presentation/cubit/profile_state.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/money_format.dart';
import '../../../auth/models/auth_user.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../../expenses/data/expense_repository.dart';
import '../../../expenses/presentation/pages/history_page.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../statistics/data/expense_statistics_repository.dart';
import '../../data/room_repository.dart';
import '../../data/room_activity_repository.dart';
import '../cubit/room_ledger_cubit.dart';
import '../cubit/room_ledger_state.dart';
import '../cubit/room_cubit.dart';
import '../cubit/room_state.dart';
import '../../models/room.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import 'room_dashboard_page.dart';
import 'create_room_page.dart';
import 'join_room_page.dart';

class RoomsPage extends StatefulWidget {
  const RoomsPage({
    required this.onSignOut,
    required this.profileRepository,
    required this.roomRepository,
    required this.expenseRepository,
    required this.statisticsRepository,
    required this.activityRepository,
    this.currentUser,
    super.key,
  });

  final Future<void> Function() onSignOut;
  final ProfileRepository profileRepository;
  final RoomRepository roomRepository;
  final ExpenseRepository expenseRepository;
  final ExpenseStatisticsRepository statisticsRepository;
  final RoomActivityRepository activityRepository;
  final AuthUser? currentUser;

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  int _selectedTab = 0;
  late final RoomCubit _roomCubit;
  late final RoomLedgerCubit _ledgerCubit;

  @override
  void initState() {
    super.initState();
    _roomCubit = RoomCubit(widget.roomRepository)
      ..loadRooms(widget.currentUser?.uid);
    _ledgerCubit = RoomLedgerCubit(
      roomRepository: widget.roomRepository,
      expenseRepository: widget.expenseRepository,
      statisticsRepository: widget.statisticsRepository,
      userId: widget.currentUser?.uid ?? '',
    );
  }

  @override
  void dispose() {
    _roomCubit.close();
    _ledgerCubit.close();
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
        BlocProvider<RoomLedgerCubit>.value(value: _ledgerCubit),
      ],
      child: BlocListener<RoomCubit, RoomState>(
        listenWhen: (previous, current) =>
            !identical(previous.rooms, current.rooms),
        listener: (_, state) => _ledgerCubit.loadRooms(state.rooms),
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            final profileName = state.profile?.displayName.trim();
            final authName = widget.currentUser?.displayName?.trim();
            final emailName = widget.currentUser?.email
                ?.trim()
                .split('@')
                .first;
            final displayName = switch (true) {
              _ when profileName?.isNotEmpty == true => profileName!,
              _ when authName?.isNotEmpty == true => authName!,
              _ when emailName?.isNotEmpty == true => emailName!,
              _ => 'there',
            };
            final selectedPage = switch (_selectedTab) {
              0 => BlocBuilder<RoomCubit, RoomState>(
                builder: (context, roomState) => _buildRooms(
                  displayName,
                  roomState,
                  context.watch<RoomLedgerCubit>().state,
                ),
              ),
              1 => HistoryPage(
                currentUserId: widget.currentUser?.uid ?? '',
                currentUserDisplayName: displayName,
                expenseRepository: widget.expenseRepository,
              ),
              2 => StatisticsPage(currentUserId: widget.currentUser?.uid ?? ''),
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
      ),
    );
  }

  Widget _buildRooms(
    String displayName,
    RoomState roomState,
    RoomLedgerState ledgerState,
  ) {
    return CustomScrollView(
      key: const PageStorageKey('rooms-home'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          sliver: SliverList.list(
            children: [
              _buildHeader(displayName),
              const SizedBox(height: 20),
              _buildObligationCard(roomState, ledgerState),
              const SizedBox(height: 26),
              SectionHeading(
                'Your rooms',
                icon: Icons.people_rounded,
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
                  onRetry: () => _roomCubit.loadRooms(widget.currentUser?.uid),
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
      ],
    );
  }

  Widget _buildObligationCard(
    RoomState roomState,
    RoomLedgerState ledgerState,
  ) {
    final totalSpendByCurrency = ledgerState.totalSpendByCurrency();
    final totalSpendLabel = totalSpendByCurrency.isEmpty
        ? formatCurrency(0, currency: 'MYR')
        : totalSpendByCurrency.entries
              .map((entry) => formatCurrency(entry.value, currency: entry.key))
              .join(' · ');

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
                return Row(
                  children: [
                    StatusPill(label: '${roomState.rooms.length} active rooms'),
                    const Spacer(),
                  ],
                );
              }
              return Row(
                children: [
                  StatusPill(
                    label: '${roomState.rooms.length} active rooms',
                    textColor: Colors.white,
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                  Spacer(),
                ],
              );
            },
          ),
          const SizedBox(height: 19),
          const Text(
            'Total spend',
            style: TextStyle(color: AppColors.white, fontSize: 13),
          ),
          const SizedBox(height: 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  totalSpendLabel,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: AppColors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
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
        builder: (context) => _RoomPreviewPage(
          room: room,
          userId: widget.currentUser?.uid ?? '',
          displayName:
              widget.currentUser?.displayName?.trim().isNotEmpty == true
              ? widget.currentUser!.displayName!.trim()
              : widget.currentUser?.email?.trim().split('@').first ?? 'Member',
          roomRepository: widget.roomRepository,
          expenseRepository: widget.expenseRepository,
          activityRepository: widget.activityRepository,
          onDeleted: () => _roomCubit.removeRoom(room.id),
        ),
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
    final userId = widget.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      _showMessage('Sign in to create a room.');
      return;
    }

    final Widget page = isCreate
        ? BlocProvider<RoomCubit>.value(
            value: _roomCubit,
            child: const CreateRoomPage(),
          )
        : BlocProvider<RoomCubit>.value(
            value: _roomCubit,
            child: JoinRoomPage(onJoined: (room) => _openRoom(room)),
          );
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
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
  const _RoomPreviewPage({
    required this.room,
    required this.userId,
    required this.displayName,
    required this.roomRepository,
    required this.expenseRepository,
    required this.activityRepository,
    required this.onDeleted,
  });

  final Room room;
  final String userId;
  final String displayName;
  final RoomRepository roomRepository;
  final ExpenseRepository expenseRepository;
  final RoomActivityRepository activityRepository;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return RoomDashboardPage(
      room: room,
      currentUserId: userId,
      currentUserDisplayName: displayName,
      roomRepository: roomRepository,
      expenseRepository: expenseRepository,
      activityRepository: activityRepository,
      onDeleted: onDeleted,
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
