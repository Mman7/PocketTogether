import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/firebase_auth_repository.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/cubit/auth_state.dart';
import '../features/auth/presentation/pages/auth_pages.dart';
import '../features/expenses/data/expense_repository.dart';
import '../features/expenses/data/firebase_expense_repository.dart';
import '../features/profile/data/firebase_profile_repository.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/rooms/data/firebase_room_repository.dart';
import '../features/rooms/data/firebase_room_activity_repository.dart';
import '../features/rooms/data/room_repository.dart';
import '../features/rooms/data/room_activity_repository.dart';
import '../features/rooms/models/room_activity.dart';
import '../features/rooms/presentation/pages/rooms_page.dart';
import '../features/statistics/data/expense_statistics_repository.dart';
import '../features/statistics/data/firebase_expense_statistics_repository.dart';
import '../features/statistics/data/expense_statistics_model.dart';
import '../core/notifications/notification_handler.dart';
import '../core/notifications/notification_payload.dart';
import '../shared/presentation/widgets/ambient_background.dart';
import 'theme/app_theme.dart';

class PocketTogetherApp extends StatefulWidget {
  const PocketTogetherApp({
    this.authRepository,
    this.profileRepository,
    this.roomRepository,
    this.expenseRepository,
    this.activityRepository,
    this.functions,
    this.statisticsRepository,
    this.notificationHandler,
    super.key,
  });

  final AuthRepository? authRepository;
  final ProfileRepository? profileRepository;
  final RoomRepository? roomRepository;
  final ExpenseRepository? expenseRepository;
  final RoomActivityRepository? activityRepository;
  final FirebaseFunctions? functions;
  final ExpenseStatisticsRepository? statisticsRepository;
  final NotificationHandler? notificationHandler;

  @override
  State<PocketTogetherApp> createState() => _PocketTogetherAppState();
}

class _PocketTogetherAppState extends State<PocketTogetherApp> {
  late final AuthRepository _authRepository;
  late final ProfileRepository _profileRepository;
  late final RoomRepository _roomRepository;
  late final ExpenseRepository _expenseRepository;
  late final ExpenseStatisticsRepository _statisticsRepository;
  late final RoomActivityRepository _activityRepository;
  late final AuthCubit _authCubit;
  late final _AuthStateRefresh _authStateRefresh;
  late final GoRouter _router;
  late final StreamSubscription<AuthState> _notificationAuthSubscription;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  NotificationPayload? _pendingNotification;

  @override
  void initState() {
    super.initState();
    _authRepository =
        widget.authRepository ?? FirebaseAuthRepository(FirebaseAuth.instance);
    _profileRepository =
        widget.profileRepository ??
        FirebaseProfileRepository(FirebaseFirestore.instance);
    final functions =
        widget.functions ??
        (widget.roomRepository == null || widget.expenseRepository == null
            ? FirebaseFunctions.instanceFor(region: 'us-central1')
            : null);
    _roomRepository =
        widget.roomRepository ??
        FirebaseRoomRepository(
          FirebaseFirestore.instance,
          functions: functions,
        );
    _expenseRepository =
        widget.expenseRepository ??
        FirebaseExpenseRepository(
          FirebaseFirestore.instance,
          functions: functions,
        );
    _statisticsRepository =
        widget.statisticsRepository ??
        (widget.roomRepository == null
            ? FirebaseExpenseStatisticsRepository(FirebaseFirestore.instance)
            : const _EmptyExpenseStatisticsRepository());
    _activityRepository =
        widget.activityRepository ??
        (widget.roomRepository == null
            ? FirebaseRoomActivityRepository(FirebaseFirestore.instance)
            : const _EmptyRoomActivityRepository());

    _authCubit = AuthCubit(
      authRepository: _authRepository,
      profileRepository: _profileRepository,
      firebaseAuth: widget.authRepository == null
          ? FirebaseAuth.instance
          : null,
    );

    _authStateRefresh = _AuthStateRefresh(_authCubit);
    _notificationAuthSubscription = _authCubit.stream.listen((_) {
      final pending = _pendingNotification;
      if (pending == null || !_authRepository.isSignedIn) return;
      _pendingNotification = null;
      unawaited(_navigateForNotification(pending));
    });
    unawaited(_authCubit.initialize());

    // Initialize the router after setting up authentication and state refresh
    _router = GoRouter(
      initialLocation: _authRepository.isSignedIn ? '/rooms' : '/login',
      refreshListenable: _authStateRefresh,
      redirect: (context, state) {
        final isAuthRoute = switch (state.matchedLocation) {
          '/login' || '/register' || '/forgot-password' => true,
          _ => false,
        };
        final authState = _authCubit.state;
        final isAuthenticated =
            authState is Authenticated ||
            authState is AuthenticatedSession ||
            ((authState is AuthInitial || authState is AuthValidatingProfile) &&
                _authRepository.isSignedIn);
        if (isAuthenticated && isAuthRoute) return '/rooms';
        if (!isAuthenticated && !isAuthRoute) return '/login';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              AmbientBackground(child: const LoginPage()),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => AmbientBackground(
            child: AmbientBackground(child: const RegisterPage()),
          ),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) =>
              AmbientBackground(child: const ForgotPasswordPage()),
        ),
        GoRoute(
          path: '/rooms',
          builder: (context, state) => AmbientBackground(
            child: RoomsPage(
              initialTab: state.uri.queryParameters['tab'] == 'history' ? 1 : 0,
              currentUser: _authRepository.currentUser,
              profileRepository: _profileRepository,
              roomRepository: _roomRepository,
              expenseRepository: _expenseRepository,
              activityRepository: _activityRepository,
              statisticsRepository: _statisticsRepository,
              onSignOut: () => context.read<AuthCubit>().signOut(),
            ),
          ),
        ),
      ],
    );

    unawaited(
      widget.notificationHandler?.initialize(
        onForegroundMessage: _handleForegroundMessage,
        onNotificationTap: _handleNotificationTap,
      ),
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message.notification?.title ?? 'New PocketTogether activity',
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(NotificationPayload payload) async {
    if (!_authRepository.isSignedIn) {
      if (_authCubit.state is AuthInitial ||
          _authCubit.state is AuthValidatingProfile) {
        _pendingNotification = payload;
        return;
      }
      _router.go('/login');
      return;
    }
    await _navigateForNotification(payload);
  }

  Future<void> _navigateForNotification(NotificationPayload payload) async {
    final tab = payload.type == NotificationType.memberJoined
        ? null
        : 'history';
    final query = tab == null ? '' : '?tab=$tab';
    _router.go('/rooms$query');
  }

  @override
  void dispose() {
    _notificationAuthSubscription.cancel();
    _router.dispose();
    _authStateRefresh.dispose();
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authCubit,
      child: MaterialApp.router(
        title: 'PocketTogether',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        scaffoldMessengerKey: _scaffoldMessengerKey,
        routerConfig: _router,
      ),
    );
  }
}

class _AuthStateRefresh extends ChangeNotifier {
  _AuthStateRefresh(AuthCubit authCubit) : _authCubit = authCubit {
    _subscription = _authCubit.stream.listen((_) => notifyListeners());
  }

  final AuthCubit _authCubit;
  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _EmptyExpenseStatisticsRepository implements ExpenseStatisticsRepository {
  const _EmptyExpenseStatisticsRepository();

  @override
  Future<ExpenseStatistics> getStatistics({
    required String roomId,
    required String userId,
    DateTime? month,
  }) async {
    return ExpenseStatistics(
      personalAllTimeInCents: 0,
      personalMonthlyInCents: 0,
      roomAllTimeInCents: 0,
      roomMonthlyInCents: 0,
      month: '',
    );
  }
}

class _EmptyRoomActivityRepository implements RoomActivityRepository {
  const _EmptyRoomActivityRepository();

  @override
  Future<RoomActivityPage> getPage({
    required String roomId,
    RoomActivity? after,
    int limit = 20,
  }) async {
    return const RoomActivityPage(items: [], hasMore: false);
  }
}
