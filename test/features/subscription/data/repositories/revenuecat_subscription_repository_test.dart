import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:prism/features/subscription/data/datasources/revenuecat_client_wrapper.dart';
import 'package:prism/features/subscription/data/repositories/revenuecat_subscription_repository.dart';
import 'package:prism/features/subscription/domain/failures/subscription_failure.dart';

class MockRevenueCatClientWrapper implements RevenueCatClientWrapper {
  bool configureCalled = false;
  PurchasesConfiguration? lastConfiguration;
  LogLevel? lastLogLevel;
  CustomerInfo? mockCustomerInfo;
  bool isConfiguredValue = false;
  PlatformException? exceptionToThrow;
  
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
      // In purchases_flutter, the cancelled error index is 1. PurchasesErrorHelper maps code '1' to purchaseCancelledError.
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
}
