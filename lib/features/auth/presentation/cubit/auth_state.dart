import '../../models/auth_user.dart';

/// Base authentication view state consumed by routing and auth pages.
///
/// Authenticated state carries the platform-neutral user model supplied by the
/// repository, keeping presentation code independent of the auth provider.
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

  final AuthUser user;
}

class AuthValidationError extends AuthState {
  const AuthValidationError({required String message})
    : super(errorMessage: message);
}

class AuthFailure extends AuthState {
  const AuthFailure({super.errorMessage});
}
