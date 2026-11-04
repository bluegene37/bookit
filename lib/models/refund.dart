// Gene - Nov, 04, 2026: Refund record model representing full or partial Stripe refunds
class Refund {
  final String id;
  final String paymentId;
  final String bookingId;
  final String? stripeRefundId;
  final double amount;
  final String? reason;
  final String status;
  final String? createdBy;
  final DateTime createdAt;

  const Refund({
    required this.id,
    required this.paymentId,
    required this.bookingId,
    this.stripeRefundId,
    required this.amount,
    this.reason,
    this.status = 'succeeded',
    this.createdBy,
    required this.createdAt,
  });

  factory Refund.fromJson(Map<String, dynamic> json) {
    return Refund(
      id: json['id'] as String,
      paymentId: json['payment_id'] as String,
      bookingId: json['booking_id'] as String,
      stripeRefundId: json['stripe_refund_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'succeeded',
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_id': paymentId,
      'booking_id': bookingId,
      'stripe_refund_id': stripeRefundId,
      'amount': amount,
      'reason': reason,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
