import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/opportunity.dart';

class FeedProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Opportunity> _opportunities = [];
  bool _isLoading = true;
  String? _error;
  String _activeFilter = 'all';
  String _timeFilter = 'all'; // 'all', '7d', '30d', '30d+'
  RealtimeChannel? _channel;

  List<Opportunity> get opportunities => _filtered();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get activeFilter => _activeFilter;
  String get timeFilter => _timeFilter;

  Future<void> initialize(String userPlan) async {
    await _loadOpportunities(userPlan);
    _subscribeRealtime(userPlan);
  }

  Future<void> _loadOpportunities(String userPlan) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final typeAQuery = _supabase
          .from('opportunities')
          .select('*, market:market_id_1(title, category, prob_yes, prob_no, end_date)')
          .eq('is_active', true)
          .eq('type', 'type_a')
          .order('detected_at', ascending: false)
          .limit(30);

      final typeBQuery = _supabase
          .from('opportunities')
          .select('*, market:market_id_1(title, category, prob_yes, prob_no, end_date)')
          .eq('is_active', true)
          .eq('type', 'type_b')
          .order('detected_at', ascending: false)
          .limit(30);

      final typeCQuery = _supabase
          .from('opportunities')
          .select('*, market:market_id_1(title, category, prob_yes, prob_no, end_date)')
          .eq('is_active', true)
          .eq('type', 'type_c')
          .order('detected_at', ascending: false)
          .limit(30);

      final results = await Future.wait([typeAQuery, typeBQuery, typeCQuery]);
      
      final allData = [
        ...results[0] as List, 
        ...results[1] as List, 
        ...results[2] as List
      ];

      var ops = allData.map((e) => Opportunity.fromJson(e)).toList();
      ops.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
      
      _opportunities = ops;

    } catch (e) {
      _error = 'Error cargando oportunidades';
      debugPrint('Feed error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void _subscribeRealtime(String userPlan) {
    _channel = _supabase
        .channel('opportunities_feed')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'opportunities',
          callback: (payload) {
            final newOpp = Opportunity.fromJson(payload.newRecord);
            _opportunities.insert(0, newOpp);
            if (_opportunities.length > 100) _opportunities.removeLast();
            notifyListeners();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'opportunities',
          callback: (payload) {
            final updated = Opportunity.fromJson(payload.newRecord);
            final index = _opportunities.indexWhere((o) => o.id == updated.id);

            if (!updated.isActive) {
              if (index >= 0) _opportunities.removeAt(index);
            } else if (index >= 0) {
              _opportunities[index] = updated;
            }
            notifyListeners();
          },
        )
        .subscribe();
  }

  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  void setTimeFilter(String filter) {
    _timeFilter = filter;
    notifyListeners();
  }

  List<Opportunity> _filtered() {
    List<Opportunity> result;

    if (_activeFilter == 'Cross') {
      result = _opportunities.where((o) => o.type == 'type_b').toList();
    } else {
      final typeA = _opportunities.where((o) => o.type == 'type_a').toList();
      if (_activeFilter == 'Free') {
        result = typeA.where((o) => o.deltaPoints < 3.1).toList();
      } else if (_activeFilter == 'Pro') {
        result = typeA.where((o) => o.deltaPoints >= 3.1).toList();
      } else {
        result = List.from(_opportunities);
      }
    }

    // Apply time filter
    if (_timeFilter != 'all') {
      result = result.where((o) {
        final days = o.daysToResolution;
        if (days == null) return _timeFilter == '90d+'; // Unknown = long term
        if (_timeFilter == '7d') return days <= 7;
        if (_timeFilter == '90d') return days > 7 && days <= 90;
        if (_timeFilter == '90d+') return days > 90;
        return true;
      }).toList();
    }

    return result;
  }

  Future<void> refresh(String userPlan) => _loadOpportunities(userPlan);

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
