import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:tiktok_business_sdk/tiktok_business_sdk.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'dart:io';

class AnalyticsService {
  static final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();
  // static final TiktokBusinessSdk _tiktokBusinessSdk = TiktokBusinessSdk();

  static Future<void> initialize() async {
    // 1. Request App Tracking Transparency (ATT) for iOS
    if (Platform.isIOS) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }

    // 2. Initialize TikTok (Requires TikTok App ID from Events Manager)
    /*
    try {
      await _tiktokBusinessSdk.initialize(
        'YOUR_TIKTOK_APP_ID', 
      );
    } catch (e) {
      debugPrint('TikTok SDK initialization error: $e');
    }
    */
    
    // Facebook is initialized automatically via native config.
    await _facebookAppEvents.logEvent(name: 'app_initialized');
  }

  // Evento: Registro de usuario completo
  static Future<void> logRegistration(String method) async {
    await _facebookAppEvents.logCompletedRegistration(registrationMethod: method);
    // TikTok Registration
    // await _tiktokBusinessSdk.logEvent('CompleteRegistration');
  }

  // Evento: Visualización de Paywall
  static Future<void> logViewPaywall() async {
    await _facebookAppEvents.logEvent(
      name: 'view_paywall',
      parameters: {'content_type': 'subscription_page'},
    );
    // TikTok Event
    // await _tiktokBusinessSdk.logEvent('ViewContent');
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
    // TikTok Checkout
    // await _tiktokBusinessSdk.logEvent('InitiateCheckout');
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
    // await _tiktokBusinessSdk.logEvent('Subscribe');
  }

  // Evento personalizado: Oportunidad vista
  static Future<void> logOpportunityView(String category) async {
    await _facebookAppEvents.logEvent(
      name: 'view_opportunity',
      parameters: {'category': category},
    );
  }
}
