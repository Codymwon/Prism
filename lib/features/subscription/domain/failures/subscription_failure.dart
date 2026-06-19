sealed class SubscriptionFailure {
  final String message;
  const SubscriptionFailure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends SubscriptionFailure {
  const NetworkFailure(super.message);
}

class PurchaseCancelledFailure extends SubscriptionFailure {
  const PurchaseCancelledFailure(super.message);
}

class StoreFailure extends SubscriptionFailure {
  const StoreFailure(super.message);
}

class PlatformNotSupportedFailure extends SubscriptionFailure {
  const PlatformNotSupportedFailure(super.message);
}

class UnknownSubscriptionFailure extends SubscriptionFailure {
  const UnknownSubscriptionFailure(super.message);
}
