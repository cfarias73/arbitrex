import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/alert.dart';
import '../services/purchase_service.dart';

class UserProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  UserProfile? _profile;
  List<PolyfoxAlert> _alerts = [];
  bool _isLoading = false;

  UserProfile? get profile => _profile;
  List<PolyfoxAlert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String get plan => _profile?.plan ?? 'free';
  bool get isPro => plan == 'pro' || plan == 'trader_plus' || plan == 'plus';
  int get maxAlerts => isPro ? 999 : 3;

  Future<void> loadProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Check RevenueCat status first
      final isPremium = await PurchaseService.isPremium();
      final currentPlan = isPremium ? 'pro' : 'free';

      // 2. Load from Supabase
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      _profile = UserProfile.fromJson(data);

      // 3. Sync plan if different
      if (_profile?.plan != currentPlan) {
        await _supabase
            .from('profiles')
            .update({'plan': currentPlan})
            .eq('id', userId);
        _profile = _profile?.copyWith(plan: currentPlan);
      }

      await loadAlerts();
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAlerts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await _supabase
          .from('user_alerts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _alerts = (data as List).map((e) => PolyfoxAlert.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando alertas: $e');
    }
  }

  Future<bool> createAlert(PolyfoxAlert alert) async {
    if (!isPro && _alerts.length >= 3) return false;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabase.from('user_alerts').insert({
        'user_id': userId,
        'name': alert.name,
        'type_filter': alert.type == AlertType.typeA ? ['type_a'] : [alert.type.toString().split('.').last],
        'category_filter': [],
        'min_delta': 7.0,
        'is_active': true,
      });

      await loadAlerts();
      return true;
    } catch (e) {
      debugPrint('Error creando alerta: $e');
      return false;
    }
  }

  Future<void> toggleAlert(String alertId, bool isActive) async {
    try {
      await _supabase
          .from('user_alerts')
          .update({'is_active': isActive})
          .eq('id', alertId);

      await loadAlerts();
    } catch (e) {
      debugPrint('Error toggle alerta: $e');
    }
  }

  Future<void> deleteAlert(String alertId) async {
    try {
      await _supabase
          .from('user_alerts')
          .delete()
          .eq('id', alertId);

      await loadAlerts();
    } catch (e) {
      debugPrint('Error eliminando alerta: $e');
    }
  }

  Future<void> updateFcmToken(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', userId);
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('profiles')
          .update({'notifications_enabled': enabled})
          .eq('id', userId);

      _profile = _profile?.copyWith(notificationsEnabled: enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error actualizando notificaciones: $e');
    }
  }
}
