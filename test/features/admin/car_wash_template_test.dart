// Gene - Nov, 15, 2026: Unit, widget, and onboarding lifecycle tests for the Express & Full-Service Car Wash template
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bookit/models/booking.dart';
import 'package:bookit/models/business.dart';
import 'package:bookit/models/business_staff.dart';
import 'package:bookit/models/service_item.dart';
import 'package:bookit/services/business_service.dart';
import 'package:bookit/services/supabase_service.dart';
import 'package:bookit/features/admin/presentation/widgets/admin_onboarding_wizard.dart';
import 'package:bookit/features/booking_engine/domain/slot_calculator.dart';
import 'package:bookit/features/booking_engine/presentation/steps/client_intake_step.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    SupabaseService.resetToDefaultData();
  });

  group('Express & Full-Service Car Wash Template & Demo Storefront', () {
    test('BusinessService exposes Automotive & Detailing category and Express Car Wash template', () async {
      final service = BusinessService();
      final categories = await service.getCategories();

      expect(categories.any((c) => c.id == 'c0000007-0000-0000-0000-000000000007'), isTrue);
      expect(categories.any((c) => c.name == 'Automotive & Detailing'), isTrue);

      final autoTemplates = await service.getTemplates(
        categoryId: 'c0000007-0000-0000-0000-000000000007',
      );
      expect(autoTemplates.any((t) => t.slug == 'auto-detailing-car-wash'), isTrue);
      expect(autoTemplates.any((t) => t.slug == 'express-car-wash'), isTrue);

      final washTpl = autoTemplates.firstWhere((t) => t.slug == 'express-car-wash');
      expect(washTpl.name, 'Express & Full-Service Car Wash');
      expect(washTpl.bookingModel, BookingModelType.slotBased);
      expect(washTpl.defaultSettings['slot_interval_minutes'], 15);
      expect(washTpl.defaultSettings['buffer_minutes'], 5);
      expect(washTpl.resourceType, 'wash_bay');
      expect(washTpl.resourceLabel, 'Wash Bay');
      expect(washTpl.serviceLabel, 'Car Wash Package');
      expect(washTpl.showStaffSelection, isTrue);
      expect(washTpl.starterServices.length, 7);
      expect(washTpl.starterStaffRoles.length, 3);
      expect(washTpl.intakeFields.length, 6);
    });

    test('Discovery filters return SplashWave Express Car Wash demo storefront with bays and wash packages', () async {
      final service = BusinessService();

      final byCategory = await service.getBusinesses(category: 'Automotive & Detailing');
      expect(byCategory.any((b) => b.name == 'SplashWave Express Car Wash & Auto Spa'), isTrue);

      final byQuery = await service.getBusinesses(query: 'SplashWave');
      expect(byQuery.length, 1);
      final storefront = byQuery.first;
      expect(storefront.resourceLabel, 'Wash Bay');
      expect(storefront.serviceLabel, 'Car Wash Package');

      final bays = await service.getStaff(storefront.id);
      expect(bays.length, 3);
      expect(bays.any((b) => b.name == 'Wash Bay 1'), isTrue);

      final packages = await service.getServices(storefront.id);
      expect(packages.length, 4);
      expect(packages.any((s) => s.name == 'Express Exterior Snow Foam & Dry'), isTrue);
      expect(packages.any((s) => s.name == 'Full-Service Inside & Out Car Wash'), isTrue);
    });
  });

  group('AdminOnboardingWizard Express Car Wash Journey', () {
    testWidgets('Wizard provisions Express & Full-Service Car Wash business end-to-end', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 950));
      bool completed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: AdminOnboardingWizard(
                  onCompleted: () => completed = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll and tap Automotive & Detailing category chip
      final autoCatFinder = find.text('Automotive & Detailing');
      await tester.ensureVisible(autoCatFinder);
      await tester.pumpAndSettle();
      await tester.tap(autoCatFinder);
      await tester.pumpAndSettle();

      // Select Express & Full-Service Car Wash template
      expect(find.text('Express & Full-Service Car Wash'), findsOneWidget);
      await tester.tap(find.text('Express & Full-Service Car Wash'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Business Name
      await tester.enterText(find.byType(TextField).first, 'Tidal Wave Car Wash');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Starter catalog & wash bays verification
      expect(find.text('Starter Service Catalog & Resource Roles'), findsOneWidget);
      expect(find.text('Express Exterior Snow Foam & Dry'), findsOneWidget);
      expect(find.textContaining('Wash Bay 1 (Express Snow Foam & Exterior)'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: Launch
      expect(find.text('Ready to Launch Tidal Wave Car Wash!'), findsOneWidget);
      await tester.tap(find.text('Launch Business'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);

      final businesses = await BusinessService().getBusinesses(query: 'Tidal Wave Car Wash');
      expect(businesses.any((b) => b.name == 'Tidal Wave Car Wash' && b.resourceLabel == 'Wash Bay'), isTrue);

      await tester.binding.setSurfaceSize(null);
    });
  });

  group('ClientIntakeStep Car Wash Vehicle Intake & Clearance Guardrail', () {
    testWidgets('Captures vehicle plate, add-on chips, signed waiver, and triggers 7ft clearance blocker', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));

      final washTpl = SupabaseService.mockTemplates.firstWhere((t) => t.slug == 'express-car-wash');
      final washBiz = Business(
        id: 'biz-carwash-intake-test',
        ownerId: 'owner-1',
        templateId: washTpl.id,
        name: 'Tidal Wave Car Wash',
        slug: 'tidal-wave-car-wash',
        category: washTpl.slug,
        bookingModel: washTpl.bookingModel,
        settings: washTpl.defaultSettings,
        uiConfig: washTpl.uiConfig,
      );
      const washPackage = ServiceItem(
        id: 'srv-wash-1',
        businessId: 'biz-carwash-intake-test',
        name: 'Full-Service Inside & Out Car Wash',
        durationMinutes: 35,
        price: 32.0,
      );

      String latestNotes = '';
      bool? latestBlocker;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ClientIntakeStep(
                business: washBiz,
                service: washPackage,
                initialNotes: '',
                onNotesChanged: (notes) => latestNotes = notes,
                onBlockerChanged: (blocked) => latestBlocker = blocked,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Car Wash Package Intake & Requirements'), findsOneWidget);

      // Enter license plate & vehicle model
      await tester.enterText(find.byType(TextField).first, '8CAR999 • White Civic');
      await tester.pumpAndSettle();

      // Toggle express add-on chip
      final addonFinder = find.text('Hydrophobic Rain-Repellent Glass Coat');
      await tester.ensureVisible(addonFinder);
      await tester.tap(addonFinder);
      await tester.pumpAndSettle();

      // Toggle 7-ft clearance blocker switch ON (first Switch in form)
      final clearanceSwitch = find.byType(Switch).first;
      await tester.ensureVisible(clearanceSwitch);
      await tester.tap(clearanceSwitch);
      await tester.pumpAndSettle();

      expect(latestBlocker, isTrue);
      expect(
        find.textContaining('Vehicles over 7 ft clearance or carrying loose roof/bed cargo'),
        findsOneWidget,
      );

      // Sign valuables & inspection waiver checkbox
      final waiverCheckbox = find.byType(Checkbox).first;
      await tester.ensureVisible(waiverCheckbox);
      await tester.tap(waiverCheckbox);
      await tester.pumpAndSettle();

      expect(latestNotes, contains('Sedan / Coupe / Hatchback'));
      expect(latestNotes, contains('8CAR999'));
      expect(latestNotes, contains('Hydrophobic Rain-Repellent Glass Coat'));
      expect(latestNotes, contains('Acknowledged & Signed'));

      await tester.binding.setSurfaceSize(null);
    });
  });

  group('SlotCalculator 15-Minute Wash Bay Turnover', () {
    test('Generates 15-minute intervals and enforces 5-minute wash bay turnover buffer', () {
      final washTpl = SupabaseService.mockTemplates.firstWhere((t) => t.slug == 'express-car-wash');
      final washBiz = Business(
        id: 'biz-carwash-slot-test',
        ownerId: 'owner-1',
        templateId: washTpl.id,
        name: 'Tidal Wave Car Wash',
        slug: 'tidal-wave-car-wash',
        category: washTpl.slug,
        bookingModel: washTpl.bookingModel,
        settings: washTpl.defaultSettings,
        uiConfig: washTpl.uiConfig,
      );

      const bay1 = BusinessStaff(
        id: 'bay-1',
        businessId: 'biz-carwash-slot-test',
        name: 'Wash Bay 1',
      );

      final testDate = DateTime(2026, 11, 16); // Monday (07:00 - 20:00)
      final existingBookings = [
        Booking(
          id: 'bk-wash-1',
          businessId: 'biz-carwash-slot-test',
          clientId: 'client-1',
          serviceId: 'srv-wash-2',
          staffId: 'bay-1',
          bookingModel: 'slot_based',
          startTime: DateTime(2026, 11, 16, 9, 0),
          endTime: DateTime(2026, 11, 16, 9, 35),
          status: 'confirmed',
          totalPrice: 32.0,
          createdAt: DateTime(2026, 11, 15),
        ),
      ];

      final slots = SlotCalculator.calculateAvailableSlots(
        business: washBiz,
        date: testDate,
        existingBookings: existingBookings,
        customDurationMinutes: 35,
        filterStaffId: 'bay-1',
        staffMember: bay1,
      );

      expect(slots.isNotEmpty, isTrue);
      expect(slots[0].startTime, DateTime(2026, 11, 16, 7, 0));
      expect(slots[1].startTime, DateTime(2026, 11, 16, 7, 15));
      expect(slots.every((s) => s.endTime.difference(s.startTime).inMinutes == 35), isTrue);

      // 09:00-09:35 + 5 min turnover buffer blocks until 09:40 -> 09:30 unavailable, 09:45 available
      final slot0930 = slots.firstWhere((s) => s.startTime == DateTime(2026, 11, 16, 9, 30));
      final slot0945 = slots.firstWhere((s) => s.startTime == DateTime(2026, 11, 16, 9, 45));
      expect(slot0930.isAvailable, isFalse);
      expect(slot0945.isAvailable, isTrue);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;
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
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  int contentLength = 0;
  @override
  bool persistentConnection = true;
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

final List<int> _jsonBytes = utf8.encode(
  '{"lat":"37.7825","lon":"-122.3965","display_name":"San Francisco, CA","address":{"city":"San Francisco","state":"CA"}}',
);
final List<int> _searchJsonBytes = utf8.encode(
  '[{"lat":"37.7825","lon":"-122.3965","display_name":"San Francisco, CA","address":{"city":"San Francisco","state":"CA"}}]',
);
const _transparentPngBytes = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final Uri url;
  late final bool _isJson = url.host.contains('nominatim');
  late final List<int> _bodyBytes = _isJson
      ? (url.path.contains('search') ? _searchJsonBytes : _jsonBytes)
      : _transparentPngBytes;

  _MockHttpClientResponse(this.url);

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
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followLoops]) => Future.value(this);
  @override
  Future<Socket> detachSocket() => throw UnsupportedError('detachSocket');
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_bodyBytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
