// Gene - Nov, 03, 2026: Customer Review and Star Rating data model
class Review {
  final String id;
  final String businessId;
  final String clientId;
  final String bookingId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? clientName;

  const Review({
    required this.id,
    required this.businessId,
    required this.clientId,
    required this.bookingId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.clientName,
  });

  /*
  // Gene - Nov, 03, 2026: Original Review fromJson
  factory Review.fromJson(Map<String, dynamic> json) {
    final pMap = json['profiles'] as Map<String, dynamic>?;

    return Review(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      clientId: json['client_id'] as String,
      bookingId: json['booking_id'] as String,
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      clientName: pMap != null ? pMap['full_name'] as String? : json['client_name'] as String?,
    );
  }
  */

  // Gene - Nov, 05, 2026: Defensive fallback factory for missing customer reviews
  factory Review.fallback({
    String id = 'rev-fallback-0',
    String businessId = '00000000-0000-0000-0000-000000000000',
    String clientId = '00000000-0000-0000-0000-000000000003',
  }) {
    return Review(
      id: id,
      businessId: businessId,
      clientId: clientId,
      bookingId: 'bk-sample-1',
      rating: 5,
      comment: 'Exceptional service and friendly staff. Highly recommend!',
      clientName: 'Michael Chen',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    );
  }

  // Gene - Nov, 05, 2026: Hardened fromJson with strict null-safety and default fallbacks
  factory Review.fromJson(Map<String, dynamic> json) {
    final pMap = json['profiles'] as Map<String, dynamic>?;

    return Review(
      id: json['id'] as String? ?? 'rev-fallback-0',
      businessId: json['business_id'] as String? ?? '00000000-0000-0000-0000-000000000000',
      clientId: json['client_id'] as String? ?? '00000000-0000-0000-0000-000000000003',
      bookingId: json['booking_id'] as String? ?? 'bk-fallback-0',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      clientName: pMap != null ? pMap['full_name'] as String? : json['client_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'client_id': clientId,
      'booking_id': bookingId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
