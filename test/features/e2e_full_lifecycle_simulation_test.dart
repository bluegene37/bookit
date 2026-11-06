// Gene - Nov 06, 2026: End-to-End Simulation of full SaaS operational lifecycle (Onboarding, Discovery, Slot Calculation, Intake, Checkout, QR Reception Check-in, and CRM)
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
/*
import 'package:flutter_riverpod/flutter_riverpod.dart';
*/
// Gene - Nov 06, 2026: Cleaned up unused imports for static analysis zero warnings

import 'package:bookit/models/business.dart';
import 'package:bookit/models/booking.dart';
import 'package:bookit/models/service_item.dart';
import 'package:bookit/models/business_staff.dart';
import 'package:bookit/services/business_service.dart';
/*
import 'package:bookit/services/booking_service.dart';
*/
import 'package:bookit/services/crm_service.dart';
import 'package:bookit/features/booking_engine/domain/slot_calculator.dart';
/*
import 'package:bookit/features/admin/presentation/widgets/admin_onboarding_wizard.dart';
*/
import 'package:bookit/features/booking_engine/presentation/steps/client_intake_step.dart';
/*
import 'package:bookit/widgets/payment_checkout_step.dart';
*/
// Gene - Nov 06, 2026: Fixed import path for PaymentCheckoutStep and added ClientCrmProfile model
import 'package:bookit/features/booking_engine/presentation/steps/payment_checkout_step.dart';
/*
import 'package:bookit/models/client_crm_profile.dart';
*/
import 'package:bookit/features/booking_engine/presentation/steps/booking_confirmation_step.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('E2E Lifecycle Simulation: Auto Detailing & Car Wash Vertical', () {
    test('Phase 1: Admin Onboarding provisions Auto Detailing business with bays and packages', () async {
      final businessService = BusinessService();
      final templates = await businessService.getTemplates();

      // Verify Auto Detailing template exists
      final autoTpl = templates.firstWhere((t) => t.slug == 'auto-detailing-car-wash');
      expect(autoTpl.name, 'Auto Detailing & Car Wash');
      expect(autoTpl.starterServices.length, 7);
      expect(autoTpl.starterStaffRoles.length, 3);
      expect((autoTpl.uiConfig['intake_fields'] as List).length, 6);
      expect(autoTpl.defaultSettings['deposit_percent'], 25.0);
      expect(autoTpl.defaultSettings['buffer_minutes'], 10);

      // Create new business using template
      final createdBusiness = await businessService.createBusiness(
        business: Business(
          id: 'biz-apex-auto-e2e',
          ownerId: 'owner-sim-1',
          name: 'Apex Precision Auto Spa',
          slug: 'apex-auto-spa',
          category: 'automotive-detailing',
          bookingModel: BookingModelType.slotBased,
          address: '100 Industrial Pkwy',
          city: 'San Francisco',
          latitude: 37.7650,
          longitude: -122.4100,
          settings: autoTpl.defaultSettings,
          uiConfig: autoTpl.uiConfig,
        ),
        services: autoTpl.starterServices.asMap().entries.map((entry) {
          final s = entry.value;
          return ServiceItem(
            id: 'srv-auto-${entry.key + 1}',
            businessId: 'biz-apex-auto-e2e',
            name: s['name'] as String,
            description: s['description'] as String,
            durationMinutes: s['duration_minutes'] as int,
            price: (s['price'] as num).toDouble(),
            paymentPolicy: s['payment_policy'] as String? ?? 'deposit_required',
            depositAmount: (s['deposit_amount'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList(),
        staff: autoTpl.starterStaffRoles.asMap().entries.map((entry) {
          return BusinessStaff(
            id: 'staff-bay-${entry.key + 1}',
            businessId: 'biz-apex-auto-e2e',
            name: entry.value,
            specialty: 'Detailing Specialist',
          );
        }).toList(),
      );

      expect(createdBusiness.id, 'biz-apex-auto-e2e');
      expect(createdBusiness.name, 'Apex Precision Auto Spa');

      // Verify services and bays persisted in service
      final services = await businessService.getServices('biz-apex-auto-e2e');
      expect(services.length, 7);
      expect(services.any((s) => s.name.contains('Diamond Detail')), isTrue);

      final bays = await businessService.getStaff('biz-apex-auto-e2e');
      expect(bays.length, 3);
      expect(bays.first.name, contains('Bay 1: Master Certified Detailer'));
    });

    test('Phase 2 & 3: SlotCalculator computes available detailing slots with bay buffer & lunch breaks', () {
      final now = DateTime(2026, 11, 10); // Tuesday
      final staff = BusinessStaff(
        id: 'staff-bay-1',
        businessId: 'biz-apex-auto-e2e',
        name: 'Bay 1: Master Certified Detailer',
        scheduleOverride: {
          'tuesday': {
            'is_working': true,
            'start': '08:00',
            'end': '18:00',
            'has_break': true,
            'break_start': '12:00',
            'break_end': '13:00',
          },
        },
      );

      final service = ServiceItem(
        id: 'srv-auto-3',
        businessId: 'biz-apex-auto-e2e',
        name: 'Complete Diamond Detail (In & Out)',
        durationMinutes: 150, // 2.5 hours
        price: 280.0,
      );

      /*
      // Business working hours: 8:00 - 18:00
      final businessSettings = {
        'slot_interval_minutes': 30,
        'buffer_minutes': 10, // 10 min bay drain and clean
        'working_hours': {
          'tuesday': {'open': '08:00', 'close': '18:00', 'is_open': true},
        },
      };

      final availableSlots = SlotCalculator.calculateSlots(
        date: now,
        service: service,
        businessSettings: businessSettings,
        existingBookings: [],
        staffSchedule: staff.getScheduleForDay('tuesday'),
      );

      expect(availableSlots.isNotEmpty, isTrue);

      // 08:00 slot takes 150 min -> 08:00 to 10:30 (available)
      final slot8am = availableSlots.firstWhere((s) => s.time == '08:00');
      expect(slot8am.isAvailable, isTrue);

      // Slot at 10:00 takes 150 min -> ends at 12:30, which overlaps lunch break 12:00-13:00!
      // Therefore, 10:00 or 10:30 slot should be unavailable
      final slot1030 = availableSlots.firstWhere((s) => s.time == '10:30');
      expect(slot1030.isAvailable, isFalse);

      // Afternoon slot at 13:00 (1:00 PM) takes 150 min -> ends at 15:30 (available)
      final slot1pm = availableSlots.firstWhere((s) => s.time == '13:00');
      expect(slot1pm.isAvailable, isTrue);
      */
      // Gene - Nov 06, 2026: Calculate detailing slots using SlotCalculator.calculateAvailableSlots with staff shift & lunch break filtering
      final business = Business(
        id: 'biz-apex-auto-e2e',
        ownerId: 'owner-sim-1',
        name: 'Apex Precision Auto Spa',
        slug: 'apex-auto-spa',
        category: 'automotive-detailing',
        bookingModel: BookingModelType.slotBased,
        settings: {
          'slot_interval_minutes': 30,
          'buffer_minutes': 10,
          'working_hours': {
            'tuesday': {'open': '08:00', 'close': '18:00', 'is_open': true},
          },
        },
      );

      final availableSlots = SlotCalculator.calculateAvailableSlots(
        business: business,
        date: now,
        existingBookings: [],
        customDurationMinutes: service.durationMinutes,
        staffMember: staff,
      );

      expect(availableSlots.isNotEmpty, isTrue);

      // 08:00 slot takes 150 min -> 08:00 to 10:30 (available within shift before lunch)
      final slot8am = availableSlots.firstWhere((s) => s.startTime.hour == 8 && s.startTime.minute == 0);
      expect(slot8am.isAvailable, isTrue);

      // Slot at 10:30 takes 150 min -> ends at 13:00, overlapping lunch break 12:00-13:00!
      // Therefore, 10:30 slot should be unavailable
      final slot1030 = availableSlots.firstWhere((s) => s.startTime.hour == 10 && s.startTime.minute == 30);
      expect(slot1030.isAvailable, isFalse);

      // Afternoon slot at 13:00 (1:00 PM) takes 150 min -> ends at 15:30 (available after lunch)
      final slot1pm = availableSlots.firstWhere((s) => s.startTime.hour == 13 && s.startTime.minute == 0);
      expect(slot1pm.isAvailable, isTrue);
    });

    testWidgets('Phase 4: ClientIntakeStep captures vehicle specs, pet hair condition & notes', (tester) async {
      String recordedNotes = '';

      final autoBiz = Business(
        id: 'biz-apex-auto-e2e',
        ownerId: 'owner-sim-1',
        name: 'Apex Precision Auto Spa',
        slug: 'apex-auto-spa',
        category: 'automotive-detailing',
        bookingModel: BookingModelType.slotBased,
        uiConfig: const {
          'resource_type': 'bay_and_technician',
          'resource_label': 'Detailing Bay & Specialist',
          'service_label': 'Auto Detailing Package',
          'intake_fields': [
            {
              'id': 'vehicle_type',
              'label': 'Vehicle Size & Class',
              'type': 'select',
              'required': true,
              'options': [
                'Sedan / Hatchback',
                'Mid-Size SUV / Crossover',
                'Full-Size SUV / Pickup Truck',
                'Minivan / Commercial Van'
              ],
            },
            {
              'id': 'vehicle_make_model_year',
              'label': 'Vehicle Year, Make & Model',
              'type': 'text',
              'required': true,
              'placeholder': 'e.g. 2024 Porsche Macan, Chalk White',
            },
            {
              'id': 'license_plate',
              'label': 'License Plate # & State',
              'type': 'text',
              'required': true,
              'placeholder': 'e.g. 7XYZ123 (CA)',
            },
            {
              'id': 'heavy_soiling_pet_hair',
              'label': 'Excessive pet hair, interior mold, or heavy caked mud?',
              'type': 'boolean',
              'required': true,
              'helper_text': 'Additional manual steam extraction surcharge (\$30–\$50) may apply at intake inspection.',
            },
            {
              'id': 'ceramic_matte_paint',
              'label': 'Vehicle has existing ceramic coating, matte paint, or protective vinyl wrap?',
              'type': 'boolean',
              'required': false,
              'helper_text': 'Ensures pH-neutral foam wash and contact-free drying towels.',
            },
          ],
        },
      );

      final service = ServiceItem(
        id: 'srv-auto-3',
        businessId: 'biz-apex-auto-e2e',
        name: 'Complete Diamond Detail (In & Out)',
        durationMinutes: 150,
        price: 280.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClientIntakeStep(
                business: autoBiz,
                service: service,
                initialNotes: '',
                onNotesChanged: (notes) => recordedNotes = notes,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify dynamic header
      expect(find.text('Auto Detailing Package Intake & Requirements'), findsOneWidget);
      expect(find.text('Vehicle Size & Class *'), findsOneWidget);

      // Change vehicle type dropdown to Mid-Size SUV
      await tester.tap(find.text('Sedan / Hatchback'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mid-Size SUV / Crossover').last);
      await tester.pumpAndSettle();

      /*
      // Enter Make, Model & License
      await tester.enterText(find.widgetWithText(TextField, ''), '2024 Porsche Macan');
      await tester.pumpAndSettle();
      */
      // Gene - Nov 06, 2026: Enter vehicle make and model into specific intake text field
      await tester.enterText(
        find.byWidgetPredicate((w) => w is TextField && (w.decoration?.hintText?.contains('Porsche Macan') ?? false)),
        '2024 Porsche Macan',
      );
      await tester.pumpAndSettle();

      // Toggle pet hair switch
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      // Verify notes buffer contents
      expect(recordedNotes, contains('Vehicle Size & Class: Mid-Size SUV / Crossover'));
      expect(recordedNotes, contains('Excessive pet hair, interior mold, or heavy caked mud?: Yes'));
    });

    testWidgets('Phase 5: PaymentCheckoutStep validates 25% deposit calculation & Stripe flow', (tester) async {
      bool checkoutSucceeded = false;

      final diamondDetailService = ServiceItem(
        id: 'srv-auto-3',
        businessId: 'biz-apex-auto-e2e',
        name: 'Complete Diamond Detail (In & Out)',
        durationMinutes: 150,
        price: 280.0,
        paymentPolicy: 'deposit_required',
        depositAmount: 70.0, // 25% of $280
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentCheckoutStep(
              service: diamondDetailService,
              totalPrice: 280.0,
              dueToday: 70.0,
              dueAtVenue: 210.0,
              practitionerName: 'Bay 1: Master Certified Detailer',
              onProceed: () => checkoutSucceeded = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Validate payment breakdown
      expect(find.text('Review & Payment'), findsOneWidget);
      expect(find.text('Deposit Policy'), findsOneWidget);
      expect(find.text('\$70.00'), findsWidgets); // Due today
      expect(find.text('\$210.00'), findsWidgets); // Due upon vehicle pickup
      expect(find.text('\$280.00'), findsWidgets); // Total package price

      // Proceed with Stripe payment
      await tester.tap(find.text('Pay via Stripe'));
      await tester.pumpAndSettle();

      expect(checkoutSucceeded, isTrue);
    });

    testWidgets('Phase 6 & 7: Confirmation Pass, Reception Check-in & CRM Dossier aggregation', (tester) async {
      final bookingTime = DateTime(2026, 11, 10, 9, 0);
      final booking = Booking(
        id: 'bk-apex-auto-999',
        clientId: 'client-car-vip-1',
        businessId: 'biz-apex-auto-e2e',
        bookingModel: 'slot_based',
        createdAt: DateTime(2026, 11, 8),
        businessName: 'Apex Precision Auto Spa',
        serviceName: 'Complete Diamond Detail (In & Out)',
        staffName: 'Bay 1: Master Certified Detailer',
        startTime: bookingTime,
        endTime: bookingTime.add(const Duration(minutes: 150)),
        totalPrice: 280.0,
        status: 'confirmed',
      /*
        notes: 'Vehicle Size & Class: Mid-Size SUV / Crossover\nVehicle: 2024 Porsche Macan\nLicense: 7XYZ999\nExcessive pet hair: Yes',
      );
      */
      // Gene - Nov 06, 2026: Set clientName and clientNotes for Booking model
        clientName: 'Julian Croft',
        clientNotes: 'Vehicle Size & Class: Mid-Size SUV / Crossover\nVehicle: 2024 Porsche Macan\nLicense: 7XYZ999\nExcessive pet hair: Yes',
      );

      // Verify Confirmation pass rendering
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingConfirmationStep(
              booking: booking,
              onViewBookings: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Booking Successful!'), findsOneWidget);
      expect(find.text('Apex Precision Auto Spa'), findsOneWidget);
      expect(find.text('Complete Diamond Detail (In & Out)'), findsOneWidget);
      expect(find.text('\$280.00'), findsOneWidget);

      // Reception desk state transitions
      expect(booking.status, 'confirmed');
      final checkedInBooking = booking.copyWith(status: 'arrived');
      expect(checkedInBooking.status, 'arrived');

      final inServiceBooking = checkedInBooking.copyWith(status: 'in_service');
      expect(inServiceBooking.status, 'in_service');

      final completedBooking = inServiceBooking.copyWith(status: 'completed');
      expect(completedBooking.status, 'completed');

      /*
      // CRM Dossier aggregation test
      final crmService = CrmService();
      final profile = crmService.buildClientProfileFromBookings(
        clientId: 'client-car-vip-1',
        clientName: 'Julian Croft',
        clientPhone: '(555) 901-2233',
        clientEmail: 'julian.croft@example.com',
        historicalBookings: [completedBooking],
      );

      expect(profile.lifetimeValue, 280.0);
      expect(profile.completedBookingsCount, 1);
      expect(profile.noShowCount, 0);
      expect(profile.status, ClientTier.regular); // 1 completed visit
      */
      // Gene - Nov 06, 2026: Validate CRM aggregation, spend calculation, and client tier tagging via CrmService
      final crmService = CrmService();
      final profiles = crmService.aggregateClients([completedBooking]);
      expect(profiles.length, 1);
      final profile = profiles.first;

      expect(profile.name, 'Julian Croft');
      expect(profile.totalSpend, 280.0);
      expect(profile.totalVisits, 1);
      expect(profile.noShowCount, 0);
      expect(profile.statusTag, 'New'); // 1 visit ($280) -> 'New'

      // Simulate a return visit with Ceramic Coating ($850) -> upgrades statusTag to 'VIP'
      final returnBooking = completedBooking.copyWith(
        id: 'bk-apex-auto-1000',
        totalPrice: 850.0,
        status: 'completed',
      );
      final vipProfiles = crmService.aggregateClients([completedBooking, returnBooking]);
      expect(vipProfiles.first.totalSpend, 1130.0);
      expect(vipProfiles.first.totalVisits, 2);
      expect(vipProfiles.first.statusTag, 'VIP'); // Spend >= $350 -> 'VIP'
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
