import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/default_revenuecat_client_wrapper.dart';
import '../../data/repositories/revenuecat_subscription_repository.dart';
import '../../domain/entities/subscription_status.dart';
import '../../domain/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return RevenueCatSubscriptionRepository(
    clientWrapper: DefaultRevenueCatClientWrapper(),
    isAndroid: Platform.isAndroid,
    isIOS: Platform.isIOS,
  );
});

final subscriptionStatusProvider = StreamProvider<SubscriptionStatus>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.subscriptionStatusStream;
});

final isProProvider = Provider<bool>((ref) {
  final statusAsync = ref.watch(subscriptionStatusProvider);
  return statusAsync.valueOrNull?.isPro ?? false;
});
