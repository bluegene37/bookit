// Gene - Nov, 03, 2026: User Profile data model
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'client', 'business_owner', 'admin'
  final String? phone;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
    required this.createdAt,
  });

  /*
  // Gene - Nov, 7, 2026: Overloaded isBusinessOwner to include 'staff', granting billing & settings privileges to clinicians
  bool get isBusinessOwner => role == 'business_owner' || role == 'admin' || role == 'staff';
  */
  // Gene - Nov, 14, 2026: Restore strict owner/admin boundary on isBusinessOwner and introduce canAccessAdminPortal for shared workspace entry
  bool get isBusinessOwner => role == 'business_owner' || role == 'admin';
  bool get isStaff => role == 'staff';
  bool get isAdmin => role == 'admin';
  bool get canAccessAdminPortal => isBusinessOwner || isStaff;

  /*
  // Gene - Nov, 03, 2026: Original UserProfile fromJson
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'User',
      role: json['role'] as String? ?? 'client',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
  */

  // Gene - Nov, 05, 2026: Defensive fallback factory for default user
  factory UserProfile.fallback({
    String id = '00000000-0000-0000-0000-000000000001',
    String email = 'admin@bookit.dev',
    String fullName = 'Dr. Alexander Vance',
    String role = 'business_owner',
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName,
      role: role,
      phone: '+1 (555) 234-5678',
      createdAt: DateTime.now(),
    );
  }

  // Gene - Nov, 05, 2026: Hardened fromJson with strict null-safety and default fallbacks
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '00000000-0000-0000-0000-000000000001',
      email: json['email'] as String? ?? 'client@bookit.dev',
      fullName: json['full_name'] as String? ?? 'Valued User',
      role: json['role'] as String? ?? 'client',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'phone': phone,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
