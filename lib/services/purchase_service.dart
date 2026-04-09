import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PurchaseService {
  static const _apiKey = 'appl_WwGMdqpfmKRrzBJIZhvvTgoYDWr';
  
  // The Entitlement ID should match what you configured in RevenueCat dashboard
  static const entitlementId = 'pro'; 

  static Future<void> initialize() async {
    if (kIsWeb) return; // RevenueCat not used on Web in this setup

    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (Platform.isIOS || Platform.isMacOS) {
      configuration = PurchasesConfiguration(_apiKey);
    } else if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKey);
    } else {
      return;
    }

    await Purchases.configure(configuration);
  }

  static Future<CustomerInfo?> getCustomerInfo() async {
    if (kIsWeb) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      return null;
    }
  }

  static Future<Offerings?> getOfferings() async {
    if (kIsWeb) return null;
    try {
      return await Purchases.getOfferings();
    } on PlatformException {
      return null;
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    if (kIsWeb) return false;
    try {
      PurchaseResult result = await Purchases.purchasePackage(package);
      return result.customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        // Handle other errors
      }
      return false;
    }
  }

  static Future<void> launchStripeCheckout(String checkoutUrl) async {
    final uri = Uri.parse(checkoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<bool> restorePurchases() async {
    if (kIsWeb) return false;
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> isPremium() async {
    if (kIsWeb) {
      // On web, we check the database directly since RevenueCat is skipped
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('plan')
          .eq('id', user.id)
          .single();
      
      final plan = response['plan'] as String?;
      return plan == 'pro' || plan == 'plus' || plan == 'trader_plus';
    }

    CustomerInfo? customerInfo = await getCustomerInfo();
    if (customerInfo == null) return false;
    return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
  }
}
