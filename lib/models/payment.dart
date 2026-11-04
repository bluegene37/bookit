// Gene - Nov, 04, 2026: Payment record model representing Stripe Connect transactions
class Payment {
  final String id;
  final String bookingId;
  final String businessId;
  final String clientId;
  final String? stripeSessionId;
  final String? stripePaymentIntentId;
  final double grossAmount;
  final double applicationFeeAmount;
  final double stripeFeeAmount;
  final double netAmount;
  final String currency;
  final String paymentStatus;
  final String? receiptUrl;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.bookingId,
    required this.businessId,
    required this.clientId,
    this.stripeSessionId,
    this.stripePaymentIntentId,
    required this.grossAmount,
    this.applicationFeeAmount = 0.0,
    this.stripeFeeAmount = 0.0,
    required this.netAmount,
    this.currency = 'usd',
    this.paymentStatus = 'succeeded',
    this.receiptUrl,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      businessId: json['business_id'] as String,
      clientId: json['client_id'] as String,
      stripeSessionId: json['stripe_session_id'] as String?,
      stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
      grossAmount: (json['gross_amount'] as num).toDouble(),
      applicationFeeAmount: (json['application_fee_amount'] as num?)?.toDouble() ?? 0.0,
      stripeFeeAmount: (json['stripe_fee_amount'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['net_amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'usd',
      paymentStatus: json['payment_status'] as String? ?? 'succeeded',
      receiptUrl: json['receipt_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'business_id': businessId,
      'client_id': clientId,
      'stripe_session_id': stripeSessionId,
      'stripe_payment_intent_id': stripePaymentIntentId,
      'gross_amount': grossAmount,
      'application_fee_amount': applicationFeeAmount,
      'stripe_fee_amount': stripeFeeAmount,
      'net_amount': netAmount,
      'currency': currency,
      'payment_status': paymentStatus,
      'receipt_url': receiptUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
