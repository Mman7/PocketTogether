import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/profile_repository.dart';
import '../../models/user.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState());

  final ProfileRepository _repository;

  Future<void> load(String? uid) async {
    if (uid == null || uid.isEmpty) return;

    emit(const ProfileState(isLoading: true));
    try {
      final profile = await _repository.getProfile(uid);
      emit(ProfileState(profile: profile));
    } on ProfileFailure catch (error) {
      emit(ProfileState(errorMessage: error.message));
    } catch (_) {
      emit(const ProfileState(errorMessage: 'Unable to load your profile.'));
    }
  }

  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    final name = displayName.trim();
    await _repository.updateDisplayName(uid: uid, displayName: name);

    final profile = state.profile;
    emit(
      ProfileState(
        profile: UserProfile(
          uid: uid,
          displayName: name,
          email: profile?.email,
          createdAt: profile?.createdAt,
          updatedAt: profile?.updatedAt,
        ),
      ),
    );
  }
}
