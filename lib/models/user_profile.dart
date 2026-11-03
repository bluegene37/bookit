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

  bool get isBusinessOwner => role == 'business_owner' || role == 'admin';
  bool get isAdmin => role == 'admin';

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
