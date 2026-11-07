// Gene - Nov 06, 2026: Widget tests for Web Admin Executive Dashboard and interactive charts
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bookit/models/business.dart';
import 'package:bookit/models/booking.dart';
import 'package:bookit/models/service_item.dart';
import 'package:bookit/models/business_staff.dart';
import 'package:bookit/services/booking_service.dart';
import 'package:bookit/services/business_service.dart';
import 'package:bookit/services/auth_service.dart';
import 'package:bookit/features/admin/presentation/admin_shell_screen.dart';
import 'package:bookit/features/admin/presentation/dashboard_overview_tab.dart';
import 'package:bookit/features/admin/presentation/widgets/charts/revenue_trend_chart.dart';
import 'package:bookit/features/admin/presentation/widgets/charts/service_donut_chart.dart';
import 'package:bookit/features/admin/presentation/widgets/charts/peak_hours_bar_chart.dart';
import 'package:bookit/features/admin/presentation/widgets/charts/staff_utilization_chart.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = null;
  });

  final testBusiness = Business(
    id: 'biz-apex-auto-web-test',
    ownerId: 'owner-web-admin',
    name: 'Apex Precision Auto Spa',
    slug: 'apex-auto-spa',
    category: 'automotive-detailing',
    bookingModel: BookingModelType.slotBased,
    ratingAvg: 4.9,
    ratingCount: 38,
    settings: const {
      'slot_interval_minutes': 30,
      'buffer_minutes': 10,
    },
  );

  final testBookings = [
    Booking(
      id: 'bk-web-1',
      clientId: 'client-1',
      businessId: 'biz-apex-auto-web-test',
      bookingModel: 'slot_based',
      createdAt: DateTime(2026, 11, 1),
      businessName: 'Apex Precision Auto Spa',
      serviceName: 'Complete Diamond Detail',
      staffName: 'Bay 1: Master Certified Detailer',
      clientName: 'Alexander Hayes',
      startTime: DateTime(2026, 11, 6, 10, 0),
      endTime: DateTime(2026, 11, 6, 12, 30),
      totalPrice: 280.0,
      status: 'confirmed',
    ),
    Booking(
      id: 'bk-web-2',
      clientId: 'client-2',
      businessId: 'biz-apex-auto-web-test',
      bookingModel: 'slot_based',
      createdAt: DateTime(2026, 11, 2),
      businessName: 'Apex Precision Auto Spa',
      serviceName: '3-Year Ceramic Coating',
      staffName: 'Bay 3: Ceramic Coating Technician',
      clientName: 'Victoria Sterling',
      startTime: DateTime(2026, 11, 6, 14, 0),
      endTime: DateTime(2026, 11, 6, 18, 0),
      totalPrice: 850.0,
      status: 'confirmed',
    ),
    Booking(
      id: 'bk-web-3',
      clientId: 'client-3',
      businessId: 'biz-apex-auto-web-test',
      bookingModel: 'slot_based',
      createdAt: DateTime(2026, 11, 3),
      businessName: 'Apex Precision Auto Spa',
      serviceName: 'Executive Interior Steam',
      clientName: 'Marcus Vance',
      startTime: DateTime(2026, 11, 7, 9, 0),
      endTime: DateTime(2026, 11, 7, 10, 30),
      totalPrice: 165.0,
      status: 'pending',
    ),
  ];

  final testServices = [
    ServiceItem(
      id: 'srv-1',
      businessId: 'biz-apex-auto-web-test',
      name: 'Complete Diamond Detail',
      durationMinutes: 150,
      price: 280.0,
    ),
    ServiceItem(
      id: 'srv-2',
      businessId: 'biz-apex-auto-web-test',
      name: '3-Year Pro Ceramic Coating',
      durationMinutes: 240,
      price: 850.0,
    ),
    ServiceItem(
      id: 'srv-3',
      businessId: 'biz-apex-auto-web-test',
      name: 'Executive Interior Steam',
      durationMinutes: 90,
      price: 165.0,
    ),
  ];

  final testStaff = [
    BusinessStaff(
      id: 'staff-1',
      businessId: 'biz-apex-auto-web-test',
      name: 'Bay 1: Master Certified Detailer',
      specialty: 'Paint Correction & Detail',
    ),
    BusinessStaff(
      id: 'staff-2',
      businessId: 'biz-apex-auto-web-test',
      name: 'Bay 2: Steam Specialist',
      specialty: 'Interior Sanitization',
    ),
  ];

  group('Web Admin Dashboard & Analytics Charts Tests', () {
    testWidgets('Desktop Viewport (1440x900) renders all 4 executive charts in dual-column grid', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminBookingsProvider(testBusiness.id).overrideWithValue(testBookings),
            businessServicesProvider(testBusiness.id).overrideWith((ref) => Future.value(testServices)),
            businessStaffProvider(testBusiness.id).overrideWith((ref) => Future.value(testStaff)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DashboardOverviewTab(business: testBusiness),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & KPIs
      expect(find.text('Apex Precision Auto Spa Executive Dashboard'), findsOneWidget);
      expect(find.textContaining('Model: Time Slot Appointment'), findsOneWidget);
      expect(find.text('Web Analytics • Live Performance'), findsOneWidget);

      expect(find.text('Gross Revenue'), findsOneWidget);
      expect(find.text('Total Appointments'), findsOneWidget);
      expect(find.text('Bay / Chair Occupancy'), findsOneWidget);
      expect(find.text('Average Ticket Value'), findsOneWidget);

      // Verify all 4 chart components are present
      expect(find.byType(RevenueTrendChart), findsOneWidget);
      expect(find.byType(ServiceDonutChart), findsOneWidget);
      expect(find.byType(PeakHoursBarChart), findsOneWidget);
      expect(find.byType(StaffUtilizationChart), findsOneWidget);

      // Verify chart specific headers
      expect(find.text('Revenue & Booking Velocity'), findsOneWidget);
      expect(find.text('Service Revenue Share'), findsOneWidget);
      expect(find.text('Peak Hours & Traffic Distribution'), findsOneWidget);
      expect(find.text('Specialist & Resource Utilization'), findsOneWidget);

      // Verify Pending approvals & Upcoming sections
      expect(find.text('Pending Booking Approvals'), findsOneWidget);
      expect(find.text('Upcoming Appointments & Bookings'), findsOneWidget);
    });

    testWidgets('Interactive chart controls: Time Range Pills & Volume Toggle switch correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminBookingsProvider(testBusiness.id).overrideWithValue(testBookings),
            businessServicesProvider(testBusiness.id).overrideWith((ref) => Future.value(testServices)),
            businessStaffProvider(testBusiness.id).overrideWith((ref) => Future.value(testStaff)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DashboardOverviewTab(business: testBusiness),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to 30D
      await tester.tap(find.text('30D'));
      await tester.pumpAndSettle();
      expect(find.text('+14.2% vs prior 30D'), findsOneWidget);

      // Switch to 90D
      await tester.tap(find.text('90D'));
      await tester.pumpAndSettle();
      expect(find.text('+14.2% vs prior 90D'), findsOneWidget);

      // Toggle velocity chart to volume mode '#'
      await tester.tap(find.text('#'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Total Appointments Booked:'), findsOneWidget);

      // Toggle back to revenue mode '$'
      await tester.tap(find.text('\$').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Total Gross Volume:'), findsOneWidget);
    });

    testWidgets('Mobile Viewport (375x812) renders vertical stack without RenderFlex overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminBookingsProvider(testBusiness.id).overrideWithValue(testBookings),
            businessServicesProvider(testBusiness.id).overrideWith((ref) => Future.value(testServices)),
            businessStaffProvider(testBusiness.id).overrideWith((ref) => Future.value(testStaff)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DashboardOverviewTab(business: testBusiness),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert zero exceptions / overflows occurred
      final err = tester.takeException();
      if (err is FlutterError) {
        debugPrint(err.toStringDeep());
      }
      expect(err, isNull);
      expect(find.byType(RevenueTrendChart), findsOneWidget);
      expect(find.byType(ServiceDonutChart), findsOneWidget);
    });

    testWidgets('AdminShellScreen renders DashboardOverviewTab as primary overview on Web', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      final container = ProviderContainer(
        overrides: [
          businessListProvider.overrideWith((ref) => Future.value([testBusiness])),
          adminBookingsProvider(testBusiness.id).overrideWithValue(testBookings),
        ],
      );
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
      await tester.pump(const Duration(seconds: 5));

      expect(find.text('CLINIC WORKSPACE'), findsOneWidget);
      expect(find.text('Apex Precision Auto Spa Executive Dashboard'), findsOneWidget);
      expect(find.byType(RevenueTrendChart), findsOneWidget);
    });
  });
}
