// Gene - Nov 06, 2026: Implemented ClientCrmProfile data model for Patient/Client CRM and clinical history dossier
import '../../../models/booking.dart';

class ClientCrmProfile {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final double totalSpend;
  final int totalVisits;
  final int noShowCount;
  final DateTime? firstVisit;
  final DateTime? lastVisit;
  final String statusTag; // 'VIP', 'Regular', 'New', 'Lapsed'
  final List<String> medicalFlags;
  final List<String> internalStaffNotes;
  final List<Booking> appointmentHistory;

  const ClientCrmProfile({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.totalSpend,
    required this.totalVisits,
    this.noShowCount = 0,
    this.firstVisit,
    this.lastVisit,
    required this.statusTag,
    this.medicalFlags = const [],
    this.internalStaffNotes = const [],
    this.appointmentHistory = const [],
  });

  String get formattedSpend => '\$${totalSpend.toStringAsFixed(2)}';
  double get noShowRate => totalVisits > 0 ? (noShowCount / (totalVisits + noShowCount)) * 100 : 0.0;

  ClientCrmProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    double? totalSpend,
    int? totalVisits,
    int? noShowCount,
    DateTime? firstVisit,
    DateTime? lastVisit,
    String? statusTag,
    List<String>? medicalFlags,
    List<String>? internalStaffNotes,
    List<Booking>? appointmentHistory,
  }) {
    return ClientCrmProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalSpend: totalSpend ?? this.totalSpend,
      totalVisits: totalVisits ?? this.totalVisits,
      noShowCount: noShowCount ?? this.noShowCount,
      firstVisit: firstVisit ?? this.firstVisit,
      lastVisit: lastVisit ?? this.lastVisit,
      statusTag: statusTag ?? this.statusTag,
      medicalFlags: medicalFlags ?? this.medicalFlags,
      internalStaffNotes: internalStaffNotes ?? this.internalStaffNotes,
      appointmentHistory: appointmentHistory ?? this.appointmentHistory,
    );
  }
}
