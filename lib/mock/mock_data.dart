import '../models/opportunity.dart';
import '../models/alert.dart';
import '../models/user.dart';

class MockData {
  static final List<Opportunity> opportunities = [
    Opportunity(
      id: '1',
      type: 'type_a',
      subtype: 'complement',
      marketId1: 'will-harris-win-pennsylvania-popular-vote',
      deltaPoints: 12.5,
      category: 'Politics',
      explanation: 'Significant divergence detected between Polymarket and Kalshi outcomes. Polymarket overvaluing GOP momentum based on whale volume.',
      detectedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      isActive: true,
      deltaHistory: [],
      market: {'title': 'Harris wins Pennsylvania Popular Vote'},
    ),
    Opportunity(
      id: '2',
      type: 'type_b',
      subtype: 'inter_market',
      marketId1: 'will-bitcoin-hit-100k-in-may',
      deltaPoints: 11.2,
      category: 'Crypto',
      explanation: 'Intra-market anomaly on high-leverage liquidations. Kalshi order book shows major sell wall not present on crypto-native platforms.',
      detectedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      isActive: true,
      deltaHistory: [],
      market: {'title': 'BTC hits 100k before May'},
    ),
    Opportunity(
      id: '3',
      type: 'type_c',
      subtype: 'anomaly',
      marketId1: 'fed-remains-hawkish-in-q2',
      deltaPoints: 10.8,
      category: 'Economy',
      explanation: 'Macro data suggests interest rates will hold, but Polymarket is pricing in a 25bps cut too early compared to Kalshi CME-linked data.',
      detectedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      isActive: true,
      deltaHistory: [],
      market: {'title': 'Fed remains hawkish in Q2'},
    ),
  ];

  static final stats = {
    'totalOpportunities': 47,
    'averageMagnitude': 6.2,
    'averageCloseTime': 2.4,
    'dailyBarData': [12.0, 15.5, 9.8, 18.2, 14.0, 22.5, 16.0],
    'topCategories': [
      {'name': 'Politics', 'value': 0.85, 'count': 18},
      {'name': 'Crypto', 'value': 0.72, 'count': 12},
      {'name': 'Economy', 'value': 0.64, 'count': 10},
      {'name': 'Sports', 'value': 0.45, 'count': 7},
    ],
  };

  static final currentUser = PolyfoxUser(
    email: 'trader@polyfox.ai',
    plan: UserPlan.free,
    memberSince: DateTime.now().subtract(const Duration(days: 45)),
    favoriteCategories: ['Politics', 'Crypto'],
  );

  static final alerts = [
    PolyfoxAlert(
      id: 'a1',
      name: 'High Delta Politics',
      description: 'Notify for all politics opportunities > 8pts',
      type: AlertType.typeA,
      categories: ['Politics'],
      threshold: 8.0,
    ),
    PolyfoxAlert(
      id: 'a2',
      name: 'Crypto Anomalies',
      description: 'Sudden price gaps in major crypto pairs',
      type: AlertType.typeB,
      categories: ['Crypto'],
      threshold: 5.0,
    ),
  ];
}
