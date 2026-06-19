import 'dart:async';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'revenuecat_client_wrapper.dart';

class DefaultRevenueCatClientWrapper implements RevenueCatClientWrapper {
  late final StreamController<CustomerInfo> _controller;

  DefaultRevenueCatClientWrapper() {
    _controller = StreamController<CustomerInfo>.broadcast(
      onListen: () {
        Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
      },
    );
  }

  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    if (!_controller.isClosed) {
      _controller.add(customerInfo);
    }
  }

  @override
  Stream<CustomerInfo> get customerInfoStream => _controller.stream;

  @override
  Future<void> configure(PurchasesConfiguration configuration) async {
    await Purchases.configure(configuration);
  }

  @override
  Future<void> setLogLevel(LogLevel level) async {
    await Purchases.setLogLevel(level);
  }

  @override
  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  @override
  Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }

  @override
  Future<void> presentPaywall() async {
    await RevenueCatUI.presentPaywall();
  }

  @override
  Future<void> presentPaywallIfNeeded(String entitlement) async {
    await RevenueCatUI.presentPaywallIfNeeded(entitlement);
  }

  @override
  Future<void> presentCustomerCenter() async {
    await RevenueCatUI.presentCustomerCenter();
  }

  @override
  Future<bool> isConfigured() async {
    return await Purchases.isConfigured;
  }

  @override
  Future<Offerings> getOfferings() async {
    return await Purchases.getOfferings();
  }

  @override
  Future<CustomerInfo> purchasePackage(Package package) async {
    final purchaseParams = PurchaseParams.package(package);
    final result = await Purchases.purchase(purchaseParams);
    return result.customerInfo;
  }
}
