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

  /*
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
  */

  // Gene - Nov, 05, 2026: Defensive fallback factory for missing service items
  factory ServiceItem.fallback({
    String id = 'srv-fallback-0',
    String businessId = '00000000-0000-0000-0000-000000000000',
    String name = 'Standard Consultation',
    double price = 50.0,
  }) {
    return ServiceItem(
      id: id,
      businessId: businessId,
      name: name,
      description: 'Standard session and clinical consultation.',
      durationMinutes: 30,
      price: price,
      currency: 'USD',
      isActive: true,
      paymentPolicy: 'pay_at_venue',
      depositType: 'percentage',
      depositAmount: 0.0,
    );
  }

  // Gene - Nov, 05, 2026: Hardened fromJson with strict null-safety and default fallbacks
  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as String? ?? 'srv-fallback-0',
      businessId: json['business_id'] as String? ?? '00000000-0000-0000-0000-000000000000',
      name: json['name'] as String? ?? 'Standard Consultation',
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

  // Gene - Nov 07, 2026: Added copyWith to support editing procedure details, payment policies, and active/archive toggles
  ServiceItem copyWith({
    String? id,
    String? businessId,
    String? name,
    String? description,
    int? durationMinutes,
    double? price,
    String? currency,
    bool? isActive,
    String? paymentPolicy,
    String? depositType,
    double? depositAmount,
  }) {
    return ServiceItem(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      paymentPolicy: paymentPolicy ?? this.paymentPolicy,
      depositType: depositType ?? this.depositType,
      depositAmount: depositAmount ?? this.depositAmount,
    );
  }

  // Gene - Nov, 7, 2026: Override equality and hashCode by service id for consistent selection state across rebuilds
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
