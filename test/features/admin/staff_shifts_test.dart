// Gene - Nov 06, 2026: Comprehensive tests for Staff Shift Matrix, Lunch Breaks, and SlotCalculator enforcement
import 'dart:async';
// Gene - Nov, 14, 2026: Added dart:convert for mock Nominatim geocoding JSON responses
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookit/models/business.dart';
import 'package:bookit/models/business_staff.dart';
import 'package:bookit/features/booking_engine/domain/slot_calculator.dart';
import 'package:bookit/services/business_service.dart';
import 'package:bookit/features/admin/presentation/widgets/staff_shift_editor_dialog.dart';
import 'package:bookit/features/admin/presentation/staff_manager_tab.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('BusinessStaff Model Tests', () {
    test('defaultSchedule provides standard 5-day week with lunch breaks', () {
      final schedule = BusinessStaff.defaultSchedule();

      expect(schedule.keys.length, 7);
      expect(schedule['monday']!['is_working'], true);
      expect(schedule['monday']!['start'], '09:00');
      expect(schedule['monday']!['end'], '17:00');
      expect(schedule['monday']!['has_break'], true);
      expect(schedule['monday']!['break_start'], '12:00');
      expect(schedule['monday']!['break_end'], '13:00');

      expect(schedule['saturday']!['is_working'], false);
      expect(schedule['sunday']!['is_working'], false);
    });

    test('helper methods return configured shift and break values', () {
      final staff = BusinessStaff(
        id: 'staff-1',
        businessId: 'biz-1',
        name: 'Dr. Jane Smith',
        specialty: 'Orthodontics',
        scheduleOverride: {
          'wednesday': {
            'is_working': true,
            'start': '10:00',
            'end': '18:00',
            'has_break': true,
            'break_start': '13:00',
            'break_end': '14:00',
          },
          'sunday': {
            'is_working': false,
            'start': '09:00',
            'end': '12:00',
            'has_break': false,
          },
        },
      );

      expect(staff.isWorkingOn('wednesday'), true);
      expect(staff.shiftStart('wednesday'), '10:00');
      expect(staff.shiftEnd('wednesday'), '18:00');
      expect(staff.hasBreak('wednesday'), true);
      expect(staff.breakStart('wednesday'), '13:00');
      expect(staff.breakEnd('wednesday'), '14:00');

      expect(staff.isWorkingOn('sunday'), false);
    });

    test('shiftSummary formats concise schedule overview', () {
      final staff = BusinessStaff(
        id: 'staff-2',
        businessId: 'biz-1',
        name: 'Dr. Michael Chen',
        scheduleOverride: BusinessStaff.defaultSchedule(),
      );

      expect(staff.shiftSummary, contains('Mon–Fri: 09:00–17:00'));
      expect(staff.shiftSummary, contains('Break: 12:00-13:00'));
    });
  });

  group('SlotCalculator Shift & Break Enforcement Tests', () {
    late Business clinic;
    late BusinessStaff drVance;

    setUp(() {
      clinic = Business(
        id: 'clinic-apex',
        ownerId: 'owner-1',
        name: 'Apex Dental Care',
        slug: 'apex-dental',
        category: 'dental',
        bookingModel: BookingModelType.slotBased,
        settings: {
          'slot_interval_minutes': 30,
          'working_hours': {
            'monday': {'open': '09:00', 'close': '17:00', 'is_open': true},
          },
        },
      );

      // Dr. Vance works Monday 10:00 - 15:00 with lunch break 12:00 - 13:00
      drVance = BusinessStaff(
        id: 'staff-vance',
        businessId: 'clinic-apex',
        name: 'Dr. Alex Vance',
        specialty: 'Dental Surgeon',
        scheduleOverride: {
          'monday': {
            'is_working': true,
            'start': '10:00',
            'end': '15:00',
            'has_break': true,
            'break_start': '12:00',
            'break_end': '13:00',
          },
          'tuesday': {
            'is_working': false,
          },
        },
      );
    });

    test('suppresses slots outside practitioner shift hours and during lunch break', () {
      // Nov 9, 2026 is a Monday
      final monday = DateTime(2026, 11, 9);

      final slots = SlotCalculator.calculateAvailableSlots(
        business: clinic,
        date: monday,
        existingBookings: [],
        filterStaffId: drVance.id,
        staffMember: drVance,
      );

      // Clinic is open 09:00 to 17:00 (16 half-hour slots total)
      expect(slots.length, 16);

      // 09:00 and 09:30 are before Dr. Vance's shift starts (10:00) -> unavailable
      final slot900 = slots.firstWhere((s) => s.formattedTime == '9:00 AM');
      final slot930 = slots.firstWhere((s) => s.formattedTime == '9:30 AM');
      expect(slot900.isAvailable, false);
      expect(slot930.isAvailable, false);

      // 10:00 and 10:30 are during shift -> available
      final slot1000 = slots.firstWhere((s) => s.formattedTime == '10:00 AM');
      final slot1030 = slots.firstWhere((s) => s.formattedTime == '10:30 AM');
      expect(slot1000.isAvailable, true);
      expect(slot1030.isAvailable, true);

      // 12:00 and 12:30 are during lunch break (12:00 - 13:00) -> unavailable
      final slot1200 = slots.firstWhere((s) => s.formattedTime == '12:00 PM');
      final slot1230 = slots.firstWhere((s) => s.formattedTime == '12:30 PM');
      expect(slot1200.isAvailable, false);
      expect(slot1230.isAvailable, false);

      // 13:00 and 13:30 are after lunch break -> available
      final slot1300 = slots.firstWhere((s) => s.formattedTime == '1:00 PM');
      final slot1330 = slots.firstWhere((s) => s.formattedTime == '1:30 PM');
      expect(slot1300.isAvailable, true);
      expect(slot1330.isAvailable, true);

      // 15:00 and 15:30 are after shift ends (15:00) -> unavailable
      final slot1500 = slots.firstWhere((s) => s.formattedTime == '3:00 PM');
      final slot1530 = slots.firstWhere((s) => s.formattedTime == '3:30 PM');
      expect(slot1500.isAvailable, false);
      expect(slot1530.isAvailable, false);
    });

    test('marks all slots unavailable if practitioner is off duty on that day', () {
      final tuesdayClinic = Business(
        id: 'clinic-apex',
        ownerId: 'owner-1',
        name: 'Apex Dental Care',
        slug: 'apex-dental',
        category: 'dental',
        bookingModel: BookingModelType.slotBased,
        settings: {
          'slot_interval_minutes': 30,
          'working_hours': {
            'tuesday': {'open': '09:00', 'close': '17:00', 'is_open': true},
          },
        },
      );

      // Nov 10, 2026 is a Tuesday, which Dr. Vance has off
      final tuesday = DateTime(2026, 11, 10);

      final slots = SlotCalculator.calculateAvailableSlots(
        business: tuesdayClinic,
        date: tuesday,
        existingBookings: [],
        filterStaffId: drVance.id,
        staffMember: drVance,
      );

      expect(slots.isNotEmpty, true);
      expect(slots.every((s) => !s.isAvailable), true);
    });
  });

  group('StaffShiftEditorDialog & StaffManagerTab Widget Tests', () {
    late Business testBusiness;
    late BusinessStaff testStaff;

    setUp(() {
      testBusiness = Business(
        id: 'biz-test-shift',
        ownerId: 'owner-1',
        name: 'Harmony Wellness',
        slug: 'harmony-wellness',
        category: 'wellness',
        bookingModel: BookingModelType.slotBased,
      );

      testStaff = BusinessStaff(
        id: 'staff-editor-test',
        businessId: 'biz-test-shift',
        name: 'Elena Rostova',
        specialty: 'Acupuncture & Holistic Care',
        scheduleOverride: BusinessStaff.defaultSchedule(),
      );
    });

    testWidgets('StaffShiftEditorDialog renders 7 days and handles save', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StaffShiftEditorDialog(
                staff: testStaff,
                businessId: 'biz-test-shift',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check dialog header
      expect(find.text('Elena Rostova'), findsOneWidget);
      expect(find.text('Acupuncture & Holistic Care'), findsOneWidget);

      // Check toolbar actions
      expect(find.text('Copy Mon to Weekdays'), findsOneWidget);
      expect(find.text('Reset Default'), findsOneWidget);

      // Check days in matrix
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Tuesday'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);

      // Tap Copy Mon to Weekdays
      await tester.tap(find.text('Copy Mon to Weekdays'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Monday schedule copied'), findsOneWidget);

      // Tap Save Shift Schedule
      await tester.tap(find.text('Save Shift Schedule'));
      await tester.pumpAndSettle();
    });

    testWidgets('StaffManagerTab renders shift summary and opens editor dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            businessStaffProvider('biz-test-shift').overrideWith((ref) => [testStaff]),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StaffManagerTab(business: testBusiness),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Staff list title
      expect(find.text('Doctors & Specialists Roster'), findsOneWidget);
      expect(find.text('Elena Rostova'), findsOneWidget);

      // Check shift summary chip
      expect(find.textContaining('Mon–Fri: 09:00–17:00'), findsOneWidget);

      // Check "Edit Shifts" button exists and tap it
      final editBtn = find.text('Edit Shifts');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Verify StaffShiftEditorDialog is now visible
      expect(find.byType(StaffShiftEditorDialog), findsOneWidget);
      expect(find.text('Save Shift Schedule'), findsOneWidget);
    });
  });
}

// Transparent 1x1 PNG data for mock HTTP responses
final Uint8List _transparentPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

// Gene - Nov, 14, 2026: Complete HttpClientRequest/Headers/Response mock (including Stream & Nominatim JSON) to eliminate UnimplementedError console noise [QA-012]
/*
class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _MockHttpClientRequest();
  }

  @override
  void close({bool force = false}) {}
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentPng]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
*/
class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest(url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest(url);

  @override
  void close({bool force = false}) {}
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  final Uri url;
  _MockHttpClientRequest(this.url);

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  int contentLength = 0;

  @override
  bool persistentConnection = true;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool bufferOutput = true;

  @override
  void add(List<int> data) {}

  @override
  void write(Object? obj) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse(url);
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  final bool isJson;
  _MockHttpHeaders({this.isJson = false});

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void forEach(void Function(String name, List<String> values) action) {
    if (isJson) {
      action(HttpHeaders.contentTypeHeader, ['application/json; charset=utf-8']);
    }
  }
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final Uri url;
  late final List<int> _bodyBytes = _resolveMockBytes(url);
  late final bool _isJson = url.host.contains('nominatim');

  _MockHttpClientResponse(this.url);

  static List<int> _resolveMockBytes(Uri url) {
    if (url.host.contains('nominatim')) {
      if (url.path.contains('search')) {
        return utf8.encode(
          '[{"lat":"34.0736","lon":"-118.4004","display_name":"Beverly Hills, CA","address":{"city":"Beverly Hills","state":"CA"}}]',
        );
      }
      return utf8.encode(
        '{"lat":"34.0736","lon":"-118.4004","display_name":"Beverly Hills, CA","address":{"city":"Beverly Hills","state":"CA"}}',
      );
    }
    return _transparentPng;
  }

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => _bodyBytes.length;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => true;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  late final HttpHeaders headers = _MockHttpHeaders(isJson: _isJson);

  @override
  List<Cookie> get cookies => const [];

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followLoops]) =>
      Future.value(this);

  @override
  Future<Socket> detachSocket() => throw UnsupportedError('detachSocket');

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_bodyBytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
