// Gene - Nov 06, 2026: Comprehensive tests for Clients CRM, LTV aggregation, and Clinical Dossier Modal
import 'dart:async';
// Gene - Nov, 14, 2026: Added dart:convert for mock Nominatim geocoding JSON responses
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookit/models/booking.dart';
import 'package:bookit/models/client_crm_profile.dart';
import 'package:bookit/services/crm_service.dart';
import 'package:bookit/services/booking_service.dart';
import 'package:bookit/features/admin/presentation/tabs/clients_crm_tab.dart';
import 'package:bookit/features/admin/presentation/widgets/client_dossier_modal.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });
  group('CrmService Unit Tests', () {
    late CrmService crmService;
    final now = DateTime(2026, 11, 6, 10, 0);

    setUp(() {
      crmService = CrmService();
    });

    test('aggregates multiple bookings for same client into one unified profile', () {
      final bookings = [
        Booking(
          id: 'bk-1',
          businessId: 'biz-1',
          clientId: 'client-1',
          clientName: 'Sarah Jenkins',
          bookingModel: 'slot_based',
          startTime: now.subtract(const Duration(days: 10)),
          endTime: now.subtract(const Duration(days: 10, hours: -1)),
          status: 'completed',
          totalPrice: 150.0,
          clientNotes: 'Allergy to penicillin.',
          createdAt: now.subtract(const Duration(days: 12)),
        ),
        Booking(
          id: 'bk-2',
          businessId: 'biz-1',
          clientId: 'client-1',
          clientName: 'Sarah Jenkins',
          bookingModel: 'slot_based',
          startTime: now.subtract(const Duration(days: 2)),
          endTime: now.subtract(const Duration(days: 2, hours: -1)),
          status: 'completed',
          totalPrice: 220.0,
          createdAt: now.subtract(const Duration(days: 4)),
        ),
        Booking(
          id: 'bk-3',
          businessId: 'biz-1',
          clientId: 'client-2',
          clientName: 'Bob Smith',
          bookingModel: 'slot_based',
          startTime: now.subtract(const Duration(days: 1)),
          endTime: now.subtract(const Duration(days: 1, hours: -1)),
          status: 'no_show',
          totalPrice: 80.0,
          createdAt: now.subtract(const Duration(days: 3)),
        ),
      ];

      final profiles = crmService.aggregateClients(bookings);

      expect(profiles.length, 2);

      // Sarah Jenkins: total spend = 150 + 220 = 370 ($350+ = VIP)
      final sarah = profiles.firstWhere((p) => p.name == 'Sarah Jenkins');
      expect(sarah.totalSpend, 370.0);
      expect(sarah.totalVisits, 2);
      expect(sarah.noShowCount, 0);
      expect(sarah.statusTag, 'VIP');
      expect(sarah.medicalFlags.any((f) => f.contains('Allergy')), true);
      expect(sarah.appointmentHistory.length, 2);

      // Bob Smith: 1 no show
      final bob = profiles.firstWhere((p) => p.name == 'Bob Smith');
      expect(bob.totalSpend, 0.0);
      expect(bob.totalVisits, 0);
      expect(bob.noShowCount, 1);
      expect(bob.statusTag, 'New');
    });

    test('addInternalNote and addMedicalFlag persist in memory', () {
      crmService.addInternalNote('client-test', 'Patient requires wheelchair access.');
      crmService.addMedicalFlag('client-test', 'Asthma');

      final dummyBooking = Booking(
        id: 'bk-test',
        businessId: 'biz-1',
        clientId: 'client-test',
        clientName: 'Test Patient',
        bookingModel: 'slot_based',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        status: 'confirmed',
        totalPrice: 100.0,
        createdAt: now,
      );

      final profiles = crmService.aggregateClients([dummyBooking]);
      final profile = profiles.first;

      expect(profile.internalStaffNotes.any((n) => n.contains('wheelchair access')), true);
      expect(profile.medicalFlags.contains('Asthma'), true);
    });
  });

  group('ClientsCrmTab & ClientDossierModal Widget Tests', () {
    late List<Booking> sampleBookings;

    setUp(() {
      sampleBookings = [
        Booking(
          id: 'bk-10',
          businessId: 'biz-crm',
          clientId: 'client-10',
          clientName: 'Dr. John Doe',
          bookingModel: 'slot_based',
          startTime: DateTime.now().subtract(const Duration(days: 5)),
          endTime: DateTime.now().subtract(const Duration(days: 5, hours: -1)),
          status: 'completed',
          totalPrice: 400.0,
          clientNotes: 'Severe latex allergy.',
          createdAt: DateTime.now().subtract(const Duration(days: 6)),
        ),
        Booking(
          id: 'bk-20',
          businessId: 'biz-crm',
          clientId: 'client-20',
          clientName: 'Emma Watson',
          bookingModel: 'slot_based',
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          endTime: DateTime.now().subtract(const Duration(days: 1, hours: -1)),
          status: 'confirmed',
          totalPrice: 120.0,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
    });

    testWidgets('ClientsCrmTab renders KPI summary cards and client table', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingsProvider.overrideWith((ref) => BookingNotifier()..state = sampleBookings),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ClientsCrmTab(businessId: 'biz-crm'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Header
      expect(find.text('Patients & Clients Directory'), findsOneWidget);

      // Check KPI Cards
      expect(find.text('Total Patients'), findsOneWidget);
      expect(find.text('Returning Rate'), findsOneWidget);
      expect(find.text('Average Patient LTV'), findsOneWidget);
      expect(find.text('VIP Patients'), findsOneWidget);

      // Check table entries
      expect(find.text('Dr. John Doe'), findsOneWidget);
      expect(find.text('Emma Watson'), findsOneWidget);
      expect(find.text('VIP'), findsNWidgets(2)); // in filter chip and table tag
      expect(find.text('New'), findsNWidgets(2)); // in filter chip and table tag
    });

    testWidgets('ClientsCrmTab filters clients via search input', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingsProvider.overrideWith((ref) => BookingNotifier()..state = sampleBookings),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ClientsCrmTab(businessId: 'biz-crm'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query "Emma"
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Emma');
      await tester.pumpAndSettle();

      // "Emma Watson" should be visible, "Dr. John Doe" should be filtered out
      expect(find.text('Emma Watson'), findsOneWidget);
      expect(find.text('Dr. John Doe'), findsNothing);
    });

    testWidgets('ClientDossierModal renders patient profile, medical flags, and handles note addition', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));

      final clientProfile = ClientCrmProfile(
        id: 'client-10',
        name: 'Dr. John Doe',
        email: 'john.doe@example.com',
        phone: '+1 (555) 019-1234',
        totalSpend: 400.0,
        totalVisits: 1,
        noShowCount: 0,
        firstVisit: DateTime.now().subtract(const Duration(days: 5)),
        lastVisit: DateTime.now().subtract(const Duration(days: 5)),
        statusTag: 'VIP',
        medicalFlags: ['Severe latex allergy', 'Penicillin Allergy'],
        internalStaffNotes: ['Patient requires extra numbing agent.'],
        appointmentHistory: [sampleBookings.first],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ClientDossierModal(
                client: clientProfile,
                businessId: 'biz-crm',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Profile details
      expect(find.text('Dr. John Doe'), findsOneWidget);
      expect(find.textContaining('john.doe@example.com'), findsOneWidget);
      expect(find.text('VIP'), findsOneWidget);

      // Medical flags
      expect(find.text('Severe latex allergy'), findsOneWidget);
      expect(find.text('Penicillin Allergy'), findsOneWidget);

      // Existing notes
      expect(find.text('Patient requires extra numbing agent.'), findsOneWidget);

      // Tap "Add Note" button
      final addNoteBtn = find.text('Add Note');
      expect(addNoteBtn, findsOneWidget);
      await tester.tap(addNoteBtn);
      await tester.pumpAndSettle();

      // Enter note in dialog
      expect(find.text('Add Clinical / Internal Note'), findsOneWidget);
      final noteField = find.byType(TextField);
      await tester.enterText(noteField, 'Follow-up call completed with patient.');
      await tester.pumpAndSettle();

      // Save note
      await tester.tap(find.text('Save Note'));
      await tester.pumpAndSettle();

      // Check note appears in dossier
      expect(find.textContaining('Follow-up call completed with patient.'), findsOneWidget);
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
