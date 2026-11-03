// Gene - Nov, 03, 2026: Service item model for dental and medical procedures or packages
class ServiceItem {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final int durationMinutes;
  final double price;
  final String currency;
  final bool isActive;

  const ServiceItem({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    this.durationMinutes = 30,
    required this.price,
    this.currency = 'USD',
    this.isActive = true,
  });

  String get formattedPrice => '\$$price';
  String get formattedDuration => '$durationMinutes min';

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'description': description,
      'duration_minutes': durationMinutes,
      'price': price,
      'currency': currency,
      'is_active': isActive,
    };
  }
}
