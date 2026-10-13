import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/profile_repository.dart';
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
}
