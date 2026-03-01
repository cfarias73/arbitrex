import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/opportunity.dart';

class FeedProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Opportunity> _opportunities = [];
  bool _isLoading = true;
  String? _error;
  String _activeFilter = 'all';
  RealtimeChannel? _channel;

  List<Opportunity> get opportunities => _filtered();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get activeFilter => _activeFilter;

  Future<void> initialize(String userPlan) async {
    await _loadOpportunities(userPlan);
    _subscribeRealtime(userPlan);
  }

  Future<void> _loadOpportunities(String userPlan) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var query = _supabase
          .from('opportunities')
          .select('*, market:market_id_1(title, category, prob_yes, prob_no)')
          .eq('is_active', true)
          .order('detected_at', ascending: false)
          .limit(50);

      // Plan free: solo tipo_a y con delay temporalmente a 0 para pruebas (originalmente 15 min)
      if (userPlan == 'free') {
        final cutoff = DateTime.now().toUtc().subtract(const Duration(minutes: 0));
        final data = await _supabase
            .from('opportunities')
            .select('*, market:market_id_1(title, category, prob_yes, prob_no)')
            .eq('is_active', true)
            .eq('type', 'type_a')
            .lt('detected_at', cutoff.toIso8601String())
            .order('detected_at', ascending: false)
            .limit(50);
        _opportunities = (data as List)
            .map((e) => Opportunity.fromJson(e))
            .toList();
      } else {
        final data = await query;
        _opportunities = (data as List)
            .map((e) => Opportunity.fromJson(e))
            .toList();
      }

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

            // Respetar restricciones del plan
            if (userPlan == 'free') {
              if (newOpp.type != 'type_a') return;
              // El delay de 15 min se maneja mostrando el item con gate
            }

            _opportunities.insert(0, newOpp);
            // Mantener máximo 50 items en memoria
            if (_opportunities.length > 50) _opportunities.removeLast();
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
              // Remover oportunidades cerradas del feed
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

  List<Opportunity> _filtered() {
    if (_activeFilter == 'all' || _activeFilter == 'Todos') return _opportunities;
    if (_activeFilter == 'intra' || _activeFilter == 'Intra') return _opportunities.where((o) => o.type == 'type_a').toList();
    if (_activeFilter == 'inter' || _activeFilter == 'Inter') return _opportunities.where((o) => o.type == 'type_b').toList();
    if (_activeFilter == 'anomaly' || _activeFilter == 'Anomalía') return _opportunities.where((o) => o.type == 'type_c').toList();
    if (_activeFilter == '7pts' || _activeFilter == '≥7pts') return _opportunities.where((o) => o.deltaPoints >= 7).toList();
    return _opportunities;
  }

  Future<void> refresh(String userPlan) => _loadOpportunities(userPlan);

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
