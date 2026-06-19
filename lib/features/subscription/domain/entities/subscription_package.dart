class SubscriptionPackage {
  final String id;
  final String identifier;
  final String title;
  final String description;
  final String priceString;
  final double price;
  final String currencyCode;
  final String packageType; // 'monthly' or 'yearly'

  const SubscriptionPackage({
    required this.id,
    required this.identifier,
    required this.title,
    required this.description,
    required this.priceString,
    required this.price,
    required this.currencyCode,
    required this.packageType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPackage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          identifier == other.identifier &&
          title == other.title &&
          description == other.description &&
          priceString == other.priceString &&
          price == other.price &&
          currencyCode == other.currencyCode &&
          packageType == other.packageType;

  @override
  int get hashCode =>
      id.hashCode ^
      identifier.hashCode ^
      title.hashCode ^
      description.hashCode ^
      priceString.hashCode ^
      price.hashCode ^
      currencyCode.hashCode ^
      packageType.hashCode;

  @override
  String toString() =>
      'SubscriptionPackage(id: $id, identifier: $identifier, title: $title, priceString: $priceString, packageType: $packageType)';
}
