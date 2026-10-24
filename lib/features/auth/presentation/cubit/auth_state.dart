import 'package:firebase_auth/firebase_auth.dart';

import '../../models/auth_user.dart';

class AuthState {
  const AuthState({
    this.errorMessage,
    this.isLoading = false,
    this.isSuccess = false,
  });

  final String? errorMessage;
  final bool isLoading;
  final bool isSuccess;
}

class Unauthenticated extends AuthState {
  const Unauthenticated() : super();
}

class AuthInitial extends AuthState {
  const AuthInitial() : super();
}

class AuthLoading extends AuthState {
  const AuthLoading() : super(isLoading: true);
}

class AuthValidatingProfile extends AuthState {
  const AuthValidatingProfile() : super(isLoading: true);
}

class Authenticated extends AuthState {
  const Authenticated(this.user) : super(isSuccess: true);

  final User user;
}

class AuthenticatedSession extends AuthState {
  const AuthenticatedSession(this.user) : super(isSuccess: true);

  final AuthUser user;
}

class AuthValidationError extends AuthState {
  const AuthValidationError({required String message})
    : super(errorMessage: message);
}

class AuthFailure extends AuthState {
  const AuthFailure({String? errorMessage}) : super(errorMessage: errorMessage);
}
