import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> signIn({required String email, required String password}) =>
      _perform(
        () => _repository.signIn(email: email, password: password),
        'Unable to sign in. Try again.',
      );

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) => _perform(
    () => _repository.register(name: name, email: email, password: password),
    'Unable to create your account. Try again.',
  );

  Future<void> sendPasswordResetEmail({required String email}) => _perform(
    () => _repository.sendPasswordResetEmail(email: email),
    'Unable to send the reset link. Try again.',
  );

  Future<void> signOut() => _repository.signOut();

  void reset() => emit(const AuthState());

  Future<void> _perform(
    Future<void> Function() action,
    String fallbackMessage,
  ) async {
    emit(const AuthState(status: AuthStatus.loading));
    try {
      await action();
      emit(const AuthState(status: AuthStatus.success));
    } on AuthFailure catch (error) {
      emit(AuthState(status: AuthStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(
        AuthState(status: AuthStatus.failure, errorMessage: fallbackMessage),
      );
    }
  }
}
