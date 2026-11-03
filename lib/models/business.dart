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
  });

  int get slotIntervalMinutes => (settings['slot_interval_minutes'] as num?)?.toInt() ?? 30;
  int get bufferMinutes => (settings['buffer_minutes'] as num?)?.toInt() ?? 10;
  bool get requiresApproval => (settings['requires_approval'] as bool?) ?? false;

  Map<String, dynamic>? get workingHours => settings['working_hours'] as Map<String, dynamic>?;

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
      settings: json['settings'] as Map<String, dynamic>? ?? {},
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

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
    };
  }
}
