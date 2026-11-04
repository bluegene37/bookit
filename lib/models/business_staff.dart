// Gene - Nov, 03, 2026: Business Staff / Doctor / Practitioner data model
class BusinessStaff {
  final String id;
  final String businessId;
  final String? userId;
  final String name;
  final String? specialty;
  final String? bio;
  final String? avatarUrl;
  final Map<String, dynamic> scheduleOverride;
  final bool isActive;

  const BusinessStaff({
    required this.id,
    required this.businessId,
    this.userId,
    required this.name,
    this.specialty,
    this.bio,
    this.avatarUrl,
    this.scheduleOverride = const {},
    this.isActive = true,
  });

  /*
  // Gene - Nov, 03, 2026: Original fromJson
  factory BusinessStaff.fromJson(Map<String, dynamic> json) {
    return BusinessStaff(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      specialty: json['specialty'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      scheduleOverride: json['schedule_override'] as Map<String, dynamic>? ?? {},
      isActive: json['is_active'] as bool? ?? true,
    );
  }
  */

  // Gene - Nov, 05, 2026: Defensive fallback factory for missing staff records
  factory BusinessStaff.fallback({
    String id = 'staff-fallback-0',
    String businessId = '00000000-0000-0000-0000-000000000000',
    String name = 'Available Specialist',
  }) {
    return BusinessStaff(
      id: id,
      businessId: businessId,
      name: name,
      specialty: 'Lead Practitioner',
      bio: 'Experienced licensed specialist providing attentive care and guidance.',
      avatarUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=400&q=80',
      isActive: true,
    );
  }

  // Gene - Nov, 05, 2026: Hardened fromJson with strict null-safety and default fallbacks
  factory BusinessStaff.fromJson(Map<String, dynamic> json) {
    return BusinessStaff(
      id: json['id'] as String? ?? 'staff-fallback-0',
      businessId: json['business_id'] as String? ?? '00000000-0000-0000-0000-000000000000',
      userId: json['user_id'] as String?,
      name: json['name'] as String? ?? 'Available Specialist',
      specialty: json['specialty'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      scheduleOverride: json['schedule_override'] as Map<String, dynamic>? ?? {},
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'user_id': userId,
      'name': name,
      'specialty': specialty,
      'bio': bio,
      'avatar_url': avatarUrl,
      'schedule_override': scheduleOverride,
      'is_active': isActive,
    };
  }
}
