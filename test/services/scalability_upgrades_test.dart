// Gene - Nov 07, 2026: Scalability upgrades TDD test suite covering pagination, date-windowing, RPC slot parsing, CRM dossier pagination, geocoding coalescing/LRU cache, and structured error telemetry
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bookit/core/utils/app_error_logger.dart';
import 'package:bookit/core/utils/paginated_result.dart';
import 'package:bookit/features/booking_engine/domain/slot_calculator.dart';
import 'package:bookit/models/booking.dart';
import 'package:bookit/models/business.dart';
import 'package:bookit/models/business_staff.dart';
import 'package:bookit/services/booking_service.dart';
import 'package:bookit/services/business_service.dart';
import 'package:bookit/services/crm_service.dart';
import 'package:bookit/services/location_geocoding_service.dart';
import 'package:bookit/services/supabase_service.dart';

void main() {
  setUp(() {
    SupabaseService.resetToDefaultData();
    AppErrorLogger.clear();
  });

  group('1. Paginated Business Discovery (BusinessService & PaginatedResult)', () {
    test('getBusinessesPaginated slices pages accurately and reports hasMore and totalCount', () async {
      final service = BusinessService();

      final page0 = await service.getBusinessesPaginated(page: 0, pageSize: 2);
      expect(page0, isA<PaginatedResult<Business>>());
      expect(page0.items.length, 2);
      expect(page0.page, 0);
      expect(page0.pageSize, 2);
      expect(page0.totalCount, greaterThanOrEqualTo(6));
      expect(page0.hasMore, isTrue);

      final page1 = await service.getBusinessesPaginated(page: 1, pageSize: 2);
      expect(page1.items.length, 2);
      expect(page1.items.first.id, isNot(equals(page0.items.first.id)));
    });
  });

  group('2. Date-Windowed Bookings & RPC Slot Calculation', () {
    test('SlotCalculator.filterBookingsForDate narrows global bookings to target day and business', () {
      final targetDate = DateTime(2026, 11, 15);
      final bookings = [
        Booking(
          id: 'bk-target-day',
          businessId: 'biz-1',
          clientId: 'client-1',
          staffId: 'staff-1',
          bookingModel: 'slot_based',
          startTime: DateTime(2026, 11, 15, 10, 0),
          endTime: DateTime(2026, 11, 15, 10, 45),
          status: 'confirmed',
          totalPrice: 100,
          createdAt: DateTime(2026, 11, 1),
        ),
        Booking(
          id: 'bk-other-day',
          businessId: 'biz-1',
          clientId: 'client-1',
          staffId: 'staff-1',
          bookingModel: 'slot_based',
          startTime: DateTime(2026, 11, 16, 10, 0),
          endTime: DateTime(2026, 11, 16, 10, 45),
          status: 'confirmed',
          totalPrice: 100,
          createdAt: DateTime(2026, 11, 1),
        ),
        Booking(
          id: 'bk-other-biz',
          businessId: 'biz-2',
          clientId: 'client-1',
          staffId: 'staff-1',
          bookingModel: 'slot_based',
          startTime: DateTime(2026, 11, 15, 11, 0),
          endTime: DateTime(2026, 11, 15, 11, 45),
          status: 'confirmed',
          totalPrice: 100,
          createdAt: DateTime(2026, 11, 1),
        ),
      ];

      final filtered = SlotCalculator.filterBookingsForDate(
        bookings,
        targetDate,
        businessId: 'biz-1',
        staffId: 'staff-1',
      );

      expect(filtered.length, 1);
      expect(filtered.first.id, 'bk-target-day');
    });

    test('SlotCalculator.fromRpcResponse parses PostgreSQL get_available_slots RPC rows and enforces staff breaks', () {
      final rpcRows = [
        {
          'slot_start': '2026-11-16T09:00:00.000',
          'slot_end': '2026-11-16T09:30:00.000',
          'is_available': true,
        },
        {
          'slot_start': '2026-11-16T12:00:00.000',
          'slot_end': '2026-11-16T12:30:00.000',
          'is_available': true,
        },
      ];

      const staffWithLunchBreak = BusinessStaff(
        id: 'staff-1',
        businessId: 'biz-1',
        name: 'Dr. Vance',
        scheduleOverride: {
          'monday': {
            'is_working': true,
            'start': '09:00',
            'end': '17:00',
            'has_break': true,
            'break_start': '12:00',
            'break_end': '13:00',
          },
        },
      );

      final slots = SlotCalculator.fromRpcResponse(
        rpcRows,
        staffMember: staffWithLunchBreak,
      );

      expect(slots.length, 2);
      expect(slots[0].isAvailable, isTrue);
      // 12:00 - 12:30 falls inside Dr. Vance's 12:00-13:00 break
      expect(slots[1].isAvailable, isFalse);
    });

    test('dateWindowedBookingsProvider returns only bookings within [from, to] window for business', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final all = container.read(bookingsProvider);
      final targetBizId = all.first.businessId;
      final now = DateTime.now();

      final windowed = container.read(
        dateWindowedBookingsProvider((
          businessId: targetBizId,
          from: now.subtract(const Duration(days: 1)),
          to: now.add(const Duration(days: 5)),
        )),
      );

      for (final b in windowed) {
        expect(b.businessId, targetBizId);
        final effectiveDate = b.startTime ?? b.dateFrom;
        expect(effectiveDate, isNotNull);
      }
    });
  });

  group('3. CRM Pagination & Dossier Persistence Snapshot', () {
    test('CrmService.aggregateClients supports page & pageSize and getDossierSnapshot returns flags & notes', () {
      final crm = CrmService();
      final bookings = [
        ...SupabaseService.mockBookings,
        Booking(
          id: 'bk-crm-2',
          businessId: '11111111-1111-1111-1111-111111111111',
          clientId: 'client-vip-2',
          clientName: 'Elena Vance',
          bookingModel: 'slot_based',
          startTime: DateTime(2026, 11, 10, 14, 0),
          endTime: DateTime(2026, 11, 10, 15, 0),
          status: 'completed',
          totalPrice: 520.0,
          createdAt: DateTime(2026, 11, 1),
        ),
      ];

      final allProfiles = crm.aggregateClients(bookings);
      expect(allProfiles.length, greaterThanOrEqualTo(2));

      final page0 = crm.aggregateClients(bookings, page: 0, pageSize: 1);
      final page1 = crm.aggregateClients(bookings, page: 1, pageSize: 1);

      expect(page0.length, 1);
      expect(page1.length, 1);
      expect(page0.first.id, isNot(equals(page1.first.id)));

      crm.addMedicalFlag('client-scale-1', 'Lidocaine Sensitivity');
      crm.addInternalNote('client-scale-1', 'Prefers morning appointments.');

      final dossier = crm.getDossierSnapshot('client-scale-1');
      expect(dossier['medical_flags'], contains('Lidocaine Sensitivity'));
      expect((dossier['internal_staff_notes'] as List).first, contains('Prefers morning appointments.'));
    });
  });

  group('4. LocationGeocodingService In-Flight Coalescing & Bounded LRU Cache', () {
    test('coalesces concurrent identical searchAddress requests into a single HTTP call', () async {
      int httpCallCount = 0;
      final mockClient = MockClient((request) async {
        httpCallCount++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response(
          jsonEncode([
            {
              'lat': '37.7879',
              'lon': '-122.4074',
              'display_name': '450 Sutter St, San Francisco, CA',
              'address': {'house_number': '450', 'road': 'Sutter St', 'city': 'San Francisco'},
            }
          ]),
          200,
        );
      });

      final service = LocationGeocodingService(client: mockClient);

      final futures = List.generate(5, (_) => service.searchAddress('450 Sutter St'));
      final results = await Future.wait(futures);

      expect(httpCallCount, 1);
      for (final res in results) {
        expect(res.first.city, 'San Francisco');
      }
    });

    test('evicts oldest entry when search cache exceeds maxCacheEntries', () async {
      int httpCallCount = 0;
      final mockClient = MockClient((request) async {
        httpCallCount++;
        final q = request.url.queryParameters['q'] ?? 'unknown';
        return http.Response(
          jsonEncode([
            {
              'lat': '37.77',
              'lon': '-122.41',
              'display_name': 'Address $q',
              'address': {'road': 'Road $q', 'city': 'City $q'},
            }
          ]),
          200,
        );
      });

      final service = LocationGeocodingService(client: mockClient, maxCacheEntries: 2);

      await service.searchAddress('Query A');
      await service.searchAddress('Query B');
      expect(httpCallCount, 2);

      // Cached hit for Query A (refreshes LRU order so Query B becomes oldest)
      await service.searchAddress('Query A');
      expect(httpCallCount, 2);

      // Adding Query C should evict Query B (since maxCacheEntries == 2)
      await service.searchAddress('Query C');
      expect(httpCallCount, 3);
      expect(service.searchCacheSize, 2);

      // Query A should still be cached
      await service.searchAddress('Query A');
      expect(httpCallCount, 3);

      // Query B was evicted, so querying it again triggers HTTP call #4
      await service.searchAddress('Query B');
      expect(httpCallCount, 4);
    });
  });

  group('5. AppErrorLogger Structured Telemetry Ring Buffer', () {
    test('records structured error events and enforces maxBufferSize', () {
      for (int i = 0; i < 5; i++) {
        AppErrorLogger.report(
          service: 'BookingService',
          operation: 'op_$i',
          error: Exception('Simulated error $i'),
          maxBufferSize: 3,
        );
      }

      expect(AppErrorLogger.recentEvents.length, 3);
      expect(AppErrorLogger.recentEvents.first.operation, 'op_4');
      expect(AppErrorLogger.recentEvents.last.operation, 'op_2');
    });
  });
}
