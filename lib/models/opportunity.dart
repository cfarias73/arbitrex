import 'dart:convert';

class Opportunity {
  final String id;
  final String type;
  final String subtype;
  final String marketId1;
  final String? marketId2;
  final double deltaPoints;
  final String category;
  final String explanation;
  final DateTime detectedAt;
  final DateTime? closedAt;
  final bool isActive;
  final List<Map<String, dynamic>> deltaHistory;
  final Map<String, dynamic>? market; // join con markets

  Opportunity({
    required this.id,
    required this.type,
    required this.subtype,
    required this.marketId1,
    this.marketId2,
    required this.deltaPoints,
    required this.category,
    required this.explanation,
    required this.detectedAt,
    this.closedAt,
    required this.isActive,
    required this.deltaHistory,
    this.market,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) => Opportunity(
    id: json['id'],
    type: json['type'],
    subtype: json['subtype'] ?? '',
    marketId1: json['market_id_1'],
    marketId2: json['market_id_2'],
    deltaPoints: (json['delta_points'] as num).toDouble(),
    category: json['category'] ?? 'other',
    explanation: json['explanation'] ?? '',
    detectedAt: DateTime.parse(json['detected_at']),
    closedAt: json['closed_at'] != null ? DateTime.parse(json['closed_at']) : null,
    isActive: json['is_active'] ?? true,
    deltaHistory: List<Map<String, dynamic>>.from(json['delta_history'] ?? []),
    market: json['market'],
  );

  String get displayTitle => market?['title'] ?? marketId1;

  /// Resolution/end date from the linked market or cross explanation JSON
  DateTime? get endDate {
    final marketEnd = market?['end_date'];
    if (marketEnd != null && marketEnd is String && marketEnd.isNotEmpty) {
      return DateTime.tryParse(marketEnd);
    }
    if (type == 'type_b' && explanation.startsWith('{')) {
      try {
        final decoded = jsonDecode(explanation) as Map<String, dynamic>;
        final ed = decoded['end_date'];
        if (ed != null && ed is String && ed.isNotEmpty) {
          return DateTime.tryParse(ed);
        }
      } catch (_) {}
    }
    return null;
  }

  /// Days until resolution (null if unknown)
  int? get daysToResolution {
    final ed = endDate;
    if (ed == null) return null;
    final diff = ed.difference(DateTime.now().toUtc()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Time horizon label
  String get horizonLabel {
    final days = daysToResolution;
    if (days == null) return 'Sin fecha';
    if (days <= 7) return '≤ 7d';
    if (days <= 30) return '≤ 30d';
    return '+30d';
  }

  String get timeAgo {
    final diff = DateTime.now().toUtc().difference(detectedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  bool get isDelayed =>
    DateTime.now().toUtc().difference(detectedAt).inMinutes < 10;
}
