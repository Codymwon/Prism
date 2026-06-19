import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../domain/entities/subscription_status.dart';
import '../../domain/failures/subscription_failure.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/revenuecat_client_wrapper.dart';

class RevenueCatSubscriptionRepository implements SubscriptionRepository {
  final RevenueCatClientWrapper _clientWrapper;
  final bool _isAndroid;
  final bool _isIOS;

  RevenueCatSubscriptionRepository({
    required RevenueCatClientWrapper clientWrapper,
    required bool isAndroid,
    required bool isIOS,
  })  : _clientWrapper = clientWrapper,
        _isAndroid = isAndroid,
        _isIOS = isIOS;

  SubscriptionFailure _mapException(Object e) {
    if (e is PlatformException) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      switch (errorCode) {
        case PurchasesErrorCode.purchaseCancelledError:
          return PurchaseCancelledFailure(e.message ?? 'Purchase was cancelled');
        case PurchasesErrorCode.networkError:
          return NetworkFailure(e.message ?? 'Network connection issue');
        case PurchasesErrorCode.storeProblemError:
        case PurchasesErrorCode.purchaseNotAllowedError:
        case PurchasesErrorCode.paymentPendingError:
          return StoreFailure(e.message ?? 'Store problem or payment pending: $errorCode');
        default:
          return UnknownSubscriptionFailure(e.message ?? 'Unknown store error: $errorCode');
      }
    }
    return UnknownSubscriptionFailure(e.toString());
  }

  @override
  Stream<SubscriptionStatus> get subscriptionStatusStream {
    if (!_isAndroid && !_isIOS) {
      return Stream.value(const SubscriptionStatus.free());
    }
    return _clientWrapper.customerInfoStream.map((customerInfo) {
      final entitlements = customerInfo.entitlements.active.keys.toSet();
      final isPro = customerInfo.entitlements.active.containsKey('Prism Pro') &&
          customerInfo.entitlements.active['Prism Pro']?.isActive == true;
      return SubscriptionStatus(
        isPro: isPro,
        activeEntitlements: entitlements,
      );
    });
  }

  @override
  Future<Either<SubscriptionFailure, Unit>> initialize() async {
    try {
      if (_isAndroid || _isIOS) {
        const apiKey = String.fromEnvironment(
          'REVENUECAT_API_KEY',
          defaultValue: 'test_pjpoQVKBajKwZqKSYULjGBPnFZO',
        );
        final config = PurchasesConfiguration(apiKey);
        await _clientWrapper.configure(config);
      }
      return const Right(unit);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<SubscriptionFailure, SubscriptionStatus>> getLatestStatus() async {
    try {
      if (!_isAndroid && !_isIOS) {
        return const Right(SubscriptionStatus.free());
      }
      final customerInfo = await _clientWrapper.getCustomerInfo();
      final entitlements = customerInfo.entitlements.active.keys.toSet();
      final isPro = customerInfo.entitlements.active.containsKey('Prism Pro') &&
          customerInfo.entitlements.active['Prism Pro']?.isActive == true;

      return Right(SubscriptionStatus(
        isPro: isPro,
        activeEntitlements: entitlements,
      ));
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<SubscriptionFailure, Unit>> presentPaywall() async {
    try {
      if (!_isAndroid && !_isIOS) {
        return Left(const PlatformNotSupportedFailure('Subscriptions are not supported on this platform.'));
      }
      await _clientWrapper.presentPaywall();
      return const Right(unit);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<SubscriptionFailure, Unit>> presentPaywallIfNeeded() async {
    try {
      if (!_isAndroid && !_isIOS) {
        return Left(const PlatformNotSupportedFailure('Subscriptions are not supported on this platform.'));
      }
      await _clientWrapper.presentPaywallIfNeeded('Prism Pro');
      return const Right(unit);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<SubscriptionFailure, Unit>> presentCustomerCenter() async {
    try {
      if (!_isAndroid && !_isIOS) {
        return Left(const PlatformNotSupportedFailure('Subscriptions are not supported on this platform.'));
      }
      await _clientWrapper.presentCustomerCenter();
      return const Right(unit);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<SubscriptionFailure, SubscriptionStatus>> restorePurchases() async {
    try {
      if (!_isAndroid && !_isIOS) {
        return Left(const PlatformNotSupportedFailure('Subscriptions are not supported on this platform.'));
      }
      final customerInfo = await _clientWrapper.restorePurchases();
      final entitlements = customerInfo.entitlements.active.keys.toSet();
      final isPro = customerInfo.entitlements.active.containsKey('Prism Pro') &&
          customerInfo.entitlements.active['Prism Pro']?.isActive == true;

      return Right(SubscriptionStatus(
        isPro: isPro,
        activeEntitlements: entitlements,
      ));
    } catch (e) {
      return Left(_mapException(e));
    }
  }
}
