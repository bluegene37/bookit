// Gene - Nov, 22, 2026: Comprehensive verification suite for DB-driven setup, universal UX invariants, release-mode isolation, and SQL/Edge contracts
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookit/core/constants/supabase_config.dart';
import 'package:bookit/features/booking_engine/presentation/steps/payment_checkout_step.dart';
import 'package:bookit/features/booking_engine/providers/booking_wizard_provider.dart';
import 'package:bookit/models/booking.dart';
import 'package:bookit/models/business.dart';
import 'package:bookit/models/business_staff.dart';
import 'package:bookit/models/platform_config.dart';
import 'package:bookit/models/service_item.dart';
import 'package:bookit/services/supabase_service.dart';

String _stripSqlComments(String sql) {
  final withoutBlock = sql.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  return withoutBlock.replaceAll(RegExp(r'--[^\n]*'), '');
}

void main() {
  setUp(() {
    SupabaseConfig.debugSimulateReleaseMode = false;
    SupabaseService.resetToDefaultData();
  });

  tearDown(() {
    SupabaseConfig.debugSimulateReleaseMode = false;
  });

  group('PlatformConfig & Database-Driven Global Presets', () {
    test('PlatformConfig.fromSettingsRows parses all 7 platform setting keys', () {
      final rows = [
        {
          'key': 'supported_currencies',
          'value': [
            {'code': 'PHP', 'symbol': '₱', 'name': 'Philippine Peso'},
            {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
            {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
            {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
          ],
        },
        {
          'key': 'booking_models',
          'value': [
            {
              'id': 'slot_based',
              'title': '1. Time Slot Appointments',
              'short_label': 'Time Slot Appointment',
              'description': 'Custom DB description',
              'icon': 'calendar_today',
            },
          ],
        },
        {
          'key': 'scheduling_presets',
          'value': {
            'slot_intervals': [10, 30, 60],
            'buffer_options': [0, 15],
            'open_times': ['08:00', '09:00'],
            'close_times': ['18:00', '20:00'],
            'default_advance_booking_days': 45,
            'default_min_notice_hours': 4,
          },
        },
        {
          'key': 'payment_channels',
          'value': [
            {
              'id': 'gcash',
              'label': 'GCash QR',
              'channel_title': 'GCash Verified Transfer',
              'subtitle': 'Scan QR Ph to pay',
              'requires_reference': true,
              'reference_label': 'GCash Ref Code',
              'reference_hint': 'Enter 13 digits',
              'sender_label': 'Sender GCash',
              'sender_hint': 'Name / Number',
            },
          ],
        },
        {
          'key': 'crm_config',
          'value': {
            'vip_spend_threshold': 500,
            'vip_visits_threshold': 5,
            'regular_visits_threshold': 3,
            'lapsed_days': 60,
            'flag_presets_by_category': {
              'healthcare': ['Latex Sensitivity'],
              'beauty': ['Color Formula Note'],
              'fitness': ['Knee Recovery'],
              'automotive': ['Matte PPF Coating'],
              'default': ['VIP Handling'],
            },
          },
        },
        {
          'key': 'standee_presets',
          'value': {
            'public_base_url': 'https://reserve.example.com/',
            'headlines': ['Book Instantly Here'],
          },
        },
        {
          'key': 'branding',
          'value': {
            'app_name': 'BookIt Pro',
            'discovery_subtitle': 'Book top local venues',
            'search_placeholder': 'Search any venue...',
            'default_latitude': 14.5995,
            'default_longitude': 120.9842,
          },
        },
      ];

      final cfg = PlatformConfig.fromSettingsRows(rows);
      expect(cfg.supportedCurrencies.first.code, 'PHP');
      expect(cfg.bookingModels.single.description, 'Custom DB description');
      expect(cfg.schedulingPresets.defaultAdvanceBookingDays, 45);
      expect(cfg.schedulingPresets.defaultMinNoticeHours, 4);
      expect(cfg.paymentChannels.single.referenceLabel, 'GCash Ref Code');
      expect(cfg.crmConfig.vipSpendThreshold, 500.0);
      expect(cfg.crmConfig.lapsedDays, 60);
      expect(cfg.standeePresets.publicBaseUrl, 'https://reserve.example.com/');
      expect(cfg.standeePresets.headlines.single, 'Book Instantly Here');
      expect(cfg.branding.appName, 'BookIt Pro');
      expect(cfg.branding.defaultLatitude, 14.5995);

      expect(PlatformConfig.symbolFor('USD'), '\$');
      expect(PlatformConfig.symbolFor('PHP'), '₱');
      expect(PlatformConfig.symbolFor('EUR'), '€');
      expect(PlatformConfig.symbolFor('JPY'), '¥');
      expect(PlatformConfig.formatCurrency(1250.5, currencyCode: 'PHP'), '₱1250.50');
      expect(PlatformConfig.formatCurrency(3000, currencyCode: 'JPY', decimals: 0), '¥3000');
      expect(
        cfg.crmFlagPresetsForCategory('Automotive & Detailing'),
        contains('Matte PPF Coating'),
      );
      expect(
        cfg.crmFlagPresetsForCategory('Unknown Custom Niche'),
        contains('VIP Handling'),
      );
    });
  });

  group('Business Model Universal Defaults & Release-Mode Payment Safety', () {
    test('Business.fromJson provides industry-neutral defaults and parses DB overrides', () {
      final minimal = Business.fromJson({
        'id': 'biz-min-1',
        'owner_id': 'owner-1',
        'name': 'Universal Hub',
        'slug': 'universal-hub',
        'category': 'Consulting',
        'booking_model': 'slot_based',
      });

      expect(minimal.venueLabel, 'Venue');
      expect(minimal.clientLabel, 'Client');
      expect(minimal.bookingLabel, 'Booking');
      expect(minimal.resourceLabel, 'Specialist');
      expect(minimal.serviceLabel, 'Service');
      expect(minimal.currency, 'USD');
      expect(minimal.advanceBookingDays, 14);
      expect(minimal.minNoticeHours, 0);
      expect(minimal.minDays, 1);

      final custom = Business.fromJson({
        'id': 'biz-custom-1',
        'owner_id': 'owner-1',
        'name': 'Manila Wash Hub',
        'slug': 'manila-wash-hub',
        'category': 'Automotive',
        'booking_model': 'date_range',
        'ui_config': {
          'venue_label': 'Hub',
          'client_label': 'Driver',
          'booking_label': 'Reservation',
          'resource_label': 'Bay',
          'service_label': 'Package',
          'crm_flag_label': 'Vehicle Notes',
          'crm_flag_presets': ['Ceramic Coated'],
        },
        'settings': {
          'currency': 'PHP',
          'advance_booking_days': 30,
          'min_notice_hours': 6,
          'min_days': 2,
          'max_days': 14,
        },
      });

      expect(custom.venueLabel, 'Hub');
      expect(custom.clientLabel, 'Driver');
      expect(custom.bookingLabel, 'Reservation');
      expect(custom.crmFlagLabel, 'Vehicle Notes');
      expect(custom.crmFlagPresets, ['Ceramic Coated']);
      expect(custom.currency, 'PHP');
      expect(custom.advanceBookingDays, 30);
      expect(custom.minNoticeHours, 6);
      expect(custom.minDays, 2);
      expect(custom.maxDays, 14);
    });

    test('Business.paymentMethodsConfig hides hardcoded demo phone numbers in simulated release mode', () {
      const biz = Business(
        id: 'biz-rel-1',
        ownerId: 'owner-1',
        name: 'Release Test Studio',
        slug: 'release-test-studio',
        category: 'Wellness',
        bookingModel: BookingModelType.slotBased,
        settings: {},
      );

      // Demo mode provides sandbox payment channels
      expect(biz.paymentMethodsConfig['gcash_number'], '0917-555-0199');
      expect(biz.paymentMethodsConfig['gcash_enabled'], isTrue);

      // Release mode omits hardcoded phone numbers and disables unconfigured channels
      SupabaseConfig.debugSimulateReleaseMode = true;
      expect(biz.paymentMethodsConfig['gcash_number'], '');
      expect(biz.paymentMethodsConfig['gcash_enabled'], isFalse);
      expect(biz.paymentMethodsConfig['maya_enabled'], isFalse);
      expect(biz.paymentMethodsConfig['bank_enabled'], isFalse);
    });
  });

  group('Booking Walk-In Serialization & BookingWizardNotifier Invariants', () {
    test('Booking serializes nullable walk-in client_id, walkin_client_name, intake_responses, and currency', () {
      final walkIn = Booking.fromJson({
        'id': '00000000-0000-4000-8000-000000000101',
        'business_id': '00000000-0000-4000-8000-000000000202',
        'client_id': null,
        'walkin_client_name': 'Walk-In Guest',
        'booking_model': 'slot_based',
        'status': 'checked_in',
        'total_price': 850.0,
        'intake_responses': {'vehicle_plate': 'ABC-1234', 'waiver_signed': true},
        'currency': 'PHP',
        'created_at': '2026-11-22T08:00:00.000Z',
      });

      expect(walkIn.clientId, isEmpty);
      expect(walkIn.walkinClientName, 'Walk-In Guest');
      expect(walkIn.intakeResponses['vehicle_plate'], 'ABC-1234');
      expect(walkIn.currency, 'PHP');

      final serialized = walkIn.toJson();
      expect(serialized['client_id'], isNull);
      expect(serialized['walkin_client_name'], 'Walk-In Guest');
      expect(serialized['intake_responses'], {'vehicle_plate': 'ABC-1234', 'waiver_signed': true});
      expect(serialized['currency'], 'PHP');
    });

    test('BookingWizardNotifier enforces staff reset, intake validation, min/max days, free consultation, and auth guard', () async {
      final dateRangeBiz = Business(
        id: 'biz-wizard-1',
        ownerId: 'owner-1',
        name: 'Mountain Cabins',
        slug: 'mountain-cabins',
        category: 'Stays',
        bookingModel: BookingModelType.dateRange,
        settings: const {
          'currency': 'PHP',
          'min_days': 2,
          'max_days': 5,
          'payment_methods': {
            'stripe_enabled': false,
            'gcash_enabled': true,
            'gcash_number': '0917-000-1111',
          },
        },
      );

      final stayService = ServiceItem(
        id: 'srv-stay-1',
        businessId: dateRangeBiz.id,
        name: 'Suite Nightly Rate',
        durationMinutes: 1440,
        price: 1000.0,
        currency: 'PHP',
        paymentPolicy: 'deposit_required',
        depositType: 'percentage',
        depositAmount: 25.0,
      );

      final freeConsult = ServiceItem(
        id: 'srv-free-1',
        businessId: dateRangeBiz.id,
        name: 'Discovery Call',
        durationMinutes: 15,
        price: 500.0,
        paymentPolicy: 'free_consultation',
      );

      const staff = BusinessStaff(
        id: 'stf-1',
        businessId: 'biz-wizard-1',
        name: 'Alex Guide',
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(bookingWizardProvider(dateRangeBiz).notifier);

      // Initial payment method skips disabled Stripe and defaults to GCash
      expect(container.read(bookingWizardProvider(dateRangeBiz)).selectedPaymentMethod, 'gcash');

      // selectStaff(null) clears previous selection
      notifier.selectStaff(staff);
      expect(container.read(bookingWizardProvider(dateRangeBiz)).selectedStaff?.id, 'stf-1');
      notifier.selectStaff(null);
      expect(container.read(bookingWizardProvider(dateRangeBiz)).selectedStaff, isNull);

      // Multi-day deposit & minDays / maxDays enforcement
      notifier.selectService(stayService);
      expect(notifier.canProceedToNextStep, isTrue); // Step 0
      notifier.nextStep();
      expect(container.read(bookingWizardProvider(dateRangeBiz)).currentStep, 1);

      final day1 = DateTime(2026, 12, 10);
      notifier.selectDateRange(day1, day1.add(const Duration(days: 1))); // < minDays(2)
      expect(notifier.canProceedToNextStep, isFalse);

      notifier.selectDateRange(day1, day1.add(const Duration(days: 6))); // > maxDays(5)
      expect(notifier.canProceedToNextStep, isFalse);

      notifier.selectDateRange(day1, day1.add(const Duration(days: 3))); // valid 3 nights
      expect(notifier.canProceedToNextStep, isTrue);
      final validState = container.read(bookingWizardProvider(dateRangeBiz));
      expect(validState.calculateTotalPrice(), 3000.0);
      expect(validState.dueTodayAmount, 750.0);
      expect(validState.dueAtVenueAmount, 2250.0);

      // Required intake blocks Step 2
      notifier.nextStep();
      expect(container.read(bookingWizardProvider(dateRangeBiz)).currentStep, 2);
      notifier.updateIntakeResponses({'waiver': ''}, hasMissingRequired: true);
      expect(notifier.canProceedToNextStep, isFalse);
      notifier.updateIntakeResponses({'waiver': 'Signed'}, hasMissingRequired: false);
      expect(notifier.canProceedToNextStep, isTrue);

      // Free consultation policy always charges 0 upfront
      notifier.selectService(freeConsult);
      final freeState = container.read(bookingWizardProvider(dateRangeBiz));
      expect(freeState.dueTodayAmount, 0.0);
      expect(freeState.isPayAtVenue, isTrue);

      // Simulated release mode blocks unauthenticated booking submission
      SupabaseConfig.debugSimulateReleaseMode = true;
      final ok = await notifier.confirmBooking();
      expect(ok, isFalse);
      expect(
        container.read(bookingWizardProvider(dateRangeBiz)).errorMessage?.toLowerCase(),
        contains('sign in'),
      );
    });
  });

  group('PaymentCheckoutStep Simulated Release-Mode Safeguards', () {
    testWidgets('hides Auto-Fill Demo Ref # and requires manual reference number in release mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      SupabaseConfig.debugSimulateReleaseMode = true;
      var proceeded = false;

      const biz = Business(
        id: 'biz-pay-rel',
        ownerId: 'owner-1',
        name: 'Verified Studio',
        slug: 'verified-studio',
        category: 'Services',
        bookingModel: BookingModelType.slotBased,
        settings: {
          'currency': 'PHP',
          'payment_methods': {
            'stripe_enabled': false,
            'gcash_enabled': true,
            'gcash_account_name': 'Verified Studio',
            'gcash_number': '0917-123-4567',
          },
        },
      );

      final service = ServiceItem(
        id: 'srv-pay-rel',
        businessId: biz.id,
        name: 'Consultation',
        durationMinutes: 30,
        price: 500,
        currency: 'PHP',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PaymentCheckoutStep(
                business: biz,
                service: service,
                totalPrice: 500,
                dueToday: 500,
                dueAtVenue: 0,
                selectedPaymentMethod: 'gcash',
                onProceed: () => proceeded = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Auto-fill button must NEVER appear in release mode
      expect(find.textContaining('Auto-Fill'), findsNothing);
      expect(find.textContaining('₱500.00'), findsWidgets);

      // Tapping Proceed without reference number must be blocked with error message
      final submitFinder = find.textContaining('Submit');
      expect(submitFinder, findsWidgets);
      await tester.ensureVisible(submitFinder.last);
      await tester.tap(submitFinder.last);
      await tester.pumpAndSettle();

      expect(proceeded, isFalse);
      expect(find.text('Please enter your transaction reference number to proceed.'), findsOneWidget);
    });
  });

  group('SQL Migration, Master Setup & Edge Function Contracts', () {
    test('active SQL statements contain zero non-hex t0000001 UUIDs and include DB-driven schema/RPCs', () {
      final migration = File('supabase/migrations/20261122000001_db_driven_setup_and_production_hardening.sql').readAsStringSync();
      final masterSetup = File('supabase/master_setup.sql').readAsStringSync();
      final seedSql = File('supabase/seed.sql').readAsStringSync();

      expect(_stripSqlComments(seedSql).contains('t0000001'), isFalse);
      expect(_stripSqlComments(masterSetup).contains('t0000001-0000'), isFalse);

      for (final sql in [migration, masterSetup]) {
        expect(sql, contains('CREATE TABLE IF NOT EXISTS public.platform_settings'));
        expect(sql, contains('reschedule_client_booking'));
        expect(sql, contains('submit_manual_payment'));
        expect(sql, contains('chk_bookings_client_or_walkin'));
        expect(sql, contains('IF NEW.client_id IS NULL THEN'));
      }
    });

    test('create-checkout-session Edge Function computes deposit_required & handles direct transfers before Stripe secret check', () {
      final edgeFn = File('supabase/functions/create-checkout-session/index.ts').readAsStringSync();
      final activeEdge = edgeFn.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
      expect(activeEdge, contains('deposit_required'));
      expect(activeEdge, contains('pay_at_venue'));
      expect(activeEdge, contains('currency'));
      const directBranch = "payment_method !== 'stripe_card'";
      expect(activeEdge, contains(directBranch));
      expect(
        activeEdge.indexOf(directBranch),
        lessThan(activeEdge.indexOf("const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')")),
      );
    });
  });
}
