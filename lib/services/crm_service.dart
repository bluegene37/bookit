// Gene - Nov 06, 2026: Implemented CrmService for client lifecycle aggregation, spend analysis, and staff clinical notes
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_crm_profile.dart';
import '../models/booking.dart';
import 'booking_service.dart';

class CrmService {
  final Map<String, List<String>> _clientInternalNotes = {
    '00000000-0000-0000-0000-000000000003': [
      'Patient reports mild dental anxiety; prefers topical numbing gel prior to injections.',
      'Last oral hygiene assessment: excellent enamel health, recommended 6-month checkup.',
    ],
  };

  final Map<String, List<String>> _clientMedicalFlags = {
    '00000000-0000-0000-0000-000000000003': [
      'Penicillin Allergy',
      'Latex Sensitivity',
    ],
  };

  /// Aggregates bookings into unique client profiles with historical LTV metrics
  List<ClientCrmProfile> aggregateClients(List<Booking> bookings) {
    final Map<String, List<Booking>> clientBookingsMap = {};

    for (final b in bookings) {
      final clientId = b.clientId.isNotEmpty ? b.clientId : (b.clientName ?? 'unknown');
      clientBookingsMap.putIfAbsent(clientId, () => []).add(b);
    }

    final List<ClientCrmProfile> profiles = [];

    clientBookingsMap.forEach((clientId, clientBookings) {
      // Sort bookings by date descending
      clientBookings.sort((a, b) {
        final aTime = a.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      final primary = clientBookings.first;
      final name = primary.clientName ?? 'Patient / Client';
      final email = '${name.toLowerCase().replaceAll(' ', '.')}@example.com';
      final phone = '+1 (555) 019-${(clientId.hashCode.abs() % 900) + 100}';

      double totalSpend = 0.0;
      int totalVisits = 0;
      int noShowCount = 0;

      for (final b in clientBookings) {
        if (b.status == 'completed' || b.status == 'confirmed' || b.status == 'arrived' || b.status == 'in_session') {
          totalSpend += b.totalPrice;
          totalVisits++;
        } else if (b.status == 'no_show') {
          noShowCount++;
        }
      }

      DateTime? firstVisit = clientBookings.last.startTime;
      DateTime? lastVisit = clientBookings.first.startTime;

      // Calculate status tag
      final now = DateTime.now();
      String tag = 'New';
      if (totalSpend >= 350.0 || totalVisits >= 3) {
        tag = 'VIP';
      } else if (totalVisits >= 2) {
        tag = 'Regular';
      } else if (lastVisit != null && now.difference(lastVisit).inDays > 90) {
        tag = 'Lapsed';
      }

      final flags = [
        ...?_clientMedicalFlags[clientId],
      ];

      // Extract flags from booking notes if present
      for (final b in clientBookings) {
        final notes = b.clientNotes?.toLowerCase() ?? '';
        if (notes.contains('allerg') && !flags.any((f) => f.toLowerCase().contains('allerg'))) {
          flags.add('Allergy Note on File');
        }
      }

      profiles.add(
        ClientCrmProfile(
          id: clientId,
          name: name,
          email: email,
          phone: phone,
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
          totalSpend: totalSpend,
          totalVisits: totalVisits,
          noShowCount: noShowCount,
          firstVisit: firstVisit,
          lastVisit: lastVisit,
          statusTag: tag,
          medicalFlags: flags,
          internalStaffNotes: _clientInternalNotes[clientId] ?? [
            'Initial patient onboarding complete. No adverse reactions recorded.',
          ],
          appointmentHistory: clientBookings,
        ),
      );
    });

    // Sort by lifetime spend descending
    profiles.sort((a, b) => b.totalSpend.compareTo(a.totalSpend));
    return profiles;
  }

  void addInternalNote(String clientId, String note) {
    if (note.trim().isEmpty) return;
    final timestamp = DateTime.now().toString().split(' ').first;
    _clientInternalNotes.putIfAbsent(clientId, () => []).insert(0, '[$timestamp] $note');
  }

  void addMedicalFlag(String clientId, String flag) {
    if (flag.trim().isEmpty) return;
    _clientMedicalFlags.putIfAbsent(clientId, () => []).add(flag.trim());
  }
}

final crmServiceProvider = Provider<CrmService>((ref) => CrmService());

final crmSearchQueryProvider = StateProvider<String>((ref) => '');
final crmSelectedTagProvider = StateProvider<String>((ref) => 'All');

final businessClientsProvider = FutureProvider.family<List<ClientCrmProfile>, String>((ref, businessId) async {
  final bookings = ref.watch(adminBookingsProvider(businessId));
  final crmService = ref.watch(crmServiceProvider);
  return crmService.aggregateClients(bookings);
});
