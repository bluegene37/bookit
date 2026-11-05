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

  // Gene - Nov 06, 2026: Added copyWith, shift matrix, and lunch break schedule helpers
  BusinessStaff copyWith({
    String? id,
    String? businessId,
    String? userId,
    String? name,
    String? specialty,
    String? bio,
    String? avatarUrl,
    Map<String, dynamic>? scheduleOverride,
    bool? isActive,
  }) {
    return BusinessStaff(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      scheduleOverride: scheduleOverride ?? this.scheduleOverride,
      isActive: isActive ?? this.isActive,
    );
  }

  bool isWorkingOn(String weekday) {
    final day = weekday.toLowerCase().trim();
    final cfg = scheduleOverride[day];
    if (cfg is Map<String, dynamic> && cfg.containsKey('is_working')) {
      return cfg['is_working'] as bool? ?? false;
    }
    return day != 'saturday' && day != 'sunday';
  }

  String shiftStart(String weekday) {
    final day = weekday.toLowerCase().trim();
    final cfg = scheduleOverride[day];
    if (cfg is Map<String, dynamic> && cfg['start'] is String) {
      return cfg['start'] as String;
    }
    return '09:00';
  }

  String shiftEnd(String weekday) {
    final day = weekday.toLowerCase().trim();
    final cfg = scheduleOverride[day];
    if (cfg is Map<String, dynamic> && cfg['end'] is String) {
      return cfg['end'] as String;
    }
    return '17:00';
  }

  bool hasBreak(String weekday) {
    final day = weekday.toLowerCase().trim();
    final cfg = scheduleOverride[day];
    if (cfg is Map<String, dynamic> && cfg['has_break'] is bool) {
      return cfg['has_break'] as bool;
    }
    return false;
  }

  String breakStart(String weekday) {
    final day = weekday.toLowerCase().trim();
    final cfg = scheduleOverride[day];
    if (cfg is Map<String, dynamic> && cfg['break_start'] is String) {
      return cfg['break_start'] as String;
    }
    return '12:00';
  }

  String breakEnd(String weekday) {
    final day = weekday.toLowerCase().trim();
    final cfg = scheduleOverride[day];
    if (cfg is Map<String, dynamic> && cfg['break_end'] is String) {
      return cfg['break_end'] as String;
    }
    return '13:00';
  }

  String get shiftSummary {
    int workingDays = 0;
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    for (final d in days) {
      if (isWorkingOn(d)) workingDays++;
    }
    if (workingDays == 0) return 'No active shifts';
    if (workingDays == 5 && !isWorkingOn('saturday') && !isWorkingOn('sunday')) {
      final start = shiftStart('monday');
      final end = shiftEnd('monday');
      final bText = hasBreak('monday') ? ' (Break: ${breakStart('monday')}-${breakEnd('monday')})' : '';
      return 'Mon–Fri: $start–$end$bText';
    }
    return '$workingDays days/week active';
  }

  static Map<String, dynamic> defaultSchedule() {
    return {
      'monday': {'is_working': true, 'start': '09:00', 'end': '17:00', 'has_break': true, 'break_start': '12:00', 'break_end': '13:00'},
      'tuesday': {'is_working': true, 'start': '09:00', 'end': '17:00', 'has_break': true, 'break_start': '12:00', 'break_end': '13:00'},
      'wednesday': {'is_working': true, 'start': '09:00', 'end': '17:00', 'has_break': true, 'break_start': '12:00', 'break_end': '13:00'},
      'thursday': {'is_working': true, 'start': '09:00', 'end': '17:00', 'has_break': true, 'break_start': '12:00', 'break_end': '13:00'},
      'friday': {'is_working': true, 'start': '09:00', 'end': '17:00', 'has_break': true, 'break_start': '12:00', 'break_end': '13:00'},
      'saturday': {'is_working': false, 'start': '10:00', 'end': '15:00', 'has_break': false, 'break_start': '12:00', 'break_end': '13:00'},
      'sunday': {'is_working': false, 'start': '10:00', 'end': '15:00', 'has_break': false, 'break_start': '12:00', 'break_end': '13:00'},
    };
  }
}
