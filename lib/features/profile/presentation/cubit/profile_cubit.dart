import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/profile_repository.dart';
import '../../models/user.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState());

  final ProfileRepository _repository;

  Future<void> load(String? uid) async {
    if (uid == null || uid.isEmpty) return;

    _emit(const ProfileState(isLoading: true));
    try {
      final profile = await _repository.getProfile(uid);
      _emit(ProfileState(profile: profile));
    } on ProfileFailure catch (error) {
      _emit(ProfileState(errorMessage: error.message));
    } catch (error, stackTrace) {
      debugPrint('[Profile] Unexpected load error: $error');
      debugPrintStack(stackTrace: stackTrace, label: '[Profile]');
      _emit(const ProfileState(errorMessage: 'Unable to load your profile.'));
    }
  }

  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    final name = displayName.trim();
    await _repository.updateDisplayName(uid: uid, displayName: name);

    final current = state.profile;
    _emit(
      ProfileState(
        profile: UserProfile(
          uid: uid,
          displayName: name,
          email: current?.email,
          createdAt: current?.createdAt,
          updatedAt: current?.updatedAt,
        ),
      ),
    );
  }

  /// Guards against emitting after close, which throws a StateError.
  void _emit(ProfileState next) {
    if (!isClosed) emit(next);
  }
}
