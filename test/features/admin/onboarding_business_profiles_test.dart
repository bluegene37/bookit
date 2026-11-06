// Gene - Nov 06, 2026: Comprehensive tests for all 5 SaaS Onboarding Configuration Templates (Aesthetic, Day Spa, Hair Salon, Dental, Fitness)
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

  group('Master Template Seed Verification Across All 5 Verticals', () {
    test('BusinessService provides complete, production-ready configuration for all 5 business profiles', () async {
      final service = BusinessService();
      final templates = await service.getTemplates();

      // 1. Aesthetic Clinic
      final aesthetic = templates.firstWhere((t) => t.slug == 'aesthetic-dermatology');
      expect(aesthetic.name, 'Aesthetic & Dermatology Clinic');
      expect(aesthetic.starterServices.length, 8);
      expect(aesthetic.starterStaffRoles.length, 3);
      expect((aesthetic.uiConfig['intake_fields'] as List).length, 6);
      expect(aesthetic.defaultSettings['deposit_percent'], 30.0);
      expect(aesthetic.defaultSettings['cancellation_window_hours'], 48);

      // 2. Day Spa & Massage Center
      final daySpa = templates.firstWhere((t) => t.slug == 'day-spa-massage');
      expect(daySpa.name, 'Day Spa & Massage Center');
      expect(daySpa.starterServices.length, 9);
      expect(daySpa.starterStaffRoles.length, 3);
      expect((daySpa.uiConfig['intake_fields'] as List).length, 5);
      expect(daySpa.defaultSettings['deposit_percent'], 25.0);
      expect(daySpa.defaultSettings['buffer_minutes'], 15);
      expect(daySpa.defaultSettings['early_arrival_minutes'], 15);
      final spaServiceNames = daySpa.starterServices.map((s) => s['name'].toString()).toList();
      expect(spaServiceNames.any((n) => n.contains('Basalt Heated Stone')), isTrue);
      expect(spaServiceNames.any((n) => n.contains('Presidential Romance Duet')), isTrue);
      expect(spaServiceNames.any((n) => n.contains('Infrared Sauna')), isTrue);

      // 3. Hair & Beauty Salon
      final hairSalon = templates.firstWhere((t) => t.slug == 'hair-beauty-salon');
      expect(hairSalon.name, 'Hair & Beauty Salon');
      expect(hairSalon.starterServices.length, 8);
      expect(hairSalon.starterStaffRoles.length, 3);
      expect((hairSalon.uiConfig['intake_fields'] as List).length, 4);
      expect(hairSalon.defaultSettings['deposit_percent'], 25.0);
      expect(hairSalon.defaultSettings['cancellation_window_hours'], 48);
      final hairServiceNames = hairSalon.starterServices.map((s) => s['name'].toString()).toList();
      expect(hairServiceNames.any((n) => n.contains('Balayage')), isTrue);
      expect(hairServiceNames.any((n) => n.contains('Brazilian Keratin')), isTrue);
      expect(hairServiceNames.any((n) => n.contains('Russian Volume Lash')), isTrue);

      // 4. Dental Practice
      final dental = templates.firstWhere((t) => t.slug == 'dental-clinic');
      expect(dental.name, 'Dental Care Clinic');
      expect(dental.starterServices.length, 9);
      expect(dental.starterStaffRoles.length, 3);
      expect((dental.uiConfig['intake_fields'] as List).length, 6);
      expect(dental.defaultSettings['advance_booking_days'], 180);
      final dentalServiceNames = dental.starterServices.map((s) => s['name'].toString()).toList();
      expect(dentalServiceNames.any((n) => n.contains('CEREC')), isTrue);
      expect(dentalServiceNames.any((n) => n.contains('Philips Zoom!')), isTrue);
      expect(dentalServiceNames.any((n) => n.contains('Invisalign')), isTrue);

      // 5. Boutique Fitness Studio & Yoga
      final fitness = templates.firstWhere((t) => t.slug == 'fitness-pilates-yoga');
      expect(fitness.name, 'Boutique Fitness Studio & Yoga');
      expect(fitness.starterServices.length, 7);
      expect(fitness.starterStaffRoles.length, 3);
      expect((fitness.uiConfig['intake_fields'] as List).length, 5);
      expect(fitness.defaultSettings['deposit_percent'], 100.0);
      expect(fitness.defaultSettings['cancellation_window_hours'], 12);
      final fitnessServiceNames = fitness.starterServices.map((s) => s['name'].toString()).toList();
      expect(fitnessServiceNames.any((n) => n.contains('Reformer Flow')), isTrue);
      expect(fitnessServiceNames.any((n) => n.contains('Infrared Candlelight Vinyasa')), isTrue);
      expect(fitnessServiceNames.any((n) => n.contains('Jumpboard Cardio')), isTrue);
    });
  });

  group('AdminOnboardingWizard Multi-Vertical Setup Journeys', () {
    testWidgets('Wizard configures Day Spa & Massage Center with couples packages', (tester) async {
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

      // Filter by Beauty & Personal Care category
      final beautyCatFinder = find.text('Beauty & Personal Care');
      await tester.ensureVisible(beautyCatFinder);
      await tester.pumpAndSettle();
      await tester.tap(beautyCatFinder);
      await tester.pumpAndSettle();

      // Step 1: Select Day Spa template
      expect(find.text('Day Spa & Massage Center'), findsOneWidget);
      await tester.tap(find.text('Day Spa & Massage Center'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Enter Name
      await tester.enterText(find.byType(TextField).first, 'Serenity Lotus Sanctuary');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Catalog verification
      expect(find.text('Starter Service Catalog & Resource Roles'), findsOneWidget);
      expect(find.text('Deep Tissue Neuromuscular Massage (60 min)'), findsOneWidget);
      expect(find.textContaining('Maya Lin, LMT'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: Launch
      expect(find.text('Ready to Launch Serenity Lotus Sanctuary!'), findsOneWidget);
      await tester.tap(find.text('Launch Business'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Wizard configures Hair & Beauty Salon with Balayage and Lash extensions', (tester) async {
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

      // Filter by Beauty & Personal Care category
      final beautyCatFinder = find.text('Beauty & Personal Care');
      await tester.ensureVisible(beautyCatFinder);
      await tester.pumpAndSettle();
      await tester.tap(beautyCatFinder);
      await tester.pumpAndSettle();

      // Select Hair Salon template
      expect(find.text('Hair & Beauty Salon'), findsOneWidget);
      await tester.tap(find.text('Hair & Beauty Salon'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Maison de Beauté');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Lived-In Signature Balayage & Glaze'), findsOneWidget);
      expect(find.textContaining('Julian Voss'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Launch Business'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Wizard configures Boutique Fitness Studio with Reformer Pilates and Yoga', (tester) async {
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

      // Filter by Fitness & Coaching category
      final fitnessCatFinder = find.text('Fitness & Coaching');
      await tester.ensureVisible(fitnessCatFinder);
      await tester.pumpAndSettle();
      await tester.tap(fitnessCatFinder);
      await tester.pumpAndSettle();

      expect(find.text('Boutique Fitness Studio & Yoga'), findsOneWidget);
      await tester.tap(find.text('Boutique Fitness Studio & Yoga'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Core & Sanctuary Reformer');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Signature Reformer Flow (All Levels)'), findsOneWidget);
      expect(find.textContaining('Maya Sterling'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Launch Business'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('ClientIntakeStep Multi-Vertical Specialized Fields', () {
    testWidgets('Day Spa intake handles pressure select, multiselect focus chips, and soundscapes', (tester) async {
      String visitNotes = '';
      final spaBiz = Business(
        id: 'biz-spa-test',
        ownerId: 'owner-test',
        name: 'Lotus Day Retreat',
        slug: 'lotus-spa',
        category: 'day-spa-massage',
        bookingModel: BookingModelType.slotBased,
        uiConfig: const {
          'resource_type': 'massage_therapist_and_treatment_room',
          'resource_label': 'Licensed Massage Therapist',
          'service_label': 'Spa Ritual',
          'intake_fields': [
            {
              'id': 'desired_pressure',
              'label': 'Preferred Massage Pressure',
              'type': 'select',
              'required': true,
              'options': [
                'Light - Gentle flowing relaxation',
                'Medium - Balanced stress relief and tension release',
                'Firm - Deep muscle focus without sharp pain',
                'Deep Tissue - Intense trigger point focus and myofascial release'
              ],
            },
            {
              'id': 'focus_and_avoid_areas',
              'label': 'Primary Focus Areas (Select all that apply)',
              'type': 'multiselect',
              'required': true,
              'options': [
                'Neck & Cervical Spine',
                'Upper Shoulders & Trapezius',
                'Lower Lumbar Back',
                'Glutes & Sciatic Nerve',
                'Feet & Reflexology'
              ],
            },
            {
              'id': 'soundscape_ambience',
              'label': 'Treatment Room Soundscape Preference',
              'type': 'select',
              'required': false,
              'options': [
                'Gentle Ocean Waves & Rainfall',
                'Tibetan Singing Bowls & Meditation',
                'Complete Silence'
              ],
            },
          ],
        },
      );

      final massageService = ServiceItem(
        id: 'srv-massage-1',
        businessId: 'biz-spa-test',
        name: 'Basalt Heated Stone Full Body Therapy (75 min)',
        durationMinutes: 75,
        price: 170.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClientIntakeStep(
                business: spaBiz,
                service: massageService,
                initialNotes: '',
                onNotesChanged: (notes) => visitNotes = notes,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Spa Ritual Intake & Requirements'), findsOneWidget);
      expect(find.text('Preferred Massage Pressure *'), findsOneWidget);
      expect(find.text('Primary Focus Areas (Select all that apply) *'), findsOneWidget);

      // Select multiselect chips
      expect(find.text('Neck & Cervical Spine'), findsOneWidget);
      expect(find.text('Lower Lumbar Back'), findsOneWidget);

      await tester.tap(find.text('Neck & Cervical Spine'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lower Lumbar Back'));
      await tester.pumpAndSettle();

      expect(visitNotes, contains('Primary Focus Areas (Select all that apply): Neck & Cervical Spine, Lower Lumbar Back'));
    });

    testWidgets('Boutique Fitness intake handles liability waiver signature and emergency contact', (tester) async {
      String visitNotes = '';
      final fitnessBiz = Business(
        id: 'biz-fitness-test',
        ownerId: 'owner-test',
        name: 'Solstice Reformer & Mat Studio',
        slug: 'solstice-fitness',
        category: 'fitness-pilates-yoga',
        bookingModel: BookingModelType.slotBased,
        uiConfig: const {
          'resource_type': 'instructor_and_studio_sanctuary',
          'resource_label': 'Certified Instructor',
          'service_label': 'Class / Private Session',
          'intake_fields': [
            {
              'id': 'fitness_experience_level',
              'label': 'Pilates / Yoga Experience Level',
              'type': 'select',
              'required': true,
              'options': [
                'First Timer (Never been on a Reformer before)',
                'Beginner (1 - 5 classes completed)',
                'Intermediate (Regular practitioner)',
                'Advanced / Instructor'
              ],
            },
            {
              'id': 'injury_movement_limitations',
              'label': 'Current Injuries or Limitations (Select all that apply)',
              'type': 'multiselect',
              'required': true,
              'options': [
                'None - Healthy & Full Mobility',
                'Lower Back Pain / Disc Herniation',
                'Knee Pain / Meniscus / ACL'
              ],
            },
            {
              'id': 'studio_liability_waiver',
              'label': 'Physical Activity Liability Release Waiver',
              'type': 'signature',
              'required': true,
              'disclaimer': 'I voluntarily participate in physical exercise at the studio and assume all risks of injury.',
            },
            {
              'id': 'emergency_contact',
              'label': 'Emergency Contact',
              'type': 'text',
              'required': true,
              'placeholder': 'Name & Phone',
            },
          ],
        },
      );

      final pilatesService = ServiceItem(
        id: 'srv-pilates-1',
        businessId: 'biz-fitness-test',
        name: 'Signature Reformer Flow (All Levels)',
        durationMinutes: 50,
        price: 36.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClientIntakeStep(
                business: fitnessBiz,
                service: pilatesService,
                initialNotes: '',
                onNotesChanged: (notes) => visitNotes = notes,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Class / Private Session Intake & Requirements'), findsOneWidget);
      expect(find.text('Physical Activity Liability Release Waiver *'), findsOneWidget);
      expect(find.text('I voluntarily participate in physical exercise at the studio and assume all risks of injury.'), findsOneWidget);

      // Tap liability checkbox to sign
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      expect(visitNotes, contains('Physical Activity Liability Release Waiver: Acknowledged & Signed'));
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
