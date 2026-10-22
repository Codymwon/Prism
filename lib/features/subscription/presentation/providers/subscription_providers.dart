import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/default_revenuecat_client_wrapper.dart';
import '../../data/repositories/revenuecat_subscription_repository.dart';
import '../../domain/entities/subscription_package.dart';
import '../../domain/entities/subscription_status.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../../../core/config/app_config.dart';

import '../../data/datasources/revenuecat_client_wrapper.dart';

final revenueCatClientWrapperProvider = Provider<RevenueCatClientWrapper>((ref) {
  return DefaultRevenueCatClientWrapper();
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return RevenueCatSubscriptionRepository(
    clientWrapper: ref.watch(revenueCatClientWrapperProvider),
    isAndroid: Platform.isAndroid,
    isIOS: Platform.isIOS,
  );
});

final subscriptionStatusProvider = StreamProvider<SubscriptionStatus>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.subscriptionStatusStream;
});

final isProProvider = Provider<bool>((ref) {
  if (!AppConfig.enableSubscriptions) {
    return false;
  }
  final statusAsync = ref.watch(subscriptionStatusProvider);
  return statusAsync.valueOrNull?.isPro ?? false;
});

final availablePackagesProvider = FutureProvider<List<SubscriptionPackage>>((ref) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  final result = await repository.getAvailablePackages();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (packages) => packages,
  );
});
