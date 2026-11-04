import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookit/features/booking_engine/presentation/steps/payment_checkout_step.dart';
import 'package:bookit/features/booking_engine/presentation/steps/booking_confirmation_step.dart';
import 'package:bookit/models/service_item.dart';
import 'package:bookit/models/booking.dart';

void main() {
  group('PaymentCheckoutStep Widget Tests', () {
    testWidgets('PaymentCheckoutStep renders deposit breakdown correctly', (tester) async {
      const service = ServiceItem(
        id: 's1',
        businessId: 'b1',
        name: 'Dental Checkup',
        price: 150.00,
        paymentPolicy: 'deposit',
        depositType: 'percentage',
        depositAmount: 20.00,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentCheckoutStep(
              service: service,
              totalPrice: 150.00,
              dueToday: 30.00,
              dueAtVenue: 120.00,
              onProceed: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Due Today (Deposit)'), findsOneWidget);
      expect(find.textContaining('\$30.00'), findsOneWidget);
      expect(find.textContaining('\$120.00'), findsOneWidget);
    });

    testWidgets('PaymentCheckoutStep renders pay on arrival when dueToday is 0', (tester) async {
      const service = ServiceItem(
        id: 's2',
        businessId: 'b1',
        name: 'Initial Consultation',
        price: 80.00,
        paymentPolicy: 'pay_at_venue',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentCheckoutStep(
              service: service,
              totalPrice: 80.00,
              dueToday: 0.00,
              dueAtVenue: 80.00,
              onProceed: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Confirm Booking (Pay on Arrival)'), findsOneWidget);
      expect(find.textContaining('\$80.00'), findsWidgets);
    });

    testWidgets('PaymentCheckoutStep triggers onProceed when action button tapped', (tester) async {
      bool proceeded = false;
      const service = ServiceItem(
        id: 's1',
        businessId: 'b1',
        name: 'Dental Cleaning',
        price: 100.00,
        paymentPolicy: 'full_upfront',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentCheckoutStep(
              service: service,
              totalPrice: 100.00,
              dueToday: 100.00,
              dueAtVenue: 0.00,
              onProceed: () {
                proceeded = true;
              },
            ),
          ),
        ),
      );

      final payButton = find.text('Pay via Stripe');
      expect(payButton, findsOneWidget);

      await tester.tap(payButton);
      await tester.pumpAndSettle();

      expect(proceeded, isTrue);
    });
  });

  group('BookingConfirmationStep Enhanced Tests', () {
    testWidgets('BookingConfirmationStep displays booking ID #BK-XXXX and deposit badge', (tester) async {
      final booking = Booking(
        id: 'a1b2c3d4-1111-2222-3333-444455556666',
        businessId: 'biz-1',
        clientId: 'usr-1',
        bookingModel: 'slot_based',
        businessName: 'Smile Dental Clinic',
        serviceName: 'Dental Checkup',
        staffName: 'Dr. Smith',
        startTime: DateTime(2026, 11, 10, 10, 0),
        endTime: DateTime(2026, 11, 10, 10, 45),
        totalPrice: 150.00,
        amountPaid: 30.00,
        amountDue: 120.00,
        paymentStatus: 'deposit_paid',
        status: 'confirmed',
        createdAt: DateTime.now(),
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

      // Verify #BK-XXXX ID formatting
      expect(find.textContaining('#BK-A1B2C3D4'), findsOneWidget);

      // Verify Payment Status Badges
      expect(find.textContaining('Deposit Paid: \$30.00'), findsOneWidget);
      expect(find.textContaining('Balance Due at Clinic: \$120.00'), findsOneWidget);

      // Verify Download PDF Invoice button
      expect(find.text('Download PDF Invoice'), findsOneWidget);
    });
  });
}
