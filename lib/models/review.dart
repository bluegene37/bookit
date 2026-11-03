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
