import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../domain/entities/subscription_package.dart';
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
          defaultValue: '', // Set via --dart-define in CI/prod; use .env locally
        );
        if (apiKey.isEmpty) {
          debugPrint('RevenueCat: no API key provided — skipping init (dev build).');
          return const Right(unit);
        }
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

  @override
  Future<Either<SubscriptionFailure, List<SubscriptionPackage>>> getAvailablePackages() async {
    try {
      if (!_isAndroid && !_isIOS) {
        return const Right([
          SubscriptionPackage(
            id: 'mock_yearly',
            identifier: 'yearly',
            title: 'Prism Pro Yearly',
            description: 'Yearly Subscription (best value)',
            priceString: '\$24.99',
            price: 24.99,
            currencyCode: 'USD',
            packageType: 'yearly',
          ),
          SubscriptionPackage(
            id: 'mock_monthly',
            identifier: 'monthly',
            title: 'Prism Pro Monthly',
            description: 'Monthly Subscription',
            priceString: '\$2.99',
            price: 2.99,
            currencyCode: 'USD',
            packageType: 'monthly',
          ),
        ]);
      }

      final offerings = await _clientWrapper.getOfferings();
      final currentOffering = offerings.current;
      if (currentOffering == null) {
        return const Right([]);
      }

      final packages = currentOffering.availablePackages.where((pkg) {
        return pkg.packageType == PackageType.annual || pkg.packageType == PackageType.monthly;
      }).map((pkg) {
        final prod = pkg.storeProduct;
        final type = pkg.packageType == PackageType.annual ? 'yearly' : 'monthly';
        return SubscriptionPackage(
          id: pkg.identifier,
          identifier: prod.identifier,
          title: prod.title,
          description: prod.description,
          priceString: prod.priceString,
          price: prod.price,
          currencyCode: prod.currencyCode,
          packageType: type,
        );
      }).toList();

      return Right(packages);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<SubscriptionFailure, SubscriptionStatus>> purchasePackage(SubscriptionPackage package) async {
    try {
      if (!_isAndroid && !_isIOS) {
        return const Right(SubscriptionStatus(
          isPro: true,
          activeEntitlements: {'Prism Pro'},
        ));
      }

      final offerings = await _clientWrapper.getOfferings();
      final currentOffering = offerings.current;
      if (currentOffering == null) {
        return Left(const StoreFailure('No offerings configured.'));
      }

      final nativePkg = currentOffering.availablePackages.firstWhere(
        (pkg) => pkg.identifier == package.id,
        orElse: () => throw StateError('Package ${package.id} not found in offerings.'),
      );

      final customerInfo = await _clientWrapper.purchasePackage(nativePkg);
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
