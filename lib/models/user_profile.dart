class UserProfile {
  final String id;
  final String email;
  final String plan;
  final DateTime? planExpiresAt;
  final bool notificationsEnabled;
  final List<String> favoriteCategories;

  UserProfile({
    required this.id,
    required this.email,
    required this.plan,
    this.planExpiresAt,
    required this.notificationsEnabled,
    required this.favoriteCategories,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    email: json['email'],
    plan: json['plan'] ?? 'free',
    planExpiresAt: json['plan_expires_at'] != null
        ? DateTime.parse(json['plan_expires_at'])
        : null,
    notificationsEnabled: json['notifications_enabled'] ?? true,
    favoriteCategories: List<String>.from(json['favorite_categories'] ?? []),
  );

  UserProfile copyWith({
    bool? notificationsEnabled,
    String? plan,
  }) => UserProfile(
    id: id,
    email: email,
    plan: plan ?? this.plan,
    planExpiresAt: planExpiresAt,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    favoriteCategories: favoriteCategories,
  );
}
