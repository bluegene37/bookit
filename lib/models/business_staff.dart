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
