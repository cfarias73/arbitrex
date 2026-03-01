import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _supabase = Supabase.instance.client;

  static Future<void> initialize() async {
    // Solicitar permisos
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Escuchar cambios de autenticación para sincronizar el token
    _supabase.auth.onAuthStateChange.listen((data) async {
      if (data.session?.user != null) {
        final token = await _messaging.getToken();
        if (token != null) {
          await _saveFcmToken(token);
        }
      }
    });

    // Obtener y guardar token FCM inicial si ya hay usuario
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveFcmToken(token);
      }
    } catch (e) {
      debugPrint('Error getting token: $e');
    }

    // Actualizar token si se renueva
    _messaging.onTokenRefresh.listen(_saveFcmToken);

    // Manejar notificaciones cuando app está en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Manejar tap en notificación cuando app estaba en background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Verificar si la app fue abierta desde una notificación
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  static Future<void> _saveFcmToken(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
      debugPrint('FCM Token sync complete');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    // Aquí se podría mostrar un SnackBar o banner personalizado si se desea
  }

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    final opportunityId = message.data['opportunity_id'];
    if (opportunityId != null) {
      // La navegación se manejará mediante el router si es necesario
      // O disparando un evento global que el router escuche
    }
  }
}
