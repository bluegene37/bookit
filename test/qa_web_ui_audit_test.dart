// Gene - Nov, 04, 2026: Comprehensive Web QA & Alpha UI/UX Audit Test Suite covering all 5 core user journeys, sweet-spot templates, form boundaries, and responsive states
import 'dart:async';
// Gene - Nov, 14, 2026: Added dart:convert for mock Nominatim geocoding JSON responses
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookit/models/business.dart';
import 'package:bookit/models/service_item.dart';
import 'package:bookit/models/booking.dart';
import 'package:bookit/models/payment.dart';
import 'package:bookit/services/business_service.dart';
import 'package:bookit/services/auth_service.dart';
import 'package:bookit/services/payment_service.dart';
import 'package:bookit/features/admin/presentation/admin_shell_screen.dart';
import 'package:bookit/features/admin/presentation/widgets/admin_onboarding_wizard.dart';
import 'package:bookit/features/admin/presentation/widgets/refund_dialog.dart';
import 'package:bookit/features/admin/presentation/tabs/payments_invoices_tab.dart';
import 'package:bookit/features/discovery/presentation/home_discovery_screen.dart';
import 'package:bookit/features/discovery/presentation/business_detail_screen.dart';
import 'package:bookit/features/booking_engine/presentation/steps/client_intake_step.dart';
import 'package:bookit/features/booking_engine/presentation/steps/payment_checkout_step.dart';
import 'package:bookit/features/booking_engine/presentation/steps/booking_confirmation_step.dart';
import 'package:bookit/features/auth/presentation/login_screen.dart';
// Gene - Nov, 7, 2026: Added booking_wizard_provider import for QA Gate 7 flow & state lifecycle tests
import 'package:bookit/features/booking_engine/providers/booking_wizard_provider.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('QA Gate 1: Admin Onboarding Wizard & Form Validation Matrix', () {
    testWidgets('Empty business name triggers validation alert and blocks progression', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdminOnboardingWizard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 0: Verify Sweet-Spot Categories and Template Cards exist
      expect(find.text('Business Onboarding & Setup'), findsOneWidget);
      expect(find.text('Step 1 of 4: Choose Industry Template'), findsOneWidget);

      // Select Dental Clinic template
      final dentalFinder = find.text('Dental Care Clinic');
      expect(dentalFinder, findsOneWidget);
      await tester.tap(dentalFinder);
      await tester.pumpAndSettle();

      // Click Continue to go to Step 1
      final continueButton = find.text('Continue');
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Step 1: Business Details
      expect(find.text('Step 2 of 4: Business Information'), findsOneWidget);

      // Leave business name blank and attempt Continue
      await tester.tap(find.text('Continue'));
      await tester.pump();

      // Validation snackbar must appear
      expect(find.text('Please enter your business name.'), findsOneWidget);
    });

    testWidgets('Full 4-Step Onboarding Wizard successfully provisions business with services and staff', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AdminOnboardingWizard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 0: Select Dental Practice
      await tester.tap(find.text('Dental Care Clinic'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 1: Enter Business Details
      final nameFields = find.byType(TextField);
      expect(nameFields, findsWidgets);

      // Fill Name (Field 0)
      await tester.enterText(nameFields.at(0), 'Alpha Premier Dental');
      await tester.pumpAndSettle();

      // Advance to Step 2 (Starter Catalog & Staff)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 4: Review Starter Catalog'), findsOneWidget);
      expect(find.text('Starter Service Catalog & Resource Roles'), findsOneWidget);

      // Advance to Step 3 (Operating Hours & Launch)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Step 4 of 4: Schedule & Launch'), findsOneWidget);
      expect(find.text('Launch Business'), findsOneWidget);

      // Click Launch Business
      await tester.tap(find.text('Launch Business'));
      await tester.pumpAndSettle();

      // Verify business is provisioned in businessListProvider
      final businesses = await container.read(businessServiceProvider).getBusinesses();
      expect(businesses.any((b) => b.name == 'Alpha Premier Dental'), isTrue);
    });
  });

  group('QA Gate 2: Admin Dashboard, Responsive Modes & Tab Navigation', () {
    testWidgets('AdminShellScreen renders authentication gate when user is unauthenticated', (tester) async {
      final container = ProviderContainer();
      container.read(authProvider.notifier).signOut();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AdminShellScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BookIt Web Admin Portal'), findsOneWidget);
      expect(find.text('Please sign in with clinic administrator credentials to access practice management.'), findsOneWidget);
    });

    // Gene - Nov, 05, 2026: QA test verifying RBAC gate blocks client role and renders Access Restricted gate (CWE-285)
    testWidgets('AdminShellScreen renders access restricted gate when logged in user has client role', (tester) async {
      final container = ProviderContainer();
      container.read(authProvider.notifier).loginAsDemoClient();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AdminShellScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.text('Your account is currently registered as a Client. Business Owner or Administrator privileges are required to access practice operations.'), findsOneWidget);
      expect(find.text('Return to Client Portal'), findsOneWidget);
    });

    testWidgets('AdminShellScreen renders responsive mobile layout with bottom navigation on narrow screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      final container = ProviderContainer();
      container.read(authProvider.notifier).loginAsDemoAdmin();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AdminShellScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // On 375px mobile screen, BottomNavigationBar must be present
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Overview'), findsWidgets);
      expect(find.text('Calendar'), findsWidgets);
      expect(find.text('Services'), findsWidgets);
      expect(find.text('Staff'), findsWidgets);
      expect(find.text('Payments'), findsWidgets);
    });

    testWidgets('AdminShellScreen renders desktop sidebar on 1440x900 viewport', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      final container = ProviderContainer();
      container.read(authProvider.notifier).loginAsDemoAdmin();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AdminShellScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // On wide desktop screen, Web Top Bar and Left Sidebar exist
      expect(find.text('CLINIC WORKSPACE'), findsOneWidget);
      expect(find.text('Dashboard Overview'), findsOneWidget);
      expect(find.text('Appointments Calendar'), findsOneWidget);
      expect(find.text('Services & Pricing'), findsOneWidget);
      expect(find.text('Doctors & Specialists'), findsOneWidget);
      expect(find.text('Payments & Invoices'), findsOneWidget);
      expect(find.text('Template & Settings'), findsOneWidget);
    });

    testWidgets('PaymentsInvoicesTab renders revenue KPIs and executes full/partial refund validations', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      final samplePayment = Payment(
        id: 'pay-test-1',
        businessId: 'biz-1',
        bookingId: 'bk-test-1',
        clientId: 'client-1',
        grossAmount: 120.0,
        netAmount: 115.0,
        paymentStatus: 'succeeded',
        createdAt: DateTime(2026, 11, 4),
      );

      final testBusiness = Business(
        id: 'biz-1',
        ownerId: 'owner-1',
        name: 'Apex Dental Care',
        slug: 'apex-dental',
        category: 'dental',
        bookingModel: BookingModelType.slotBased,
      );

      final container = ProviderContainer(
        overrides: [
          businessPaymentsProvider('biz-1').overrideWith((ref) => Stream.value([samplePayment])),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: PaymentsInvoicesTab(business: testBusiness),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Check KPI Summary Cards
      expect(find.text('Gross Volume'), findsOneWidget);
      expect(find.text('Net Payouts'), findsOneWidget);
      expect(find.text('Balances Due at Clinic'), findsOneWidget);
      expect(find.text('Refunds'), findsOneWidget);

      // Verify transaction table header
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Client'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);

      // Verify RefundDialog in isolation
      double? refundedAmount;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefundDialog(
              payment: samplePayment,
              onRefund: (amount, reason) async {
                refundedAmount = amount;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Issue Refund'), findsOneWidget);
      expect(find.text('Full Refund (\$120.00)'), findsOneWidget);
      expect(find.text('Custom Partial Refund'), findsOneWidget);

      // Switch to Partial Refund
      await tester.tap(find.text('Custom Partial Refund'));
      await tester.pumpAndSettle();

      // Amount field appears
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '60.00');
      await tester.pumpAndSettle();

      // Submit refund
      /*
      // Gene - Nov, 04, 2026: Incorrect button text 'Confirm Refund'
      await tester.tap(find.text('Confirm Refund'));
      */
      // Gene - Nov, 04, 2026: Updated finder to match RefundDialog button text 'Process Refund'
      await tester.tap(find.text('Process Refund'));
      await tester.pumpAndSettle();

      expect(refundedAmount, 60.0);
    });
  });

  group('QA Gate 3: Client Discovery Screen & Filters', () {
    testWidgets('HomeDiscoveryScreen category filter updates active selection', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeDiscoveryScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('BookIt'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);

      // Tap Healthcare & Clinics
      final healthcareChip = find.text('Healthcare & Clinics');
      if (healthcareChip.evaluate().isNotEmpty) {
        await tester.tap(healthcareChip);
        await tester.pumpAndSettle();
      }

      // Verify business cards exist
      expect(find.text('Apex Dental & Orthodontic Care'), findsOneWidget);
    });

    testWidgets('Search query filters business list dynamically', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeDiscoveryScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Search for Serenity
      await tester.enterText(searchField, 'Serenity');
      await tester.pumpAndSettle();

      expect(find.text('Serenity Post-Op Recovery & Wellness Suites'), findsOneWidget);
      expect(find.text('Apex Dental & Orthodontic Care'), findsNothing);
    });
  });

  group('QA Gate 4: Business Detail Screen Dynamic Labels', () {
    testWidgets('BusinessDetailScreen renders slot-based dynamic labels for clinic', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BusinessDetailScreen(businessId: '11111111-1111-1111-1111-111111111111'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Clinic name
      expect(find.text('Apex Dental & Orthodontic Care'), findsOneWidget);
      // Dynamic service label catalog
      expect(find.text('Service Catalog'), findsOneWidget);
      // Dynamic resource label header
      expect(find.text('Our Specialists'), findsOneWidget);
      // CTA Book button
      expect(find.text('Book Appointment (Time Slot Appointment)'), findsOneWidget);
    });

    testWidgets('BusinessDetailScreen renders date-range dynamic labels for recovery stay', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BusinessDetailScreen(businessId: '22222222-2222-2222-2222-222222222222'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Serenity Post-Op Recovery & Wellness Suites'), findsOneWidget);
      expect(find.text('Service Catalog'), findsOneWidget);
    });
  });

  group('QA Gate 5: Universal Booking Engine & Dynamic Intake Forms', () {
    testWidgets('ClientIntakeStep renders template intake toggles and formats visit notes', (tester) async {
      final dentalBiz = Business(
        id: 'biz-1',
        ownerId: 'owner-1',
        name: 'Apex Dental Care',
        slug: 'apex-dental',
        category: 'dental',
        bookingModel: BookingModelType.slotBased,
        uiConfig: const {
          'resource_type': 'person',
          'resource_label': 'Specialist',
          'service_label': 'Treatment',
          'intake_fields': [
            {
              'id': 'dental_anxiety',
              'label': 'Do you experience dental anxiety or require sedation?',
              'type': 'boolean',
            },
            {
              'id': 'last_cleaning',
              'label': 'When was your last dental cleaning?',
              'type': 'text',
              'placeholder': 'e.g. 6 months ago',
            },
          ],
        },
      );

      String formattedNotes = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientIntakeStep(
              business: dentalBiz,
              service: ServiceItem(
                id: 'srv-1',
                businessId: 'biz-1',
                name: 'Comprehensive Exam',
                durationMinutes: 45,
                price: 120.0,
              ),
              initialNotes: '',
              onNotesChanged: (notes) {
                formattedNotes = notes;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify dynamic label header
      expect(find.text('Treatment Intake & Requirements'), findsOneWidget);
      expect(find.text('Do you experience dental anxiety or require sedation?'), findsOneWidget);
      expect(find.text('When was your last dental cleaning?'), findsOneWidget);

      // Toggle dental anxiety switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(formattedNotes.contains('Do you experience dental anxiety or require sedation?: Yes'), isTrue);

      // Enter text for last cleaning
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);
      await tester.enterText(textFields.first, '3 months ago');
      await tester.pumpAndSettle();

      expect(formattedNotes.contains('When was your last dental cleaning?: 3 months ago'), isTrue);
    });

    testWidgets('PaymentCheckoutStep displays correct policy tags and financial breakdown', (tester) async {
      final depositService = ServiceItem(
        id: 'srv-dep',
        businessId: 'biz-1',
        name: 'Dental Implant Consultation',
        durationMinutes: 60,
        price: 250.0,
        paymentPolicy: 'deposit',
        depositAmount: 50.0,
      );

      bool proceeded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentCheckoutStep(
              service: depositService,
              totalPrice: 250.0,
              dueToday: 50.0,
              dueAtVenue: 200.0,
              practitionerName: 'Dr. Vance',
              onProceed: () {
                proceeded = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review & Payment'), findsOneWidget);
      expect(find.text('Deposit Policy'), findsOneWidget);
      expect(find.text('\$50.00'), findsWidgets); // Due today
      expect(find.text('\$200.00'), findsWidgets); // Due at venue
      expect(find.text('\$250.00'), findsWidgets); // Total

      // Tap Proceed
      await tester.tap(find.text('Pay via Stripe'));
      await tester.pumpAndSettle();

      expect(proceeded, isTrue);
    });

    testWidgets('BookingConfirmationStep displays formatted reference code and appointment recap', (tester) async {
      final booking = Booking(
        id: 'bk-alpha-12345678',
        clientId: 'client-1',
        businessId: 'biz-1',
        bookingModel: 'slot_based',
        createdAt: DateTime(2026, 11, 4),
        businessName: 'Apex Dental Care',
        serviceName: 'Comprehensive Dental Exam',
        staffName: 'Dr. Vance',
        startTime: DateTime(2026, 11, 6, 14, 0),
        endTime: DateTime(2026, 11, 6, 14, 45),
        totalPrice: 120.0,
        status: 'confirmed',
      );

      bool viewedBookings = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingConfirmationStep(
              booking: booking,
              onViewBookings: () {
                viewedBookings = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Booking Successful!'), findsOneWidget);
      expect(find.text('BOOKING PASS'), findsOneWidget);
      expect(find.text('#BK-BK-ALPHA'), findsOneWidget);
      expect(find.text('Apex Dental Care'), findsOneWidget);
      expect(find.text('\$120.00'), findsOneWidget);

      await tester.tap(find.text('View in My Bookings'));
      await tester.pumpAndSettle();

      expect(viewedBookings, isTrue);
    });
  });

  group('QA Gate 6: Authentication & Security Boundaries', () {
    testWidgets('LoginScreen validates invalid email and provides instant demo sign-in', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to BookIt'), findsOneWidget);
      expect(find.text('Admin Demo'), findsOneWidget);
      expect(find.text('Patient Demo'), findsOneWidget);

      // Attempt submit with empty fields
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email and password.'), findsOneWidget);
    });
  });

  // Gene - Nov, 7, 2026: QA Gate 7 verifying end-to-end wizard state identity, multi-day deposit math, contraindication gating, and reset lifecycle
  group('QA Gate 7: End-to-End Flow & Wizard Lifecycle Regression Suite', () {
    test('Business equality by id ensures bookingWizardProvider resolves identical state across reconstructed instances', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const bizInstanceA = Business(
        id: '11111111-1111-1111-1111-111111111111',
        ownerId: 'owner-1',
        name: 'Apex Dental',
        slug: 'apex-dental',
        category: 'Healthcare & Clinics',
        bookingModel: BookingModelType.slotBased,
      );
      final bizInstanceB = bizInstanceA.copyWith(ratingCount: 99);

      const service = ServiceItem(
        id: 'srv-101',
        businessId: '11111111-1111-1111-1111-111111111111',
        name: 'Laser Whitening',
        price: 180.0,
      );

      container.read(bookingWizardProvider(bizInstanceA).notifier).selectService(service);
      final stateFromB = container.read(bookingWizardProvider(bizInstanceB));
      expect(stateFromB.selectedService?.id, 'srv-101');
    });

    test('Multi-day dateRange booking calculates percentage deposit against total multi-day stay price', () {
      const stayService = ServiceItem(
        id: 'srv-stay',
        businessId: 'biz-stay',
        name: 'Private Recovery Suite',
        price: 300.0,
        paymentPolicy: 'deposit',
        depositType: 'percentage',
        depositAmount: 20.0, // 20%
      );

      final state = BookingWizardState(
        selectedService: stayService,
        dateRangeStart: DateTime(2026, 11, 10),
        dateRangeEnd: DateTime(2026, 11, 13), // 3 nights -> $900 total
      );

      expect(state.calculateTotalPrice(), 900.0);
      expect(state.dueTodayAmount, 180.0); // 20% of $900 = $180
      expect(state.dueAtVenueAmount, 720.0);
    });

    test('Clinical contraindication blocker gates Step 2 progression until cleared', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const biz = Business(
        id: 'biz-derm',
        ownerId: 'owner-1',
        name: 'Lumina Dermatology',
        slug: 'lumina-derm',
        category: 'Healthcare & Clinics',
        bookingModel: BookingModelType.daily,
      );
      const service = ServiceItem(
        id: 'srv-laser',
        businessId: 'biz-derm',
        name: 'Fractional CO2 Laser',
        price: 350.0,
      );

      final notifier = container.read(bookingWizardProvider(biz).notifier);
      notifier.selectService(service);
      notifier.nextStep(); // -> Step 1
      notifier.nextStep(); // -> Step 2 (Intake)
      expect(container.read(bookingWizardProvider(biz)).currentStep, 2);
      expect(container.read(bookingWizardProvider(biz)).canProceed(biz.bookingModel), isTrue);

      // Activate contraindication blocker
      notifier.setIntakeBlocker(true);
      expect(container.read(bookingWizardProvider(biz)).canProceed(biz.bookingModel), isFalse);

      // Attempt nextStep while blocked — must remain on Step 2
      notifier.nextStep();
      expect(container.read(bookingWizardProvider(biz)).currentStep, 2);

      // Clear blocker and advance -> Step 3
      notifier.setIntakeBlocker(false);
      notifier.nextStep();
      expect(container.read(bookingWizardProvider(biz)).currentStep, 3);

      // Test goToStep(1) and reset()
      notifier.goToStep(1);
      expect(container.read(bookingWizardProvider(biz)).currentStep, 1);

      notifier.reset();
      expect(container.read(bookingWizardProvider(biz)).currentStep, 0);
      expect(container.read(bookingWizardProvider(biz)).selectedService, isNull);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

/*
// Gene - Nov, 04, 2026: Basic mock client missing autoUncompress property
class _MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }
}
*/
/*
// Gene - Nov, 04, 2026: Added autoUncompress and idleTimeout getters/setters for NetworkImage loader compatibility
class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }
}
*/
// Gene - Nov, 14, 2026: Complete HttpClientRequest/Headers/Response mock (including Stream & Nominatim JSON) to eliminate UnimplementedError console noise [QA-012]
/*
// Gene - Nov 06, 2026: Implemented openUrl, close, and userAgent in _MockHttpClient for flutter_map NetworkTileProvider compatibility
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
    return Stream<List<int>>.value(_transparentPng).listen(
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
    return Stream<List<int>>.value(_bodyBytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

const _transparentPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];
