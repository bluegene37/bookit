// Gene - Nov 06, 2026: Implemented CrmService for client lifecycle aggregation, spend analysis, and staff clinical notes
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_crm_profile.dart';
import '../models/booking.dart';
import 'booking_service.dart';
// Gene - Nov 07, 2026: Added SupabaseService, PaginatedResult, and AppErrorLogger imports for persistent CRM dossiers and paginated client aggregation
import 'supabase_service.dart';
import '../core/utils/paginated_result.dart';
import '../core/utils/app_error_logger.dart';

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

  /*
  /// Aggregates bookings into unique client profiles with historical LTV metrics
  List<ClientCrmProfile> aggregateClients(List<Booking> bookings) {
  */
  // Gene - Nov 07, 2026: Upgraded aggregateClients with optional page & pageSize pagination for large clinical rosters
  List<ClientCrmProfile> aggregateClients(
    List<Booking> bookings, {
    int? page,
    int? pageSize,
  }) {
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

      /*
      for (final b in clientBookings) {
        if (b.status == 'completed' || b.status == 'confirmed' || b.status == 'arrived' || b.status == 'in_session') {
          totalSpend += b.totalPrice;
          totalVisits++;
        } else if (b.status == 'no_show') {
          noShowCount++;
        }
      }
      */
      // Gene - Nov 07, 2026: Aligned booking status strings ('checked_in', 'in_service', 'rejected') for accurate LTV and no-show calculation
      for (final b in clientBookings) {
        if (b.status == 'completed' ||
            b.status == 'confirmed' ||
            b.status == 'checked_in' ||
            b.status == 'arrived' ||
            b.status == 'in_service' ||
            b.status == 'in_session') {
          totalSpend += b.totalPrice;
          totalVisits++;
        } else if (b.status == 'no_show' || b.status == 'rejected') {
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

    /*
    // Sort by lifetime spend descending
    profiles.sort((a, b) => b.totalSpend.compareTo(a.totalSpend));
    return profiles;
  }

  void addInternalNote(String clientId, String note) {
    if (note.trim().isEmpty) return;
    final timestamp = DateTime.now().toString().split(' ').first;
    _clientInternalNotes.putIfAbsent(clientId, () => []).insert(0, '[$timestamp] $note');
  }
    */
    // Gene - Nov 07, 2026: Sort by lifetime spend descending and apply optional pagination + Supabase CRM dossier persistence
    profiles.sort((a, b) => b.totalSpend.compareTo(a.totalSpend));
    if (page != null && pageSize != null && page >= 0 && pageSize > 0) {
      return PaginatedResult.fromFullList(
        fullList: profiles,
        page: page,
        pageSize: pageSize,
      ).items;
    }
    return profiles;
  }

  void addInternalNote(String clientId, String note, {String? businessId}) {
    if (note.trim().isEmpty) return;
    final timestamp = DateTime.now().toString().split(' ').first;
    _clientInternalNotes.putIfAbsent(clientId, () => []).insert(0, '[$timestamp] $note');
    if (businessId != null) {
      _syncDossierToSupabase(businessId: businessId, clientId: clientId);
    }
  }

  /*
  void addMedicalFlag(String clientId, String flag) {
    if (flag.trim().isEmpty) return;
    _clientMedicalFlags.putIfAbsent(clientId, () => []).add(flag.trim());
  }
  */
  /*
  // Gene - Nov 07, 2026: Deduplicated addMedicalFlag and added removeMedicalFlag for interactive clinical dossier management
  void addMedicalFlag(String clientId, String flag) {
    final trimmed = flag.trim();
    if (trimmed.isEmpty) return;
    final list = _clientMedicalFlags.putIfAbsent(clientId, () => []);
    if (!list.any((f) => f.toLowerCase() == trimmed.toLowerCase())) {
      list.add(trimmed);
    }
  }

  void removeMedicalFlag(String clientId, String flag) {
    final list = _clientMedicalFlags[clientId];
    if (list != null) {
      list.removeWhere((f) => f.toLowerCase() == flag.trim().toLowerCase());
    }
  }
}
  */

  // Gene - Nov 07, 2026: Deduplicated addMedicalFlag / removeMedicalFlag with Supabase `client_crm_dossiers` persistence and getDossierSnapshot
  void addMedicalFlag(String clientId, String flag, {String? businessId}) {
    final trimmed = flag.trim();
    if (trimmed.isEmpty) return;
    final list = _clientMedicalFlags.putIfAbsent(clientId, () => []);
    if (!list.any((f) => f.toLowerCase() == trimmed.toLowerCase())) {
      list.add(trimmed);
    }
    if (businessId != null) {
      _syncDossierToSupabase(businessId: businessId, clientId: clientId);
    }
  }

  void removeMedicalFlag(String clientId, String flag, {String? businessId}) {
    final list = _clientMedicalFlags[clientId];
    if (list != null) {
      list.removeWhere((f) => f.toLowerCase() == flag.trim().toLowerCase());
    }
    if (businessId != null) {
      _syncDossierToSupabase(businessId: businessId, clientId: clientId);
    }
  }

  Map<String, dynamic> getDossierSnapshot(String clientId) {
    return {
      'client_id': clientId,
      'medical_flags': List<String>.unmodifiable(_clientMedicalFlags[clientId] ?? const []),
      'internal_staff_notes': List<String>.unmodifiable(_clientInternalNotes[clientId] ?? const []),
    };
  }

  Future<void> _syncDossierToSupabase({
    required String businessId,
    required String clientId,
  }) async {
    final client = SupabaseService.client;
    if (client == null) return;
    try {
      await client.from('client_crm_dossiers').upsert(
        {
          'business_id': businessId,
          'client_id': clientId,
          'medical_flags': _clientMedicalFlags[clientId] ?? const <String>[],
          'internal_staff_notes': _clientInternalNotes[clientId] ?? const <String>[],
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'business_id,client_id',
      );
    } catch (e, st) {
      AppErrorLogger.report(
        service: 'CrmService',
        operation: '_syncDossierToSupabase',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> loadBusinessDossiers(String businessId) async {
    final client = SupabaseService.client;
    if (client == null) return;
    try {
      final rows = await client
          .from('client_crm_dossiers')
          .select()
          .eq('business_id', businessId);
      for (final row in (rows as List)) {
        final cid = row['client_id']?.toString();
        if (cid == null || cid.isEmpty) continue;
        final flags = (row['medical_flags'] as List?)?.map((e) => e.toString()).toList();
        final notes = (row['internal_staff_notes'] as List?)?.map((e) => e.toString()).toList();
        if (flags != null) _clientMedicalFlags[cid] = flags;
        if (notes != null) _clientInternalNotes[cid] = notes;
      }
    } catch (e, st) {
      AppErrorLogger.report(
        service: 'CrmService',
        operation: 'loadBusinessDossiers',
        error: e,
        stackTrace: st,
      );
    }
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
