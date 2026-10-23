import 'dart:io';

import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../constants/app_constants.dart';

class SubscriptionService {
  static const String _weeklyReportEntitlement = 'vault_pro';
  static bool _initialized = false;

  static bool get _isConfigured => AppConstants.revenueCatApiKey.isNotEmpty;

  static Future<void> init() async {
    if (_initialized || !_isConfigured) {
      return;
    }

    final String apiKey = AppConstants.revenueCatApiKey;
    final PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
    if (Platform.isIOS) {
      configuration.store = Store.appStore;
    }

    await Purchases.configure(configuration);
    _initialized = true;
  }

  static Future<bool> isPro() async {
    if (!_isConfigured) {
      return false;
    }

    await init();
    final CustomerInfo customerInfo = await Purchases.getCustomerInfo();
    return customerInfo.entitlements.active.containsKey(
      _weeklyReportEntitlement,
    );
  }

  static Future<bool> purchase(BuildContext context) async {
    if (!_isConfigured) {
      return false;
    }

    await init();
    final Offerings offerings = await Purchases.getOfferings();
    final Package? package = offerings.current?.availablePackages.firstOrNull;
    if (package == null) {
      return false;
    }

    final PurchaseResult purchaseResult = await Purchases.purchase(
      PurchaseParams.package(package),
    );
    return purchaseResult.customerInfo.entitlements.active.containsKey(
      _weeklyReportEntitlement,
    );
  }

  static Future<void> restorePurchases() async {
    if (!_isConfigured) {
      return;
    }

    await init();
    await Purchases.restorePurchases();
  }
}
