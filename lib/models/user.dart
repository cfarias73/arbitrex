enum UserPlan { free, pro }

class ArbitrexUser {
  final String email;
  final UserPlan plan;
  final DateTime memberSince;
  final List<String> favoriteCategories;

  ArbitrexUser({
    required this.email,
    this.plan = UserPlan.free,
    required this.memberSince,
    this.favoriteCategories = const [],
  });
}
