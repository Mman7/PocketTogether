import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import '../features/rooms/data/room_repository.dart';
import '../features/rooms/presentation/pages/rooms_page.dart';
import 'theme/app_theme.dart';

class PocketTogetherApp extends StatefulWidget {
  const PocketTogetherApp({
    this.authRepository,
    this.profileRepository,
    this.roomRepository,
    this.expenseRepository,
    super.key,
  });

  final AuthRepository? authRepository;
  final ProfileRepository? profileRepository;
  final RoomRepository? roomRepository;
  final ExpenseRepository? expenseRepository;

  @override
  State<PocketTogetherApp> createState() => _PocketTogetherAppState();
}

class _PocketTogetherAppState extends State<PocketTogetherApp> {
  late final AuthRepository _authRepository;
  late final ProfileRepository _profileRepository;
  late final RoomRepository _roomRepository;
  late final ExpenseRepository _expenseRepository;
  late final AuthCubit _authCubit;
  late final _AuthStateRefresh _authStateRefresh;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRepository =
        widget.authRepository ?? FirebaseAuthRepository(FirebaseAuth.instance);
    _profileRepository =
        widget.profileRepository ??
        FirebaseProfileRepository(FirebaseFirestore.instance);
    _roomRepository =
        widget.roomRepository ??
        FirebaseRoomRepository(FirebaseFirestore.instance);
    _expenseRepository =
        widget.expenseRepository ??
        FirebaseExpenseRepository(FirebaseFirestore.instance);

    _authCubit = AuthCubit(
      authRepository: _authRepository,
      profileRepository: _profileRepository,
      firebaseAuth: widget.authRepository == null
          ? FirebaseAuth.instance
          : null,
    );
    _authStateRefresh = _AuthStateRefresh(_authCubit);
    unawaited(_authCubit.initialize());
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
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: '/rooms',
          builder: (context, state) => RoomsPage(
            currentUser: _authRepository.currentUser,
            profileRepository: _profileRepository,
            roomRepository: _roomRepository,
            expenseRepository: _expenseRepository,
            onSignOut: () => context.read<AuthCubit>().signOut(),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
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
