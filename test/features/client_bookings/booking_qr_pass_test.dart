// Gene - Nov, 05, 2026: Widget tests for Customer Digital Boarding Pass modal and QR previews
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookit/models/booking.dart';
import 'package:bookit/features/client_bookings/presentation/widgets/booking_qr_pass_modal.dart';
import 'package:bookit/features/booking_engine/presentation/steps/booking_confirmation_step.dart';
import 'package:bookit/features/client_bookings/presentation/client_bookings_screen.dart';
import 'package:bookit/services/booking_service.dart';

void main() {
  group('Customer Digital Boarding Pass Tests', () {
    testWidgets('BookingQrPassModal renders QR code, pass ID, and business details', (tester) async {
      final booking = Booking(
        id: 'test-booking-123456',
        businessId: 'biz-1',
        clientId: 'c-1',
        bookingModel: 'slot_based',
        businessName: 'Dr. Smile Dental Clinic',
        serviceName: 'Comprehensive Cleaning',
        startTime: DateTime(2026, 11, 10, 14, 30),
        totalPrice: 150.0,
        createdAt: DateTime(2026, 11, 5),
        status: 'confirmed',
        qrToken: 'BK-123456',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => BookingQrPassModal.show(ctx, booking),
                  child: const Text('Open Pass'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Pass'));
      await tester.pumpAndSettle();

      expect(find.text('Digital Boarding Pass'), findsOneWidget);
      expect(find.text('Dr. Smile Dental Clinic'), findsOneWidget);
      expect(find.text('BK-123456'), findsOneWidget);
      expect(find.text('Present this QR code at front desk'), findsOneWidget);
      expect(find.text('Scheduled — Present upon arrival'), findsOneWidget);
    });

    testWidgets('BookingQrPassModal shows checked in status banner when status is checked_in', (tester) async {
      final booking = Booking(
        id: 'test-booking-999',
        businessId: 'biz-1',
        clientId: 'c-1',
        bookingModel: 'slot_based',
        businessName: 'Apex Sports Physio',
        serviceName: 'Initial Assessment',
        startTime: DateTime(2026, 11, 10, 10, 0),
        totalPrice: 120.0,
        createdAt: DateTime(2026, 11, 5),
        status: 'checked_in',
        qrToken: 'BK-APEX99',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => BookingQrPassModal.show(ctx, booking),
                  child: const Text('Open Checked-In Pass'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Checked-In Pass'));
      await tester.pumpAndSettle();

      expect(find.text('Digital Boarding Pass'), findsOneWidget);
      expect(find.text('Checked In! You are in the queue.'), findsOneWidget);
    });

    testWidgets('BookingConfirmationStep embeds QR pass preview card', (tester) async {
      final booking = Booking(
        id: 'test-confirm-pass-1',
        businessId: 'biz-1',
        clientId: 'c-1',
        bookingModel: 'slot_based',
        businessName: 'Dr. Smile Dental Clinic',
        serviceName: 'Tooth Polish',
        startTime: DateTime(2026, 11, 12, 11, 0),
        totalPrice: 85.0,
        createdAt: DateTime(2026, 11, 5),
        status: 'confirmed',
        qrToken: 'BK-POLISH1',
      );

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

      expect(find.text('Digital Boarding Pass'), findsOneWidget);
      expect(find.text('Present upon arrival for quick check-in'), findsOneWidget);
      expect(find.text('Tap to enlarge'), findsOneWidget);
    });

    testWidgets('ClientBookingsScreen upcoming card includes View QR Pass button', (tester) async {
      final testBooking = Booking(
        id: 'test-client-b1',
        businessId: 'biz-1',
        clientId: 'c-1',
        bookingModel: 'slot_based',
        businessName: 'City Vet Clinic',
        serviceName: 'Puppy Checkup',
        startTime: DateTime(2026, 11, 20, 9, 30),
        totalPrice: 65.0,
        createdAt: DateTime(2026, 11, 5),
        status: 'confirmed',
        qrToken: 'BK-VET001',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientBookingsProvider.overrideWithValue([testBooking]),
          ],
          child: const MaterialApp(
            home: ClientBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('City Vet Clinic'), findsOneWidget);
      expect(find.text('View QR Pass'), findsOneWidget);

      await tester.tap(find.text('View QR Pass'));
      await tester.pumpAndSettle();

      expect(find.text('Digital Boarding Pass'), findsOneWidget);
      expect(find.text('BK-VET001'), findsOneWidget);
    });
  });
}
