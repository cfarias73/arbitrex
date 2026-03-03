enum UserPlan { free, pro }

class PolyfoxUser {
  final String email;
  final UserPlan plan;
  final DateTime memberSince;
  final List<String> favoriteCategories;

  PolyfoxUser({
    required this.email,
    this.plan = UserPlan.free,
    required this.memberSince,
    this.favoriteCategories = const [],
  });
}
