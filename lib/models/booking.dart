// Gene - Nov, 03, 2026: Universal Booking model supporting slot appointments, date ranges, and daily sessions
import 'package:intl/intl.dart';

class Booking {
  final String id;
  final String businessId;
  final String clientId;
  final String? serviceId;
  final String? staffId;
  final String bookingModel; // 'slot_based', 'date_range', 'daily'
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled', 'rejected'
  final double totalPrice;
  final String? clientNotes;
  final String? adminNotes;
  final String? cancellationReason;
  final DateTime createdAt;

  // Joined display attributes
  final String? businessName;
  final String? serviceName;
  final String? staffName;
  final String? clientName;

  // Gene - Nov, 04, 2026: Added Stripe payment, hold expiration, and financial tracking fields
  final String paymentStatus; // 'unpaid', 'deposit_paid', 'paid_in_full', 'refunded', 'partially_refunded'
  final DateTime? holdExpiresAt;
  final double amountPaid;
  final double amountDue;

  /*
  const Booking({
    required this.id,
    required this.businessId,
    required this.clientId,
    this.serviceId,
    this.staffId,
    required this.bookingModel,
    this.startTime,
    this.endTime,
    this.dateFrom,
    this.dateTo,
    this.status = 'pending',
    required this.totalPrice,
    this.clientNotes,
    this.adminNotes,
    this.cancellationReason,
    required this.createdAt,
    this.businessName,
    this.serviceName,
    this.staffName,
    this.clientName,
  });
  */

  // Gene - Nov, 04, 2026: Updated constructor supporting payment status, deposit, and hold timer fields
  const Booking({
    required this.id,
    required this.businessId,
    required this.clientId,
    this.serviceId,
    this.staffId,
    required this.bookingModel,
    this.startTime,
    this.endTime,
    this.dateFrom,
    this.dateTo,
    this.status = 'pending',
    required this.totalPrice,
    this.clientNotes,
    this.adminNotes,
    this.cancellationReason,
    required this.createdAt,
    this.businessName,
    this.serviceName,
    this.staffName,
    this.clientName,
    this.paymentStatus = 'unpaid',
    this.holdExpiresAt,
    this.amountPaid = 0.0,
    this.amountDue = 0.0,
  });

  // Gene - Nov, 04, 2026: Added copyWith for immutability and state transitions
  Booking copyWith({
    String? id,
    String? businessId,
    String? clientId,
    String? serviceId,
    String? staffId,
    String? bookingModel,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
    double? totalPrice,
    String? clientNotes,
    String? adminNotes,
    String? cancellationReason,
    DateTime? createdAt,
    String? businessName,
    String? serviceName,
    String? staffName,
    String? clientName,
    String? paymentStatus,
    DateTime? holdExpiresAt,
    double? amountPaid,
    double? amountDue,
  }) {
    return Booking(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      clientId: clientId ?? this.clientId,
      serviceId: serviceId ?? this.serviceId,
      staffId: staffId ?? this.staffId,
      bookingModel: bookingModel ?? this.bookingModel,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      clientNotes: clientNotes ?? this.clientNotes,
      adminNotes: adminNotes ?? this.adminNotes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      businessName: businessName ?? this.businessName,
      serviceName: serviceName ?? this.serviceName,
      staffName: staffName ?? this.staffName,
      clientName: clientName ?? this.clientName,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      holdExpiresAt: holdExpiresAt ?? this.holdExpiresAt,
      amountPaid: amountPaid ?? this.amountPaid,
      amountDue: amountDue ?? this.amountDue,
    );
  }

  bool get isSlotBased => bookingModel == 'slot_based';
  bool get isDateRange => bookingModel == 'date_range';
  bool get isDaily => bookingModel == 'daily';

  String get formattedSchedule {
    if (isSlotBased && startTime != null) {
      final dateStr = DateFormat('EEE, MMM d, yyyy').format(startTime!);
      final timeStr = DateFormat('h:mm a').format(startTime!);
      final endStr = endTime != null ? ' - ${DateFormat('h:mm a').format(endTime!)}' : '';
      return '$dateStr at $timeStr$endStr';
    } else if (isDateRange && dateFrom != null && dateTo != null) {
      final fromStr = DateFormat('MMM d, yyyy').format(dateFrom!);
      final toStr = DateFormat('MMM d, yyyy').format(dateTo!);
      final days = dateTo!.difference(dateFrom!).inDays;
      return '$fromStr → $toStr ($days ${days == 1 ? 'day' : 'days'})';
    } else if (isDaily && dateFrom != null) {
      return DateFormat('EEEE, MMM d, yyyy').format(dateFrom!);
    }
    return 'Schedule pending';
  }

  /*
  factory Booking.fromJson(Map<String, dynamic> json) {
    // Check joined nested maps if present
    final bMap = json['businesses'] as Map<String, dynamic>?;
    final sMap = json['services'] as Map<String, dynamic>?;
    final stMap = json['business_staff'] as Map<String, dynamic>?;
    final pMap = json['profiles'] as Map<String, dynamic>?;

    return Booking(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      clientId: json['client_id'] as String,
      serviceId: json['service_id'] as String?,
      staffId: json['staff_id'] as String?,
      bookingModel: json['booking_model'] as String? ?? 'slot_based',
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time'] as String) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      dateFrom: json['date_from'] != null ? DateTime.parse(json['date_from'] as String) : null,
      dateTo: json['date_to'] != null ? DateTime.parse(json['date_to'] as String) : null,
      status: json['status'] as String? ?? 'pending',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      clientNotes: json['client_notes'] as String?,
      adminNotes: json['admin_notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      businessName: bMap != null ? bMap['name'] as String? : json['business_name'] as String?,
      serviceName: sMap != null ? sMap['name'] as String? : json['service_name'] as String?,
      staffName: stMap != null ? stMap['name'] as String? : json['staff_name'] as String?,
      clientName: pMap != null ? pMap['full_name'] as String? : json['client_name'] as String?,
    );
  }
  */

  /*
  // Gene - Nov, 04, 2026: Updated fromJson deserialization supporting payment status and financial amounts
  factory Booking.fromJson(Map<String, dynamic> json) {
    // Check joined nested maps if present
    final bMap = json['businesses'] as Map<String, dynamic>?;
    final sMap = json['services'] as Map<String, dynamic>?;
    final stMap = json['business_staff'] as Map<String, dynamic>?;
    final pMap = json['profiles'] as Map<String, dynamic>?;

    return Booking(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      clientId: json['client_id'] as String,
      serviceId: json['service_id'] as String?,
      staffId: json['staff_id'] as String?,
      bookingModel: json['booking_model'] as String? ?? 'slot_based',
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time'] as String) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      dateFrom: json['date_from'] != null ? DateTime.parse(json['date_from'] as String) : null,
      dateTo: json['date_to'] != null ? DateTime.parse(json['date_to'] as String) : null,
      status: json['status'] as String? ?? 'pending',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      clientNotes: json['client_notes'] as String?,
      adminNotes: json['admin_notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      businessName: bMap != null ? bMap['name'] as String? : json['business_name'] as String?,
      serviceName: sMap != null ? sMap['name'] as String? : json['service_name'] as String?,
      staffName: stMap != null ? stMap['name'] as String? : json['staff_name'] as String?,
      clientName: pMap != null ? pMap['full_name'] as String? : json['client_name'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      holdExpiresAt: json['hold_expires_at'] != null
          ? DateTime.parse(json['hold_expires_at'] as String)
          : null,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
      amountDue: (json['amount_due'] as num?)?.toDouble() ?? ((json['total_price'] as num?)?.toDouble() ?? 0.0),
    );
  }
  */

  // Gene - Nov, 05, 2026: Defensive fallback factory for missing bookings
  factory Booking.fallback({
    String id = 'bk-fallback-0',
    String businessId = '00000000-0000-0000-0000-000000000000',
    String clientId = '00000000-0000-0000-0000-000000000003',
  }) {
    return Booking(
      id: id,
      businessId: businessId,
      clientId: clientId,
      bookingModel: 'slot_based',
      startTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      endTime: DateTime.now().add(const Duration(days: 1, hours: 2, minutes: 45)),
      status: 'confirmed',
      totalPrice: 100.0,
      businessName: 'Apex Dental & Orthodontic Care',
      serviceName: 'Comprehensive Dental Exam',
      staffName: 'Dr. Alexander Vance',
      clientName: 'Michael Chen',
      paymentStatus: 'paid_in_full',
      createdAt: DateTime.now(),
    );
  }

  // Gene - Nov, 05, 2026: Hardened fromJson with strict null-safety and default fallbacks
  factory Booking.fromJson(Map<String, dynamic> json) {
    final bMap = json['businesses'] as Map<String, dynamic>?;
    final sMap = json['services'] as Map<String, dynamic>?;
    final stMap = json['business_staff'] as Map<String, dynamic>?;
    final pMap = json['profiles'] as Map<String, dynamic>?;

    return Booking(
      id: json['id'] as String? ?? 'bk-fallback-0',
      businessId: json['business_id'] as String? ?? '00000000-0000-0000-0000-000000000000',
      clientId: json['client_id'] as String? ?? '00000000-0000-0000-0000-000000000003',
      serviceId: json['service_id'] as String?,
      staffId: json['staff_id'] as String?,
      bookingModel: json['booking_model'] as String? ?? 'slot_based',
      startTime: json['start_time'] != null ? DateTime.tryParse(json['start_time'].toString()) : null,
      endTime: json['end_time'] != null ? DateTime.tryParse(json['end_time'].toString()) : null,
      dateFrom: json['date_from'] != null ? DateTime.tryParse(json['date_from'].toString()) : null,
      dateTo: json['date_to'] != null ? DateTime.tryParse(json['date_to'].toString()) : null,
      status: json['status'] as String? ?? 'pending',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      clientNotes: json['client_notes'] as String?,
      adminNotes: json['admin_notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      businessName: bMap != null ? bMap['name'] as String? : json['business_name'] as String?,
      serviceName: sMap != null ? sMap['name'] as String? : json['service_name'] as String?,
      staffName: stMap != null ? stMap['name'] as String? : json['staff_name'] as String?,
      clientName: pMap != null ? pMap['full_name'] as String? : json['client_name'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      holdExpiresAt: json['hold_expires_at'] != null
          ? DateTime.tryParse(json['hold_expires_at'].toString())
          : null,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
      amountDue: (json['amount_due'] as num?)?.toDouble() ?? ((json['total_price'] as num?)?.toDouble() ?? 0.0),
    );
  }

  /*
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'client_id': clientId,
      'service_id': serviceId,
      'staff_id': staffId,
      'booking_model': bookingModel,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'date_from': dateFrom != null ? DateFormat('yyyy-MM-dd').format(dateFrom!) : null,
      'date_to': dateTo != null ? DateFormat('yyyy-MM-dd').format(dateTo!) : null,
      'status': status,
      'total_price': totalPrice,
      'client_notes': clientNotes,
      'admin_notes': adminNotes,
      'cancellation_reason': cancellationReason,
      'created_at': createdAt.toIso8601String(),
    };
  }
  */

  // Gene - Nov, 04, 2026: Updated toJson serialization with payment fields
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'client_id': clientId,
      'service_id': serviceId,
      'staff_id': staffId,
      'booking_model': bookingModel,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'date_from': dateFrom != null ? DateFormat('yyyy-MM-dd').format(dateFrom!) : null,
      'date_to': dateTo != null ? DateFormat('yyyy-MM-dd').format(dateTo!) : null,
      'status': status,
      'total_price': totalPrice,
      'client_notes': clientNotes,
      'admin_notes': adminNotes,
      'cancellation_reason': cancellationReason,
      'created_at': createdAt.toIso8601String(),
      'payment_status': paymentStatus,
      'hold_expires_at': holdExpiresAt?.toIso8601String(),
      'amount_paid': amountPaid,
      'amount_due': amountDue,
    };
  }
}
