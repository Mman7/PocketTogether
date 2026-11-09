import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocket_together/features/profile/presentation/cubit/profile_state.dart';
import 'package:pocket_together/shared/presentation/widgets/ambient_background.dart';

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
import '../widgets/room_list.dart';
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
    this.initialTab = 0,
    this.currentUser,
    super.key,
  });

  final Future<void> Function() onSignOut;
  final ProfileRepository profileRepository;
  final RoomRepository roomRepository;
  final ExpenseRepository expenseRepository;
  final ExpenseStatisticsRepository statisticsRepository;
  final RoomActivityRepository activityRepository;
  final int initialTab;
  final AuthUser? currentUser;

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  late int _selectedTab;
  late final RoomCubit _roomCubit;
  late final RoomLedgerCubit _ledgerCubit;
  String? _lastVisitedRoomId;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 3).toInt();
    _roomCubit = RoomCubit(widget.roomRepository)
      ..loadRooms(widget.currentUser?.uid);
    _ledgerCubit = RoomLedgerCubit(
      roomRepository: widget.roomRepository,
      expenseRepository: widget.expenseRepository,
      statisticsRepository: widget.statisticsRepository,
      userId: widget.currentUser?.uid ?? '',
    );
    unawaited(_loadLastVisitedRoom());
  }

  String? get _lastVisitedRoomKey {
    final userId = widget.currentUser?.uid;
    if (userId == null || userId.isEmpty) return null;
    return 'last_visited_room_id_$userId';
  }

  Future<void> _loadLastVisitedRoom() async {
    final key = _lastVisitedRoomKey;
    if (key == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      final roomId = preferences.getString(key);
      setState(() => _lastVisitedRoomId = roomId);
    } catch (_) {
      // Preferences are optional for rendering the rooms list.
    }
  }

  void _rememberLastVisitedRoom(String roomId) {
    final key = _lastVisitedRoomKey;
    if (key == null) return;
    setState(() => _lastVisitedRoomId = roomId);
    unawaited(_saveLastVisitedRoom(key, roomId));
  }

  Future<void> _saveLastVisitedRoom(String key, String roomId) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(key, roomId);
    } catch (_) {
      // The in-memory highlight still works when persistence is unavailable.
    }
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
              RoomList(
                rooms: roomState.rooms,
                isLoading: roomState.isLoadingRooms,
                errorMessage: roomState.roomsErrorMessage,
                lastVisitedRoomId: _lastVisitedRoomId,
                onRetry: () => _roomCubit.loadRooms(widget.currentUser?.uid),
                onRoomTap: _openRoom,
              ),
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
                  label: 'Create',
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
                  label: const Text('Join'),
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
      onDestinationSelected: (index) {
        if (index == 1 || index == 2) {
          _ledgerCubit.refresh();
        }
        setState(() => _selectedTab = index);
      },
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
    _rememberLastVisitedRoom(room.id);
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
            child: AmbientBackground(child: const CreateRoomPage()),
          )
        : BlocProvider<RoomCubit>.value(
            value: _roomCubit,
            child: AmbientBackground(
              child: JoinRoomPage(
                onJoined: (room) {
                  _openRoom(room);
                },
              ),
            ),
          );
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    return AmbientBackground(
      child: RoomDashboardPage(
        room: room,
        currentUserId: userId,
        currentUserDisplayName: displayName,
        roomRepository: roomRepository,
        expenseRepository: expenseRepository,
        activityRepository: activityRepository,
        onDeleted: onDeleted,
      ),
    );
  }
}
