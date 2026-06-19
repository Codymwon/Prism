import 'package:fpdart/fpdart.dart';
import '../entities/subscription_status.dart';
import '../failures/subscription_failure.dart';

abstract class SubscriptionRepository {
  /// Stream of active subscription state changes
  Stream<SubscriptionStatus> get subscriptionStatusStream;

  /// Initializes the subscription SDK
  Future<Either<SubscriptionFailure, Unit>> initialize();

  /// Gets the current subscription status
  Future<Either<SubscriptionFailure, SubscriptionStatus>> getLatestStatus();

  /// Launches the pre-built paywall to upgrade
  Future<Either<SubscriptionFailure, Unit>> presentPaywall();

  /// Launches the pre-built paywall if the user does not have the "Prism Pro" entitlement
  Future<Either<SubscriptionFailure, Unit>> presentPaywallIfNeeded();

  /// Launches the Customer Center to manage subscriptions or request refunds
  Future<Either<SubscriptionFailure, Unit>> presentCustomerCenter();

  /// Restores previous purchases
  Future<Either<SubscriptionFailure, SubscriptionStatus>> restorePurchases();
}
