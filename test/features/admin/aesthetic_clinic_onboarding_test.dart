// Gene - Nov 06, 2026: Comprehensive tests for Aesthetic & Dermatology Clinic onboarding template and dynamic clinical intake engine
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bookit/models/business.dart';
import 'package:bookit/models/service_item.dart';
import 'package:bookit/services/business_service.dart';
import 'package:bookit/features/admin/presentation/widgets/admin_onboarding_wizard.dart';
import 'package:bookit/features/booking_engine/presentation/steps/client_intake_step.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('Aesthetic & Dermatology Clinic Template Seed Tests', () {
    test('getTemplates returns aesthetic-dermatology template with clinical configuration', () async {
      final service = BusinessService();
      final templates = await service.getTemplates();

      final aestheticTpl = templates.firstWhere((t) => t.slug == 'aesthetic-dermatology');
      expect(aestheticTpl.name, 'Aesthetic & Dermatology Clinic');
      expect(aestheticTpl.slug, 'aesthetic-dermatology');
      expect(aestheticTpl.categoryId, 'c0000001-0000-0000-0000-000000000001');
      expect(aestheticTpl.bookingModel, BookingModelType.slotBased);

      // Verify Clinic Scheduling & Deposit Settings
      expect(aestheticTpl.defaultSettings['deposit_percent'], 30.0);
      expect(aestheticTpl.defaultSettings['cancellation_window_hours'], 48);
      expect(aestheticTpl.defaultSettings['numbing_buffer_minutes'], 20);
      expect(aestheticTpl.defaultSettings['slot_interval_minutes'], 15);
      expect(aestheticTpl.defaultSettings['buffer_minutes'], 15);

      // Verify Starter Services (8 treatments)
      expect(aestheticTpl.starterServices.length, 8);
      final serviceNames = aestheticTpl.starterServices.map((s) => s['name']).toList();
      expect(serviceNames.any((n) => n.contains('Botox / Dysport')), isTrue);
      expect(serviceNames.any((n) => n.contains('Juvederm / Restylane')), isTrue);
      expect(serviceNames.any((n) => n.contains('Lip Augmentation')), isTrue);
      expect(serviceNames.any((n) => n.contains('Candela GentleMax Pro')), isTrue);
      expect(serviceNames.any((n) => n.contains('PicoWay Pigmentation')), isTrue);
      expect(serviceNames.any((n) => n.contains('Morpheus8 RF Microneedling')), isTrue);
      expect(serviceNames.any((n) => n.contains('Deluxe Medical Hydrafacial')), isTrue);
      expect(serviceNames.any((n) => n.contains('TCA Jessner Medium Skin Rejuvenation Peel')), isTrue);

      // Verify 30% deposit calculation in starter services
      final morpheusService = aestheticTpl.starterServices.firstWhere((s) => s['name'].toString().contains('Morpheus8'));
      expect(morpheusService['price'], 950.00);
      expect(morpheusService['deposit_amount'], 285.00);
      expect(morpheusService['payment_policy'], 'deposit_required');

      // Verify Starter Staff Roles (3 clinicians)
      expect(aestheticTpl.starterStaffRoles.length, 3);
      expect(aestheticTpl.starterStaffRoles[0], contains('Dr. Alexander Vance'));
      expect(aestheticTpl.starterStaffRoles[1], contains('Sarah Jenkins'));
      expect(aestheticTpl.starterStaffRoles[2], contains('Elena Rostova'));

      // Verify UI Config & Clinical Intake Fields
      expect(aestheticTpl.uiConfig['resource_type'], 'person_and_room_and_device');
      expect(aestheticTpl.uiConfig['resource_label'], 'Medical Practitioner');
      expect(aestheticTpl.uiConfig['service_label'], 'Aesthetic Treatment');

      final intakeFields = (aestheticTpl.uiConfig['intake_fields'] as List);
      expect(intakeFields.length, 6);

      // 1. Fitzpatrick Skin Type (select)
      final fitzpatrick = intakeFields.firstWhere((f) => f['id'] == 'fitzpatrick_scale');
      expect(fitzpatrick['type'], 'select');
      expect((fitzpatrick['options'] as List).length, 6);
      expect((fitzpatrick['options'] as List).first, contains('Type I'));

      // 2. Accutane (blocking boolean)
      final accutane = intakeFields.firstWhere((f) => f['id'] == 'accutane_history');
      expect(accutane['type'], 'boolean');
      expect(accutane['blocking_condition'], isTrue);
      expect(accutane['blocking_message'], contains('cannot be administered within 6 months'));

      // 3. Blood thinners (helper text boolean)
      final bloodThinners = intakeFields.firstWhere((f) => f['id'] == 'blood_thinners_nsaids');
      expect(bloodThinners['type'], 'boolean');
      expect(bloodThinners['helper_text'], contains('bruising'));

      // 4. Pregnancy (blocking boolean)
      final pregnancy = intakeFields.firstWhere((f) => f['id'] == 'pregnancy_lactation');
      expect(pregnancy['type'], 'boolean');
      expect(pregnancy['blocking_condition'], isTrue);

      // 5. Cold sores (helper text)
      final coldSores = intakeFields.firstWhere((f) => f['id'] == 'hsv_cold_sores');
      expect(coldSores['helper_text'], contains('antiviral'));

      // 6. Photo consent (required)
      final consent = intakeFields.firstWhere((f) => f['id'] == 'clinical_photo_consent');
      expect(consent['required'], isTrue);
    });
  });

  group('AdminOnboardingWizard Aesthetic Clinic Journey', () {
    testWidgets('Wizard configures Aesthetic Clinic with 8 services and 3 staff roles', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 950));

      bool onboardingCompleted = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: AdminOnboardingWizard(
                  onCompleted: () {
                    onboardingCompleted = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 of 4: Select Aesthetic Clinic Template
      expect(find.text('Business Onboarding & Setup'), findsOneWidget);
      expect(find.text('Step 1 of 4: Choose Industry Template'), findsOneWidget);
      expect(find.text('Aesthetic & Dermatology Clinic'), findsOneWidget);

      await tester.tap(find.text('Aesthetic & Dermatology Clinic'));
      await tester.pumpAndSettle();

      // Tap Continue -> Step 2 of 4: Business Information
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 4: Business Information'), findsOneWidget);
      expect(find.text('Business Name *'), findsOneWidget);
      expect(find.text('Slug (URL Handle)'), findsOneWidget);

      // Enter business name
      await tester.enterText(find.byType(TextField).first, 'Luxe Aesthetic Clinic');
      await tester.pumpAndSettle();

      // Tap Continue -> Step 3 of 4: Review Starter Catalog
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Review Starter Catalog
      expect(find.text('Step 3 of 4: Review Starter Catalog'), findsOneWidget);
      expect(find.text('Starter Service Catalog & Resource Roles'), findsOneWidget);
      expect(find.text('Botox / Dysport Wrinkle Relaxer'), findsOneWidget);
      expect(find.text('Juvederm / Restylane Dermal Filler'), findsOneWidget);

      // Scroll to verify services further down the list
      final morpheusFinder = find.text('Morpheus8 RF Microneedling (Face & Neck)');
      await tester.scrollUntilVisible(morpheusFinder, 100);
      expect(morpheusFinder, findsOneWidget);

      // Verify starter staff role titles preview in Step 3
      expect(find.textContaining('Dr. Alexander Vance'), findsOneWidget);
      expect(find.textContaining('Sarah Jenkins'), findsOneWidget);

      // Tap Continue -> Step 4 of 4: Schedule & Launch
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: Schedule & Launch
      expect(find.text('Step 4 of 4: Schedule & Launch'), findsOneWidget);
      expect(find.text('Ready to Launch Luxe Aesthetic Clinic!'), findsOneWidget);
      expect(find.text('6 custom intake questions'), findsOneWidget);
      expect(find.text('Launch Business'), findsOneWidget);

      // Tap Launch Business
      await tester.tap(find.text('Launch Business'));
      await tester.pumpAndSettle();

      expect(onboardingCompleted, isTrue);

      await tester.binding.setSurfaceSize(null);
    });
  });

  group('ClientIntakeStep Clinical Pre-screening Engine', () {
    final aestheticBiz = Business(
      id: 'biz-aesthetic-test',
      ownerId: 'owner-test',
      name: 'Luxe Derm & Aesthetics',
      slug: 'luxe-derm',
      category: 'aesthetic-dermatology',
      bookingModel: BookingModelType.slotBased,
      uiConfig: const {
        'resource_type': 'person_and_room_and_device',
        'resource_label': 'Medical Practitioner',
        'service_label': 'Aesthetic Treatment',
        'intake_fields': [
          {
            'id': 'fitzpatrick_scale',
            'label': 'Fitzpatrick Skin Type',
            'type': 'select',
            'required': true,
            'options': [
              'Type I - Always burns, never tans',
              'Type II - Usually burns, tans with difficulty',
              'Type III - Sometimes mild burn, gradually tans',
              'Type IV - Rarely burns, tans with ease',
              'Type V - Very rarely burns, tans very easily',
              'Type VI - Never burns, deeply pigmented'
            ]
          },
          {
            'id': 'accutane_history',
            'label': 'Used oral Isotretinoin (Accutane) within the past 6 months?',
            'type': 'boolean',
            'required': true,
            'blocking_condition': true,
            'blocking_message': 'Laser, RF microneedling, and chemical peels cannot be administered within 6 months of Accutane therapy due to scarring risks.'
          },
          {
            'id': 'blood_thinners_nsaids',
            'label': 'Currently taking blood thinners, Aspirin, Ibuprofen, or high-dose Fish Oil?',
            'type': 'boolean',
            'required': true,
            'helper_text': 'May increase injection-site bruising.'
          },
          {
            'id': 'pregnancy_lactation',
            'label': 'Currently pregnant, planning pregnancy, or breastfeeding?',
            'type': 'boolean',
            'required': true,
            'blocking_condition': true,
            'blocking_message': 'Cosmetic injectables and laser treatments are contraindicated during pregnancy and breastfeeding.'
          },
          {
            'id': 'hsv_cold_sores',
            'label': 'History of oral facial cold sores (HSV-1)?',
            'type': 'boolean',
            'required': false,
            'helper_text': 'If having lip filler or perioral laser, prophylactic antiviral medication is recommended.'
          },
          {
            'id': 'clinical_photo_consent',
            'label': 'I consent to pre- and post-treatment photographic documentation for my clinical record',
            'type': 'boolean',
            'required': true
          }
        ],
      },
    );

    final morpheusService = ServiceItem(
      id: 'srv-morpheus-test',
      businessId: 'biz-aesthetic-test',
      name: 'Morpheus8 RF Microneedling (Face & Neck)',
      durationMinutes: 75,
      price: 950.0,
      paymentPolicy: 'deposit_required',
      depositAmount: 285.0,
    );

    testWidgets('ClientIntakeStep renders Fitzpatrick dropdown and formats selection into notes', (tester) async {
      String recordedNotes = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClientIntakeStep(
                business: aestheticBiz,
                service: morpheusService,
                initialNotes: '',
                onNotesChanged: (notes) {
                  recordedNotes = notes;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dynamic header check
      expect(find.text('Aesthetic Treatment Intake & Requirements'), findsOneWidget);

      // Verify Fitzpatrick dropdown is present
      expect(find.text('Fitzpatrick Skin Type *'), findsOneWidget);
      expect(find.text('Type I - Always burns, never tans'), findsOneWidget);

      // Change dropdown to Type IV
      await tester.tap(find.text('Type I - Always burns, never tans'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Type IV - Rarely burns, tans with ease').last);
      await tester.pumpAndSettle();

      expect(recordedNotes, contains('Fitzpatrick Skin Type: Type IV - Rarely burns, tans with ease'));
    });

    testWidgets('ClientIntakeStep displays contraindication warning banner when Accutane is selected', (tester) async {
      String recordedNotes = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClientIntakeStep(
                business: aestheticBiz,
                service: morpheusService,
                initialNotes: '',
                onNotesChanged: (notes) {
                  recordedNotes = notes;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Contraindication banner should not be visible before toggle
      expect(find.textContaining('cannot be administered within 6 months of Accutane'), findsNothing);

      // Find the Accutane switch (first switch among booleans)
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(5)); // 5 boolean switches

      // Toggle Accutane switch (index 0)
      await tester.tap(switches.at(0));
      await tester.pumpAndSettle();

      // Verify contraindication banner appears
      expect(find.textContaining('cannot be administered within 6 months of Accutane'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
      expect(recordedNotes, contains('Used oral Isotretinoin (Accutane) within the past 6 months?: Yes'));
    });

    testWidgets('ClientIntakeStep displays contraindication warning banner when Pregnancy is selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClientIntakeStep(
                business: aestheticBiz,
                service: morpheusService,
                initialNotes: '',
                onNotesChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Cosmetic injectables and laser treatments are contraindicated'), findsNothing);

      final switches = find.byType(Switch);
      // Pregnancy is index 2 among the boolean switches (0: Accutane, 1: Blood thinners, 2: Pregnancy)
      await tester.tap(switches.at(2));
      await tester.pumpAndSettle();

      expect(find.textContaining('Cosmetic injectables and laser treatments are contraindicated'), findsOneWidget);
    });

    testWidgets('ClientIntakeStep renders clinical helper text for blood thinners and HSV-1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClientIntakeStep(
                business: aestheticBiz,
                service: morpheusService,
                initialNotes: '',
                onNotesChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('May increase injection-site bruising.'), findsOneWidget);
      expect(find.text('If having lip filler or perioral laser, prophylactic antiviral medication is recommended.'), findsOneWidget);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _TestHttpClient();
}

class _TestHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  String? userAgent;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
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
  int contentLength = 0;
  @override
  bool persistentConnection = true;
  @override
  void add(List<int> data) {}
  @override
  void write(Object? obj) {}
  @override
  Future addStream(Stream<List<int>> stream) async => null;
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

final List<int> _jsonBytes = utf8.encode('{"display_name": "San Francisco, CA", "address": {"city": "San Francisco"}}');

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _jsonBytes.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_jsonBytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
