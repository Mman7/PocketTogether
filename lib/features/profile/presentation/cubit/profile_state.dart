import '../../model/user.dart';

class ProfileState {
  const ProfileState({this.isLoading = false, this.profile, this.errorMessage});

  final bool isLoading;
  final UserProfile? profile;
  final String? errorMessage;
}
