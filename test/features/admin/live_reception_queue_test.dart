// Gene - Nov, 05, 2026: Comprehensive widget tests for Live Reception Queue and Waiting Room tracker
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookit/models/booking.dart';
import 'package:bookit/services/booking_service.dart';
import 'package:bookit/features/admin/presentation/tabs/live_reception_queue_tab.dart';
import 'package:bookit/features/admin/presentation/admin_shell_screen.dart';

void main() {
  group('LiveReceptionQueueTab Tests', () {
    testWidgets('LiveReceptionQueueTab displays 4 swimlanes with wait timers', (tester) async {
      final now = DateTime.now();
      final dummyBookings = [
        Booking(
          id: 'b-1',
          businessId: 'biz-1',
          clientId: 'c-1',
          clientName: 'Alice Expected',
          serviceName: 'Consultation',
          bookingModel: 'slot_based',
          totalPrice: 100.0,
          createdAt: now,
          status: 'confirmed',
        ),
        Booking(
          id: 'b-2',
          businessId: 'biz-1',
          clientId: 'c-2',
          clientName: 'Bob Waiting',
          serviceName: 'Teeth Cleaning',
          bookingModel: 'slot_based',
          totalPrice: 120.0,
          createdAt: now,
          status: 'checked_in',
          checkedInAt: now.subtract(const Duration(minutes: 6)),
        ),
        Booking(
          id: 'b-3',
          businessId: 'biz-1',
          clientId: 'c-3',
          clientName: 'Charlie In-Service',
          serviceName: 'Checkup',
          bookingModel: 'slot_based',
          totalPrice: 80.0,
          createdAt: now,
          status: 'in_service',
          inServiceAt: now.subtract(const Duration(minutes: 15)),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingsProvider.overrideWith((ref) => BookingNotifier()..state = dummyBookings),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LiveReceptionQueueTab(businessId: 'biz-1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Expected'), findsWidgets);
      expect(find.textContaining('In Waiting Room'), findsWidgets);
      expect(find.textContaining('In-Service'), findsWidgets);
      expect(find.text('Alice Expected'), findsOneWidget);
      expect(find.text('Bob Waiting'), findsOneWidget);
      expect(find.text('Charlie In-Service'), findsOneWidget);
    });

    testWidgets('LiveReceptionQueueTab renders SLA wait time badges correctly', (tester) async {
      final now = DateTime.now();
      final dummyBookings = [
        // < 10m: Soft teal
        Booking(
          id: 'b-teal',
          businessId: 'biz-1',
          clientId: 'c-1',
          clientName: 'Teal Patient',
          serviceName: 'Consultation',
          bookingModel: 'slot_based',
          totalPrice: 50.0,
          createdAt: now,
          status: 'checked_in',
          checkedInAt: now.subtract(const Duration(minutes: 4)),
        ),
        // 10-15m: Amber
        Booking(
          id: 'b-amber',
          businessId: 'biz-1',
          clientId: 'c-2',
          clientName: 'Amber Patient',
          serviceName: 'Cleaning',
          bookingModel: 'slot_based',
          totalPrice: 60.0,
          createdAt: now,
          status: 'checked_in',
          checkedInAt: now.subtract(const Duration(minutes: 12)),
        ),
        // > 15m: Red alert SLA Target Exceeded
        Booking(
          id: 'b-red',
          businessId: 'biz-1',
          clientId: 'c-3',
          clientName: 'Red Patient',
          serviceName: 'Emergency',
          bookingModel: 'slot_based',
          totalPrice: 70.0,
          createdAt: now,
          status: 'checked_in',
          checkedInAt: now.subtract(const Duration(minutes: 18)),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingsProvider.overrideWith((ref) => BookingNotifier()..state = dummyBookings),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LiveReceptionQueueTab(businessId: 'biz-1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check badges
      expect(find.textContaining('04m'), findsOneWidget);
      expect(find.textContaining('12m'), findsOneWidget);
      expect(find.textContaining('Target Exceeded'), findsOneWidget);
    });

    testWidgets('1-Tap workflow action buttons update booking status', (tester) async {
      final now = DateTime.now();
      final dummyBookings = [
        Booking(
          id: 'b-exp',
          businessId: 'biz-1',
          clientId: 'c-1',
          clientName: 'David Expected',
          serviceName: 'Checkup',
          bookingModel: 'slot_based',
          totalPrice: 100.0,
          createdAt: now,
          status: 'confirmed',
        ),
        Booking(
          id: 'b-wait',
          businessId: 'biz-1',
          clientId: 'c-2',
          clientName: 'Elena Waiting',
          serviceName: 'X-Ray',
          bookingModel: 'slot_based',
          totalPrice: 120.0,
          createdAt: now,
          status: 'checked_in',
          checkedInAt: now.subtract(const Duration(minutes: 5)),
        ),
        Booking(
          id: 'b-serv',
          businessId: 'biz-1',
          clientId: 'c-3',
          clientName: 'Frank In-Service',
          serviceName: 'Filling',
          bookingModel: 'slot_based',
          totalPrice: 150.0,
          createdAt: now,
          status: 'in_service',
          inServiceAt: now.subtract(const Duration(minutes: 10)),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          bookingsProvider.overrideWith((ref) => BookingNotifier()..state = dummyBookings),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: LiveReceptionQueueTab(businessId: 'biz-1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap [Check-In] on Expected card
      final checkInBtn = find.widgetWithText(InkWell, 'Check-In');
      expect(checkInBtn, findsOneWidget);
      await tester.tap(checkInBtn);
      await tester.pumpAndSettle();

      expect(container.read(bookingsProvider).firstWhere((b) => b.id == 'b-exp').status, 'checked_in');

      // Tap [Call In / Start] on Waiting card (b-wait)
      final callInBtns = find.widgetWithText(InkWell, 'Call In / Start');
      expect(callInBtns, findsWidgets);
      await tester.tap(callInBtns.last);
      await tester.pumpAndSettle();

      expect(container.read(bookingsProvider).firstWhere((b) => b.id == 'b-wait').status, 'in_service');

      // Tap [Complete & Invoice] on In-Service card (b-serv)
      final completeBtns = find.widgetWithText(InkWell, 'Complete & Invoice');
      expect(completeBtns, findsWidgets);
      await tester.tap(completeBtns.last);
      await tester.pumpAndSettle();

      expect(container.read(bookingsProvider).firstWhere((b) => b.id == 'b-serv').status, 'completed');
    });

    testWidgets('AdminShellScreen includes Queue navigation destination', (tester) async {
      final hasQueueRail = AdminShellScreen.railDestinations.any((d) {
        if (d.label is Text) {
          return (d.label as Text).data == 'Queue';
        }
        return false;
      });

      final hasQueueBottomNav = AdminShellScreen.bottomNavItems.any((b) {
        return b.label == 'Queue';
      });

      expect(hasQueueRail, isTrue);
      expect(hasQueueBottomNav, isTrue);
    });
  });
}
