// Gene - Nov, 03, 2026: Business model supporting polymorphic booking models (slot_based, date_range, daily)

enum BookingModelType {
  slotBased,
  dateRange,
  daily;

  static BookingModelType fromString(String value) {
    switch (value) {
      case 'date_range':
        return BookingModelType.dateRange;
      case 'daily':
        return BookingModelType.daily;
      case 'slot_based':
      default:
        return BookingModelType.slotBased;
    }
  }

  String toDbString() {
    switch (this) {
      case BookingModelType.slotBased:
        return 'slot_based';
      case BookingModelType.dateRange:
        return 'date_range';
      case BookingModelType.daily:
        return 'daily';
    }
  }

  String get displayName {
    switch (this) {
      case BookingModelType.slotBased:
        return 'Time Slot Appointment (Clinic/Doctor)';
      case BookingModelType.dateRange:
        return 'Date Range (Stay / Rental / Multi-day)';
      case BookingModelType.daily:
        return 'Daily Session (Day Clinic / Pass)';
    }
  }
}

class Business {
  final String id;
  final String ownerId;
  final String name;
  final String slug;
  final String category;
  final BookingModelType bookingModel;
  final String? description;
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? contactPhone;
  final String? contactEmail;
  final String? bannerUrl;
  final String? logoUrl;
  final Map<String, dynamic> settings;
  final double ratingAvg;
  final int ratingCount;
  final bool isActive;

  // Gene - Nov, 04, 2026: Stripe Connect and platform fee attributes
  final String? stripeAccountId;
  final bool stripeChargesEnabled;
  final double platformFeePercent;
  final double platformFeeFixed;

  // Gene - Nov, 04, 2026: Template association and modular dynamic booking UI configuration
  final String? templateId;
  final Map<String, dynamic> uiConfig;

  /*
  // Gene - Nov, 04, 2026: Previous constructor without templateId & uiConfig
  const Business({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.slug,
    required this.category,
    required this.bookingModel,
    this.description,
    this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.contactPhone,
    this.contactEmail,
    this.bannerUrl,
    this.logoUrl,
    this.settings = const {},
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.isActive = true,
    this.stripeAccountId,
    this.stripeChargesEnabled = false,
    this.platformFeePercent = 2.50,
    this.platformFeeFixed = 0.30,
  });
  */

  // Gene - Nov, 04, 2026: Updated constructor supporting template inheritance and uiConfig
  const Business({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.slug,
    required this.category,
    required this.bookingModel,
    this.description,
    this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.contactPhone,
    this.contactEmail,
    this.bannerUrl,
    this.logoUrl,
    this.settings = const {},
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.isActive = true,
    this.stripeAccountId,
    this.stripeChargesEnabled = false,
    this.platformFeePercent = 2.50,
    this.platformFeeFixed = 0.30,
    this.templateId,
    this.uiConfig = const {},
  });

  int get slotIntervalMinutes => (settings['slot_interval_minutes'] as num?)?.toInt() ?? 30;
  int get bufferMinutes => (settings['buffer_minutes'] as num?)?.toInt() ?? 10;
  bool get requiresApproval => (settings['requires_approval'] as bool?) ?? false;

  Map<String, dynamic>? get workingHours => settings['working_hours'] as Map<String, dynamic>?;

  // Gene - Nov, 04, 2026: Modular UI and resource dynamic helpers for universal booking engine
  String get resourceType => (uiConfig['resource_type'] as String?) ?? 'person';
  String get resourceLabel => (uiConfig['resource_label'] as String?) ?? 'Specialist';
  String get serviceLabel => (uiConfig['service_label'] as String?) ?? 'Service';
  bool get showStaffSelection => (uiConfig['show_staff_selection'] as bool?) ?? true;
  List<Map<String, dynamic>> get intakeFields {
    final fields = uiConfig['intake_fields'];
    if (fields is List) {
      return fields.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  /*
  // Gene - Nov, 04, 2026: Previous fromJson without templateId & uiConfig
  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      category: json['category'] as String,
      bookingModel: BookingModelType.fromString(json['booking_model'] as String? ?? 'slot_based'),
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      bannerUrl: json['banner_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      settings: json['settings'] != null
          ? Map<String, dynamic>.from(json['settings'] as Map)
          : const {},
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      stripeAccountId: json['stripe_account_id'] as String?,
      stripeChargesEnabled: json['stripe_charges_enabled'] as bool? ?? false,
      platformFeePercent: (json['platform_fee_percent'] as num?)?.toDouble() ?? 2.50,
      platformFeeFixed: (json['platform_fee_fixed'] as num?)?.toDouble() ?? 0.30,
    );
  }
  */

  // Gene - Nov, 04, 2026: Updated fromJson parsing template_id and ui_config snapshot
  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      category: json['category'] as String,
      bookingModel: BookingModelType.fromString(json['booking_model'] as String? ?? 'slot_based'),
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      bannerUrl: json['banner_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      settings: json['settings'] != null
          ? Map<String, dynamic>.from(json['settings'] as Map)
          : const {},
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      stripeAccountId: json['stripe_account_id'] as String?,
      stripeChargesEnabled: json['stripe_charges_enabled'] as bool? ?? false,
      platformFeePercent: (json['platform_fee_percent'] as num?)?.toDouble() ?? 2.50,
      platformFeeFixed: (json['platform_fee_fixed'] as num?)?.toDouble() ?? 0.30,
      templateId: json['template_id'] as String?,
      uiConfig: json['ui_config'] != null
          ? Map<String, dynamic>.from(json['ui_config'] as Map)
          : const {},
    );
  }

  /*
  // Gene - Nov, 04, 2026: Previous toJson without template_id & ui_config
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'slug': slug,
      'category': category,
      'booking_model': bookingModel.toDbString(),
      'description': description,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'banner_url': bannerUrl,
      'logo_url': logoUrl,
      'settings': settings,
      'rating_avg': ratingAvg,
      'rating_count': ratingCount,
      'is_active': isActive,
      'stripe_account_id': stripeAccountId,
      'stripe_charges_enabled': stripeChargesEnabled,
      'platform_fee_percent': platformFeePercent,
      'platform_fee_fixed': platformFeeFixed,
    };
  }
  */

  // Gene - Nov, 04, 2026: Updated toJson serializing template_id and ui_config snapshot
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'slug': slug,
      'category': category,
      'booking_model': bookingModel.toDbString(),
      'description': description,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'banner_url': bannerUrl,
      'logo_url': logoUrl,
      'settings': settings,
      'rating_avg': ratingAvg,
      'rating_count': ratingCount,
      'is_active': isActive,
      'stripe_account_id': stripeAccountId,
      'stripe_charges_enabled': stripeChargesEnabled,
      'platform_fee_percent': platformFeePercent,
      'platform_fee_fixed': platformFeeFixed,
      'template_id': templateId,
      'ui_config': uiConfig,
    };
  }
}
