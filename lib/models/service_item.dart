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

  // Gene - Nov, 04, 2026: Added deposit policy and calculation properties
  final String paymentPolicy; // 'full_upfront', 'deposit', 'pay_at_venue'
  final String depositType; // 'percentage', 'fixed'
  final double depositAmount;

  /*
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
  */

  // Gene - Nov, 04, 2026: Updated constructor with deposit and payment policy fields
  const ServiceItem({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    this.durationMinutes = 30,
    required this.price,
    this.currency = 'USD',
    this.isActive = true,
    this.paymentPolicy = 'full_upfront',
    this.depositType = 'percentage',
    this.depositAmount = 20.00,
  });

  String get formattedPrice => '\$$price';
  String get formattedDuration => '$durationMinutes min';

  // Gene - Nov, 04, 2026: Calculate deposit required based on service payment policy
  double calculateDepositAmount() {
    if (paymentPolicy == 'full_upfront') return price;
    if (paymentPolicy == 'pay_at_venue') return 0.0;
    if (depositType == 'percentage') {
      return double.parse((price * (depositAmount / 100)).toStringAsFixed(2));
    }
    return depositAmount > price ? price : depositAmount;
  }

  /*
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
  */

  // Gene - Nov, 04, 2026: Updated fromJson parsing payment policy and deposit settings
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
      paymentPolicy: json['payment_policy'] as String? ?? 'full_upfront',
      depositType: json['deposit_type'] as String? ?? 'percentage',
      depositAmount: (json['deposit_amount'] as num?)?.toDouble() ?? 20.00,
    );
  }

  /*
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
  */

  // Gene - Nov, 04, 2026: Updated toJson serializing payment policy and deposit fields
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
      'payment_policy': paymentPolicy,
      'deposit_type': depositType,
      'deposit_amount': depositAmount,
    };
  }
}
