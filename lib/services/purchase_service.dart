import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  static const _apiKey = 'appl_WwGMdqpfmKRrzBJIZhvvTgoYDWr';
  
  // The Entitlement ID should match what you configured in RevenueCat dashboard
  static const entitlementId = 'pro'; 

  static Future<void> initialize() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (Platform.isIOS || Platform.isMacOS) {
      configuration = PurchasesConfiguration(_apiKey);
    } else if (Platform.isAndroid) {
      // Assuming same key or user will provide android key later
      // For now using the same since usually they are separate but let's stick to the provided one
      configuration = PurchasesConfiguration(_apiKey);
    } else {
      return;
    }

    await Purchases.configure(configuration);
  }

  static Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      return null;
    }
  }

  static Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } on PlatformException {
      return null;
    }
  }

  static Future<bool> purchasePackage(Package package) async {
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

  static Future<bool> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> isPremium() async {
    CustomerInfo? customerInfo = await getCustomerInfo();
    if (customerInfo == null) return false;
    return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
  }
}
