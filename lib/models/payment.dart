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
  // Gene - Nov 07, 2026: Added hybrid payment method, reference number, and sender account metadata
  final String paymentMethod; // 'stripe_card', 'gcash', 'maya', 'bank_transfer'
  final String? referenceNumber;
  final String? senderAccount;

  /*
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
  */

  // Gene - Nov 07, 2026: Updated Payment constructor supporting paymentMethod, referenceNumber, and senderAccount
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
    this.paymentMethod = 'stripe_card',
    this.referenceNumber,
    this.senderAccount,
  });

  // Gene - Nov 07, 2026: Human-readable display label for payment method
  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'gcash':
        return 'GCash';
      case 'maya':
        return 'Maya';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'stripe_card':
      default:
        return 'Card (Stripe)';
    }
  }

  /*
  // Gene - Nov, 04, 2026: Original Payment fromJson
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
  */

  // Gene - Nov, 05, 2026: Defensive fallback factory for missing payments
  factory Payment.fallback({
    String id = 'pay-fallback-0',
    String bookingId = 'bk-fallback-0',
    String businessId = '00000000-0000-0000-0000-000000000000',
    String clientId = '00000000-0000-0000-0000-000000000003',
  }) {
    return Payment(
      id: id,
      bookingId: bookingId,
      businessId: businessId,
      clientId: clientId,
      grossAmount: 100.0,
      applicationFeeAmount: 2.80,
      stripeFeeAmount: 3.20,
      netAmount: 94.00,
      currency: 'usd',
      paymentStatus: 'succeeded',
      createdAt: DateTime.now(),
    );
  }

  /*
  // Gene - Nov, 05, 2026: Hardened fromJson with strict null-safety and default fallbacks
  factory Payment.fromJson(Map<String, dynamic> json) {
    final gross = (json['gross_amount'] as num?)?.toDouble() ?? 0.0;
    final net = (json['net_amount'] as num?)?.toDouble() ?? gross;

    return Payment(
      id: json['id'] as String? ?? 'pay-fallback-0',
      bookingId: json['booking_id'] as String? ?? 'bk-fallback-0',
      businessId: json['business_id'] as String? ?? '00000000-0000-0000-0000-000000000000',
      clientId: json['client_id'] as String? ?? '00000000-0000-0000-0000-000000000003',
      stripeSessionId: json['stripe_session_id'] as String?,
      stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
      grossAmount: gross,
      applicationFeeAmount: (json['application_fee_amount'] as num?)?.toDouble() ?? 0.0,
      stripeFeeAmount: (json['stripe_fee_amount'] as num?)?.toDouble() ?? 0.0,
      netAmount: net,
      currency: json['currency'] as String? ?? 'usd',
      paymentStatus: json['payment_status'] as String? ?? 'succeeded',
      receiptUrl: json['receipt_url'] as String?,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
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
  */

  // Gene - Nov 07, 2026: Updated Payment fromJson and toJson supporting payment_method, reference_number, and sender_account
  factory Payment.fromJson(Map<String, dynamic> json) {
    final gross = (json['gross_amount'] as num?)?.toDouble() ?? 0.0;
    final net = (json['net_amount'] as num?)?.toDouble() ?? gross;

    return Payment(
      id: json['id'] as String? ?? 'pay-fallback-0',
      bookingId: json['booking_id'] as String? ?? 'bk-fallback-0',
      businessId: json['business_id'] as String? ?? '00000000-0000-0000-0000-000000000000',
      clientId: json['client_id'] as String? ?? '00000000-0000-0000-0000-000000000003',
      stripeSessionId: json['stripe_session_id'] as String?,
      stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
      grossAmount: gross,
      applicationFeeAmount: (json['application_fee_amount'] as num?)?.toDouble() ?? 0.0,
      stripeFeeAmount: (json['stripe_fee_amount'] as num?)?.toDouble() ?? 0.0,
      netAmount: net,
      currency: json['currency'] as String? ?? 'usd',
      paymentStatus: json['payment_status'] as String? ?? 'succeeded',
      receiptUrl: json['receipt_url'] as String?,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      paymentMethod: json['payment_method'] as String? ?? 'stripe_card',
      referenceNumber: json['reference_number'] as String?,
      senderAccount: json['sender_account'] as String?,
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
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'sender_account': senderAccount,
    };
  }
}
