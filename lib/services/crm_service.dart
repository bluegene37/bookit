// Gene - Nov 06, 2026: Implemented CrmService for client lifecycle aggregation, spend analysis, and staff clinical notes
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_crm_profile.dart';
import '../models/booking.dart';
import 'booking_service.dart';
// Gene - Nov 07, 2026: Added SupabaseService, PaginatedResult, and AppErrorLogger imports for persistent CRM dossiers and paginated client aggregation
import 'supabase_service.dart';
import '../core/utils/paginated_result.dart';
import '../core/utils/app_error_logger.dart';
// Gene - Nov, 22, 2026: Added PlatformConfig, PlatformConfigService, and SupabaseConfig for DB-driven CRM segmentation and live RPC loading
import '../core/constants/supabase_config.dart';
import '../models/platform_config.dart';
import 'platform_config_service.dart';

/*
// Gene - Nov 06/07, 2026: Previous CrmService implementation with hardcoded dental notes, fixed thresholds, and stock avatar URL
*/
// Gene - Nov, 22, 2026: Database-driven CrmService with per-business dossier caching, dynamic CrmConfig thresholds, live RPC loading, and neutral client defaults
class CrmService {
  final Map<String, List<String>> _clientInternalNotes = {
    if (SupabaseService.client == null && SupabaseConfig.isDemoModeEnabled)
      '11111111-1111-1111-1111-111111111111_00000000-0000-0000-0000-000000000003': [
        'Client reports mild sensitivity; prefers topical numbing gel prior to procedures.',
        'Last annual assessment: excellent condition, recommended 6-month follow-up.',
      ],
  };

  final Map<String, List<String>> _clientMedicalFlags = {
    if (SupabaseService.client == null && SupabaseConfig.isDemoModeEnabled)
      '11111111-1111-1111-1111-111111111111_00000000-0000-0000-0000-000000000003': [
        'Penicillin Allergy',
        'Latex Sensitivity',
      ],
  };

  String _cacheKey(String clientId, {String? businessId}) {
    if (businessId == null || businessId.isEmpty) return clientId;
    return '${businessId}_$clientId';
  }

  List<String> _lookupCachedList(
    Map<String, List<String>> store,
    String clientId, {
    String? businessId,
  }) {
    final result = <String>[];
    if (businessId != null && businessId.isNotEmpty) {
      for (final item in (store['${businessId}_$clientId'] ?? const <String>[])) {
        if (!result.contains(item)) result.add(item);
      }
    }
    for (final item in (store[clientId] ?? const <String>[])) {
      if (!result.contains(item)) result.add(item);
    }
    return result;
  }

  List<ClientCrmProfile> aggregateClients(
    List<Booking> bookings, {
    String? businessId,
    CrmConfig crmConfig = const CrmConfig(),
    int? page,
    int? pageSize,
  }) {
    final Map<String, List<Booking>> clientBookingsMap = {};

    for (final b in bookings) {
      final clientId = b.clientId.isNotEmpty
          ? b.clientId
          : 'walkin:${(b.walkinClientName ?? b.clientName ?? b.id).trim()}';
      clientBookingsMap.putIfAbsent(clientId, () => []).add(b);
    }

    final List<ClientCrmProfile> profiles = [];
    final isDemo = SupabaseService.client == null && SupabaseConfig.isDemoModeEnabled;

    clientBookingsMap.forEach((clientId, clientBookings) {
      clientBookings.sort((a, b) {
        final aTime = a.startTime ?? a.dateFrom ?? a.createdAt;
        final bTime = b.startTime ?? b.dateFrom ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      final primary = clientBookings.first;
      final resolvedBizId = businessId ?? primary.businessId;
      final name = primary.clientName ?? primary.walkinClientName ?? 'Client';
      final isWalkIn = clientId.startsWith('walkin:');
      final email = (!isWalkIn && isDemo)
          ? '${name.toLowerCase().replaceAll(' ', '.')}@example.com'
          : null;
      final phone = (!isWalkIn && isDemo)
          ? '+1 (555) 019-${(clientId.hashCode.abs() % 900) + 100}'
          : null;

      double totalSpend = 0.0;
      int totalVisits = 0;
      int noShowCount = 0;

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

      DateTime? firstVisit =
          clientBookings.last.startTime ?? clientBookings.last.dateFrom;
      DateTime? lastVisit =
          clientBookings.first.startTime ?? clientBookings.first.dateFrom;

      final now = DateTime.now();
      String tag = 'New';
      if (totalSpend >= crmConfig.vipSpendThreshold ||
          totalVisits >= crmConfig.vipVisitsThreshold) {
        tag = 'VIP';
      } else if (totalVisits >= crmConfig.regularVisitsThreshold) {
        tag = 'Regular';
      } else if (lastVisit != null &&
          now.difference(lastVisit).inDays > crmConfig.lapsedDays) {
        tag = 'Lapsed';
      }

      final flags = _lookupCachedList(
        _clientMedicalFlags,
        clientId,
        businessId: resolvedBizId,
      );

      for (final b in clientBookings) {
        final notes = b.clientNotes?.toLowerCase() ?? '';
        if (notes.contains('allerg') &&
            !flags.any((f) => f.toLowerCase().contains('allerg'))) {
          flags.add('Allergy Note on File');
        }
      }

      final notes = _lookupCachedList(
        _clientInternalNotes,
        clientId,
        businessId: resolvedBizId,
      );

      profiles.add(
        ClientCrmProfile(
          id: clientId,
          name: name,
          email: email,
          phone: phone,
          avatarUrl: null,
          totalSpend: totalSpend,
          totalVisits: totalVisits,
          noShowCount: noShowCount,
          firstVisit: firstVisit,
          lastVisit: lastVisit,
          statusTag: tag,
          medicalFlags: flags,
          internalStaffNotes: notes,
          appointmentHistory: clientBookings,
        ),
      );
    });

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
    final key = _cacheKey(clientId, businessId: businessId);
    _clientInternalNotes.putIfAbsent(key, () => []).insert(0, '[$timestamp] $note');
    if (businessId != null && !clientId.startsWith('walkin:')) {
      _syncDossierToSupabase(businessId: businessId, clientId: clientId);
    }
  }

  void addMedicalFlag(String clientId, String flag, {String? businessId}) {
    final trimmed = flag.trim();
    if (trimmed.isEmpty) return;
    final key = _cacheKey(clientId, businessId: businessId);
    final list = _clientMedicalFlags.putIfAbsent(key, () => []);
    if (!list.any((f) => f.toLowerCase() == trimmed.toLowerCase())) {
      list.add(trimmed);
    }
    if (businessId != null && !clientId.startsWith('walkin:')) {
      _syncDossierToSupabase(businessId: businessId, clientId: clientId);
    }
  }

  void removeMedicalFlag(String clientId, String flag, {String? businessId}) {
    final lower = flag.trim().toLowerCase();
    final scopedKey = _cacheKey(clientId, businessId: businessId);
    _clientMedicalFlags[scopedKey]?.removeWhere((f) => f.toLowerCase() == lower);
    if (businessId != null) {
      _clientMedicalFlags[clientId]?.removeWhere((f) => f.toLowerCase() == lower);
      if (!clientId.startsWith('walkin:')) {
        _syncDossierToSupabase(businessId: businessId, clientId: clientId);
      }
    }
  }

  Map<String, dynamic> getDossierSnapshot(String clientId, {String? businessId}) {
    return {
      'client_id': clientId,
      'medical_flags': List<String>.unmodifiable(
        _lookupCachedList(_clientMedicalFlags, clientId, businessId: businessId),
      ),
      'internal_staff_notes': List<String>.unmodifiable(
        _lookupCachedList(_clientInternalNotes, clientId, businessId: businessId),
      ),
    };
  }

  Future<void> _syncDossierToSupabase({
    required String businessId,
    required String clientId,
  }) async {
    final client = SupabaseService.client;
    if (client == null) return;
    try {
      final key = _cacheKey(clientId, businessId: businessId);
      await client.from('client_crm_dossiers').upsert(
        {
          'business_id': businessId,
          'client_id': clientId,
          'medical_flags': _clientMedicalFlags[key] ?? const <String>[],
          'internal_staff_notes': _clientInternalNotes[key] ?? const <String>[],
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
        final key = _cacheKey(cid, businessId: businessId);
        final flags = (row['medical_flags'] as List?)?.map((e) => e.toString()).toList();
        final notes = (row['internal_staff_notes'] as List?)?.map((e) => e.toString()).toList();
        if (flags != null) _clientMedicalFlags[key] = flags;
        if (notes != null) _clientInternalNotes[key] = notes;
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
  final crmConfig = ref.watch(activePlatformConfigProvider).crmConfig;
  final client = SupabaseService.client;

  if (client != null) {
    try {
      await crmService.loadBusinessDossiers(businessId);
      final rpcData = await client.rpc(
        'get_business_crm_profiles',
        params: {
          'p_business_id': businessId,
          'p_limit': 100,
          'p_offset': 0,
        },
      );
      if (rpcData is List && rpcData.isNotEmpty) {
        final rpcProfiles = rpcData.whereType<Map>().map((raw) {
          final r = Map<String, dynamic>.from(raw);
          final cid = r['client_id']?.toString() ?? '';
          final history = bookings.where((b) => b.clientId == cid).toList();
          final flags = (r['medical_flags'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
          final notes = (r['internal_staff_notes'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
          return ClientCrmProfile(
            id: cid,
            name: (r['full_name'] as String?) ?? 'Client',
            email: r['email'] as String?,
            phone: r['phone'] as String?,
            avatarUrl: r['avatar_url'] as String?,
            totalSpend: (r['total_spend'] as num?)?.toDouble() ?? 0.0,
            totalVisits: (r['total_visits'] as num?)?.toInt() ?? 0,
            noShowCount: (r['no_show_count'] as num?)?.toInt() ?? 0,
            firstVisit: r['first_visit'] != null ? DateTime.tryParse(r['first_visit'].toString()) : null,
            lastVisit: r['last_visit'] != null ? DateTime.tryParse(r['last_visit'].toString()) : null,
            statusTag: (r['status_tag'] as String?) ?? 'New',
            medicalFlags: flags,
            internalStaffNotes: notes,
            appointmentHistory: history,
          );
        }).toList();

        // Also append walk-in bookings without linked profile UUIDs
        final walkinBookings = bookings.where((b) => b.clientId.isEmpty).toList();
        if (walkinBookings.isNotEmpty) {
          rpcProfiles.addAll(
            crmService.aggregateClients(
              walkinBookings,
              businessId: businessId,
              crmConfig: crmConfig,
            ),
          );
          rpcProfiles.sort((a, b) => b.totalSpend.compareTo(a.totalSpend));
        }
        return rpcProfiles;
      }
    } catch (e, st) {
      AppErrorLogger.report(
        service: 'CrmService',
        operation: 'businessClientsProvider',
        error: e,
        stackTrace: st,
      );
    }
  }

  return crmService.aggregateClients(
    bookings,
    businessId: businessId,
    crmConfig: crmConfig,
  );
});
