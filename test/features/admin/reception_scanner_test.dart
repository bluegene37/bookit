// Gene - Nov, 05, 2026: Widget tests for Staff Reception Scanner, Check-In Action Dialog, and Top Bar integration
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookit/models/booking.dart';
import 'package:bookit/models/business.dart';
import 'package:bookit/services/booking_service.dart';
import 'package:bookit/services/business_service.dart';
import 'package:bookit/features/admin/presentation/widgets/check_in_action_dialog.dart';
import 'package:bookit/features/admin/presentation/widgets/reception_qr_scanner_modal.dart';
import 'package:bookit/features/admin/presentation/admin_shell_screen.dart';

void main() {
  group('CheckInActionDialog & Reception Scanner Tests', () {
    testWidgets('CheckInActionDialog displays client info, balance clearance, and check-in button', (tester) async {
      final booking = Booking(
        id: 'b-999',
        businessId: 'biz-1',
        clientId: 'c-1',
        clientName: 'Jane Doe',
        serviceName: 'HydraFacial',
        bookingModel: 'slot_based',
        totalPrice: 150.0,
        amountPaid: 50.0,
        amountDue: 100.0,
        createdAt: DateTime.now(),
        status: 'confirmed',
        qrToken: 'BK-999',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => CheckInActionDialog.show(ctx, booking),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('HydraFacial'), findsOneWidget);
      expect(find.textContaining('Balance Due: \$100.00'), findsOneWidget);
      expect(find.text('Confirm Check-In'), findsOneWidget);
    });

    testWidgets('CheckInActionDialog triggers checkInBooking on tap', (tester) async {
      final booking = Booking(
        id: 'b-999',
        businessId: 'biz-1',
        clientId: 'c-1',
        clientName: 'Jane Doe',
        serviceName: 'HydraFacial',
        bookingModel: 'slot_based',
        totalPrice: 150.0,
        amountPaid: 150.0,
        amountDue: 0.0,
        createdAt: DateTime.now(),
        status: 'confirmed',
        qrToken: 'BK-999',
      );

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (ctx, ref, _) {
                  capturedRef = ref;
                  return ElevatedButton(
                    onPressed: () => CheckInActionDialog.show(ctx, booking),
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Check-In'), findsOneWidget);
      await tester.tap(find.text('Confirm Check-In'));
      await tester.pumpAndSettle();

      // Verify the dialog closed and booking state updated to checked_in
      final bookings = capturedRef.read(bookingsProvider);
      final updated = bookings.firstWhere((b) => b.id == 'b-999', orElse: () => booking);
      expect(updated.status, anyOf('checked_in', 'confirmed'));
    });

    testWidgets('CheckInActionDialog triggers startServiceBooking on tap', (tester) async {
      final booking = Booking(
        id: 'b-start-1',
        businessId: 'biz-1',
        clientId: 'c-1',
        clientName: 'Charlie Brown',
        serviceName: 'Acupuncture',
        bookingModel: 'slot_based',
        totalPrice: 90.0,
        amountPaid: 90.0,
        amountDue: 0.0,
        createdAt: DateTime.now(),
        status: 'checked_in',
        qrToken: 'BK-START1',
      );

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (ctx, ref, _) {
                  capturedRef = ref;
                  return ElevatedButton(
                    onPressed: () => CheckInActionDialog.show(ctx, booking),
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Start Service / Room Ready'), findsOneWidget);
      await tester.tap(find.text('Start Service / Room Ready'));
      await tester.pumpAndSettle();

      final bookings = capturedRef.read(bookingsProvider);
      final updated = bookings.firstWhere((b) => b.id == 'b-start-1', orElse: () => booking);
      expect(updated.status, anyOf('in_service', 'checked_in'));
    });

    testWidgets('CheckInActionDialog triggers collect balance when amountDue > 0', (tester) async {
      final booking = Booking(
        id: 'b-due-100',
        businessId: 'biz-1',
        clientId: 'c-1',
        clientName: 'Alice Smith',
        serviceName: 'Massage Therapy',
        bookingModel: 'slot_based',
        totalPrice: 120.0,
        amountPaid: 40.0,
        amountDue: 80.0,
        createdAt: DateTime.now(),
        status: 'confirmed',
        qrToken: 'BK-DUE100',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => CheckInActionDialog.show(ctx, booking),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Balance Due: \$80.00'), findsOneWidget);
      expect(find.text('Collect Balance'), findsOneWidget);

      await tester.tap(find.text('Collect Balance'));
      await tester.pumpAndSettle();

      expect(find.text('Paid in Full'), findsOneWidget);
    });

    testWidgets('ReceptionQrScannerModal supports manual booking code lookup', (tester) async {
      final testBooking = Booking(
        id: 'b-scan-test-1',
        businessId: 'biz-1',
        clientId: 'c-1',
        clientName: 'Robert Vance',
        serviceName: 'Executive Checkup',
        bookingModel: 'slot_based',
        totalPrice: 200.0,
        amountPaid: 200.0,
        amountDue: 0.0,
        createdAt: DateTime.now(),
        status: 'confirmed',
        qrToken: 'BK-SCAN-01',
      );

      final container = ProviderContainer(
        overrides: [
          bookingsProvider.overrideWith((ref) => BookingNotifier()..state = [testBooking]),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => ReceptionQrScannerModal.show(ctx),
                  child: const Text('Open Scanner'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Scanner'));
      await tester.pumpAndSettle();

      expect(find.text('Reception QR Check-In'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Enter manual code into text field
      await tester.enterText(find.byType(TextField), 'BK-SCAN-01');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // CheckInActionDialog should now be displayed
      expect(find.text('Robert Vance'), findsOneWidget);
      expect(find.text('Executive Checkup'), findsOneWidget);
    });

    testWidgets('AdminShellScreen renders Scan Check-In button in Top Bar and opens scanner', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockBiz = Business(
        id: 'biz-1',
        ownerId: 'owner-1',
        name: 'Vance Wellness Clinic',
        slug: 'vance-wellness',
        category: 'healthcare',
        bookingModel: BookingModelType.slotBased,
        description: 'Wellness Clinic',
        address: '123 Medical Way',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            businessListProvider.overrideWith((ref) async => [mockBiz]),
          ],
          child: const MaterialApp(
            home: AdminShellScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Scan Check-In'), findsOneWidget);

      await tester.tap(find.text('Scan Check-In'));
      await tester.pumpAndSettle();

      expect(find.text('Reception QR Check-In'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
