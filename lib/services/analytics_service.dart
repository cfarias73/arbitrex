import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:tiktok_sdk/tiktok_sdk.dart';
import 'dart:io';

class AnalyticsService {
  static final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();

  static Future<void> initialize() async {
    // Inicialización de TikTok (requiere App ID)
    // Nota: Sustituir 'YOUR_TIKTOK_APP_ID' con el ID real de TikTok For Business
    await TikTokSDK.instance.setup(
      androidAppId: 'YOUR_TIKTOK_APP_ID',
      iosAppId: 'YOUR_TIKTOK_APP_ID',
    );
    
    // Facebook se inicializa automáticamente si el Info.plist/AndroidManifest está correcto,
    // pero podemos forzar el log de inicio.
    await _facebookAppEvents.logEvent(name: 'app_initialized');
  }

  // Evento: Registro de usuario completo
  static Future<void> logRegistration(String method) async {
    await _facebookAppEvents.logCompletedRegistration(registrationMethod: method);
    // TikTok: No tiene un método específico de registro directo en el plugin básico, 
    // se suele usar logEvent personalizado si es necesario.
  }

  // Evento: Visualización de Paywall
  static Future<void> logViewPaywall() async {
    await _facebookAppEvents.logEvent(
      name: 'view_paywall',
      parameters: {'content_type': 'subscription_page'},
    );
  }

  // Evento: Suscripción iniciada (Checkout)
  static Future<void> logInitiateCheckout(String planName, double price) async {
    await _facebookAppEvents.logEvent(
      name: 'initiate_checkout',
      parameters: {
        'plan_name': planName,
        'value': price,
        'currency': 'USD',
      },
    );
  }

  // Evento: Suscripción Completada (Compra)
  static Future<void> logPurchase(double amount, String currency, String planName) async {
    // Facebook tracking
    await _facebookAppEvents.logPurchase(
      amount: amount,
      currency: currency,
      parameters: {'plan_name': planName},
    );
    
    // TikTok tracking
    // Nota: TikTok SDK en Flutter es limitado, pero suele trackear eventos automáticos.
  }

  // Evento personalizado: Oportunidad vista
  static Future<void> logOpportunityView(String category) async {
    await _facebookAppEvents.logEvent(
      name: 'view_opportunity',
      parameters: {'category': category},
    );
  }
}
