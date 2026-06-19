import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:prism/features/subscription/data/datasources/revenuecat_client_wrapper.dart';
import 'package:prism/features/subscription/data/repositories/revenuecat_subscription_repository.dart';
import 'package:prism/features/subscription/domain/entities/subscription_package.dart';
import 'package:prism/features/subscription/domain/failures/subscription_failure.dart';

class MockRevenueCatClientWrapper implements RevenueCatClientWrapper {
  bool configureCalled = false;
  PurchasesConfiguration? lastConfiguration;
  LogLevel? lastLogLevel;
  CustomerInfo? mockCustomerInfo;
  bool isConfiguredValue = false;
  PlatformException? exceptionToThrow;
  Offerings? mockOfferings;
  Package? lastPurchasedPackage;
  
  @override
  Future<void> configure(PurchasesConfiguration configuration) async {
    configureCalled = true;
    lastConfiguration = configuration;
    isConfiguredValue = true;
  }

  @override
  Future<void> setLogLevel(LogLevel level) async {
    lastLogLevel = level;
  }

  @override
  Future<CustomerInfo> getCustomerInfo() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (mockCustomerInfo != null) return mockCustomerInfo!;
    throw UnimplementedError();
  }

  @override
  Future<CustomerInfo> restorePurchases() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (mockCustomerInfo != null) return mockCustomerInfo!;
    throw UnimplementedError();
  }

  @override
  Future<void> presentPaywall() async {}

  @override
  Future<void> presentPaywallIfNeeded(String entitlement) async {}

  @override
  Future<void> presentCustomerCenter() async {}

  @override
  Stream<CustomerInfo> get customerInfoStream => const Stream.empty();

  @override
  Future<bool> isConfigured() async => isConfiguredValue;

  @override
  Future<Offerings> getOfferings() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (mockOfferings != null) return mockOfferings!;
    throw UnimplementedError();
  }

  @override
  Future<CustomerInfo> purchasePackage(Package package) async {
    lastPurchasedPackage = package;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (mockCustomerInfo != null) return mockCustomerInfo!;
    throw UnimplementedError();
  }
}

class FakeCustomerInfo extends Fake implements CustomerInfo {
  final Map<String, EntitlementInfo> _mockActiveEntitlements;

  FakeCustomerInfo(this._mockActiveEntitlements);

  @override
  EntitlementInfos get entitlements => FakeEntitlementInfos(_mockActiveEntitlements);
}

class FakeEntitlementInfos extends Fake implements EntitlementInfos {
  @override
  final Map<String, EntitlementInfo> active;

  FakeEntitlementInfos(this.active);
}

class FakeEntitlementInfo extends Fake implements EntitlementInfo {
  @override
  final bool isActive;

  FakeEntitlementInfo(this.isActive);
}

class FakeOfferings extends Fake implements Offerings {
  @override
  final Offering? current;

  FakeOfferings(this.current);
}

class FakeOffering extends Fake implements Offering {
  @override
  final List<Package> availablePackages;

  FakeOffering(this.availablePackages);
}

class FakePackage extends Fake implements Package {
  @override
  final String identifier;
  @override
  final PackageType packageType;
  @override
  final StoreProduct storeProduct;

  FakePackage(this.identifier, this.packageType, this.storeProduct);
}

class FakeStoreProduct extends Fake implements StoreProduct {
  @override
  final String identifier;
  @override
  final String title;
  @override
  final String description;
  @override
  final String priceString;
  @override
  final double price;
  @override
  final String currencyCode;

  FakeStoreProduct({
    required this.identifier,
    required this.title,
    required this.description,
    required this.priceString,
    required this.price,
    required this.currencyCode,
  });
}

void main() {
  late MockRevenueCatClientWrapper mockClient;

  setUp(() {
    mockClient = MockRevenueCatClientWrapper();
  });

  group('RevenueCatSubscriptionRepository - Initialization', () {
    test('should initialize successfully and return Right(unit) on Android', () async {
      // Arrange
      final repository = RevenueCatSubscriptionRepository(
        clientWrapper: mockClient,
        isAndroid: true,
        isIOS: false,
      );

      // Act
      final result = await repository.initialize();

      // Assert
      expect(result.isRight(), true);
      expect(mockClient.configureCalled, true);
      expect(mockClient.lastConfiguration?.apiKey, 'test_pjpoQVKBajKwZqKSYULjGBPnFZO');
    });

    test('should initialize successfully and return Right(unit) on Windows without configuring client', () async {
      // Arrange
      final repository = RevenueCatSubscriptionRepository(
        clientWrapper: mockClient,
        isAndroid: false,
        isIOS: false,
      );

      // Act
      final result = await repository.initialize();

      // Assert
      expect(result.isRight(), true);
      expect(mockClient.configureCalled, false);
    });
  });

  group('RevenueCatSubscriptionRepository - Entitlement Checking', () {
    test('should return isPro = true when Prism Pro entitlement is active', () async {
      // Arrange
      final activeEntitlements = {
        'Prism Pro': FakeEntitlementInfo(true),
      };
      mockClient.mockCustomerInfo = FakeCustomerInfo(activeEntitlements);
      final repository = RevenueCatSubscriptionRepository(
        clientWrapper: mockClient,
        isAndroid: true,
        isIOS: false,
      );

      // Act
      final result = await repository.getLatestStatus();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('should not fail'),
        (status) {
          expect(status.isPro, true);
          expect(status.activeEntitlements.contains('Prism Pro'), true);
        },
      );
    });

    test('should return isPro = false when Prism Pro entitlement is inactive', () async {
      // Arrange
      mockClient.mockCustomerInfo = FakeCustomerInfo(const {});
      final repository = RevenueCatSubscriptionRepository(
        clientWrapper: mockClient,
        isAndroid: true,
        isIOS: false,
      );

      // Act
      final result = await repository.getLatestStatus();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('should not fail'),
        (status) {
          expect(status.isPro, false);
          expect(status.activeEntitlements.isEmpty, true);
        },
      );
    });
  });

  group('RevenueCatSubscriptionRepository - Error Mapping', () {
    test('should map PlatformException with code 1 (purchaseCancelledError) to PurchaseCancelledFailure', () async {
      // Arrange
      mockClient.exceptionToThrow = PlatformException(
        code: '1',
        message: 'User cancelled the purchase flow',
      );
      final repository = RevenueCatSubscriptionRepository(
        clientWrapper: mockClient,
        isAndroid: true,
        isIOS: false,
      );

      // Act
      final result = await repository.getLatestStatus();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<PurchaseCancelledFailure>());
          expect(failure.message, contains('User cancelled'));
        },
        (status) => fail('should fail'),
      );
    });

    test('should map PlatformException with code 10 (networkError) to NetworkFailure', () async {
      // Arrange
      mockClient.exceptionToThrow = PlatformException(
        code: '10',
        message: 'No internet connection',
      );
      final repository = RevenueCatSubscriptionRepository(
        clientWrapper: mockClient,
        isAndroid: true,
        isIOS: false,
      );

      // Act
      final result = await repository.getLatestStatus();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, contains('No internet connection'));
        },
        (status) => fail('should fail'),
      );
    });
  });

  group('RevenueCatSubscriptionRepository - Offerings & Purchasing', () {
    test('should fetch and map available packages (monthly & yearly) on Android', () async {
      // Arrange
      final yearlyProduct = FakeStoreProduct(
        identifier: 'yearly_prod',
        title: 'Prism Pro Yearly',
        description: 'Yearly Subscription',
        priceString: '\$36.00',
        price: 36.0,
        currencyCode: 'USD',
      );
      final monthlyProduct = FakeStoreProduct(
        identifier: 'monthly_prod',
        title: 'Prism Pro Monthly',
        description: 'Monthly Subscription',
        priceString: '\$4.00',
        price: 4.0,
        currencyCode: 'USD',
      );

      final yearlyPackage = FakePackage('yearly_pkg', PackageType.annual, yearlyProduct);
      final monthlyPackage = FakePackage('monthly_pkg', PackageType.monthly, monthlyProduct);

      mockClient.mockOfferings = FakeOfferings(FakeOffering([yearlyPackage, monthlyPackage]));

      final repository = RevenueCatSubscriptionRepository(
        clientWrapper: mockClient,
        isAndroid: true,
        isIOS: false,
      );

      // Act
      final result = await repository.getAvailablePackages();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('should not fail'),
        (packages) {
          expect(packages.length, 2);
          final yearly = packages.firstWhere((p) => p.packageType == 'yearly');
          final monthly = packages.firstWhere((p) => p.packageType == 'monthly');

          expect(yearly.price, 36.0);
          expect(yearly.priceString, '\$36.00');
          expect(monthly.price, 4.0);
          expect(monthly.priceString, '\$4.00');
        },
      );
    });

    test('should return mock packages on Windows without calling client', () async {
      // Arrange
      final repository = RevenueCatSubscriptionRepository(
        clientWrapper: mockClient,
        isAndroid: false,
        isIOS: false,
      );

      // Act
      final result = await repository.getAvailablePackages();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('should not fail'),
        (packages) {
          expect(packages.length, 2);
          final yearly = packages.firstWhere((p) => p.packageType == 'yearly');
          final monthly = packages.firstWhere((p) => p.packageType == 'monthly');

          expect(yearly.price, 36.00);
          expect(monthly.price, 4.00);
        },
      );
    });

    test('should execute purchase on Android by resolving and passing package', () async {
      // Arrange
      final yearlyProduct = FakeStoreProduct(
        identifier: 'yearly_prod',
        title: 'Prism Pro Yearly',
        description: 'Yearly Subscription',
        priceString: '\$36.00',
        price: 36.0,
        currencyCode: 'USD',
      );
      final yearlyPackage = FakePackage('yearly_pkg', PackageType.annual, yearlyProduct);
      mockClient.mockOfferings = FakeOfferings(FakeOffering([yearlyPackage]));
      mockClient.mockCustomerInfo = FakeCustomerInfo({
        'Prism Pro': FakeEntitlementInfo(true),
      });

      final repository = RevenueCatSubscriptionRepository(
        clientWrapper: mockClient,
        isAndroid: true,
        isIOS: false,
      );

      final domainPackage = SubscriptionPackage(
        id: 'yearly_pkg',
        identifier: 'yearly_prod',
        title: 'Prism Pro Yearly',
        description: 'Yearly Subscription',
        priceString: '\$36.00',
        price: 36.0,
        currencyCode: 'USD',
        packageType: 'yearly',
      );

      // Act
      final result = await repository.purchasePackage(domainPackage);

      // Assert
      expect(result.isRight(), true);
      expect(mockClient.lastPurchasedPackage, isNotNull);
      expect(mockClient.lastPurchasedPackage!.identifier, 'yearly_pkg');
      result.fold(
        (failure) => fail('should not fail'),
        (status) {
          expect(status.isPro, true);
        },
      );
    });

    test('should execute mock purchase on Windows returning isPro = true without calling client', () async {
      // Arrange
      final repository = RevenueCatSubscriptionRepository(
        clientWrapper: mockClient,
        isAndroid: false,
        isIOS: false,
      );

      final domainPackage = SubscriptionPackage(
        id: 'mock_yearly',
        identifier: 'yearly',
        title: 'Prism Pro Yearly',
        description: 'Yearly',
        priceString: '\$36.00',
        price: 36.0,
        currencyCode: 'USD',
        packageType: 'yearly',
      );

      // Act
      final result = await repository.purchasePackage(domainPackage);

      // Assert
      expect(result.isRight(), true);
      expect(mockClient.lastPurchasedPackage, isNull);
      result.fold(
        (failure) => fail('should not fail'),
        (status) {
          expect(status.isPro, true);
        },
      );
    });
  });
}
