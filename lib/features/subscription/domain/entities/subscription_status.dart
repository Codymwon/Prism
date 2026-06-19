import 'package:collection/collection.dart';

class SubscriptionStatus {
  final bool isPro;
  final DateTime? expirationDate;
  final Set<String> activeEntitlements;

  const SubscriptionStatus({
    required this.isPro,
    this.expirationDate,
    required this.activeEntitlements,
  });

  const SubscriptionStatus.free()
      : isPro = false,
        expirationDate = null,
        activeEntitlements = const {};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionStatus &&
          runtimeType == other.runtimeType &&
          isPro == other.isPro &&
          expirationDate == other.expirationDate &&
          const SetEquality().equals(activeEntitlements, other.activeEntitlements);

  @override
  int get hashCode =>
      isPro.hashCode ^ expirationDate.hashCode ^ const SetEquality().hash(activeEntitlements);

  @override
  String toString() =>
      'SubscriptionStatus(isPro: $isPro, expirationDate: $expirationDate, activeEntitlements: $activeEntitlements)';
}
