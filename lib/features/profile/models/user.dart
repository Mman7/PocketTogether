class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    this.email,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String displayName;
  final String? email;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
