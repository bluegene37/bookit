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
}
