// Gene - Nov, 03, 2026: In-app Notification item data model
class NotificationItem {
  final String id;
  final String userId;
  final String? businessId;
  final String? bookingId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.userId,
    this.businessId,
    this.bookingId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessId: json['business_id'] as String?,
      bookingId: json['booking_id'] as String?,
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'info',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_id': businessId,
      'booking_id': bookingId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
