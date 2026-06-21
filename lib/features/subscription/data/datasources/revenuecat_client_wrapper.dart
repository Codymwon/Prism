import 'package:purchases_flutter/purchases_flutter.dart';

abstract class RevenueCatClientWrapper {
  Future<void> setLogLevel(LogLevel level);
  Future<void> configure(PurchasesConfiguration configuration);
  Future<CustomerInfo> getCustomerInfo();
  Future<CustomerInfo> restorePurchases();
  Future<void> presentPaywall();
  Future<void> presentPaywallIfNeeded(String entitlement);
  Future<void> presentCustomerCenter();
  Stream<CustomerInfo> get customerInfoStream;
  Future<bool> isConfigured();
  Future<Offerings> getOfferings();
  Future<CustomerInfo> purchasePackage(Package package);
  Future<LogInResult> logIn(String appUserId);
  Future<CustomerInfo> logOut();
}

