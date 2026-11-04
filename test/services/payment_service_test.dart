// Gene - Nov, 04, 2026: Unit tests for PaymentService fee calculations, mock checkout, onboarding, and BookingService integration
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bookit/models/booking.dart';
import 'package:bookit/services/booking_service.dart';
import 'package:bookit/services/payment_service.dart';
import 'package:bookit/services/supabase_service.dart';

void main() {
  group('PaymentService Tests', () {
    test('Payment calculation calculates fee and net values accurately', () {
      const gross = 30.00;
      const feePercent = 2.50;
      const feeFixed = 0.30;

      final appFee = double.parse(((gross * (feePercent / 100)) + feeFixed).toStringAsFixed(2));
      final net = double.parse((gross - appFee).toStringAsFixed(2));

      expect(appFee, 1.05);
      expect(net, 28.95);
    });

    test('BookingNotifier.createBooking sets awaiting_payment, hold_expires_at, and unpaid status for new bookings', () async {
      final notifier = BookingNotifier();
      final now = DateTime.now();

      final initialBooking = Booking(
        id: 'test-booking-payment-1',
        businessId: 'biz-1',
        clientId: 'client-1',
        bookingModel: 'slot_based',
        status: 'pending',
        totalPrice: 150.00,
        createdAt: now,
      );

      final created = await notifier.createBooking(initialBooking);

      expect(created.status, 'awaiting_payment');
      expect(created.paymentStatus, 'unpaid');
      expect(created.holdExpiresAt, isNotNull);
      expect(created.amountDue, 150.00);
      expect(created.amountPaid, 0.0);

      // Verify the 15-minute reservation hold
      final holdDiffMinutes = created.holdExpiresAt!.difference(now).inMinutes;
      expect(holdDiffMinutes, inInclusiveRange(14, 15));

      // Verify notifier state contains the created booking
      expect(notifier.state.any((b) => b.id == 'test-booking-payment-1'), isTrue);
      final stored = notifier.state.firstWhere((b) => b.id == 'test-booking-payment-1');
      expect(stored.status, 'awaiting_payment');
      expect(stored.paymentStatus, 'unpaid');
    });

    test('BookingNotifier.createBooking bypasses hold timer and preserves confirmed status for pay_at_venue', () async {
      final notifier = BookingNotifier();
      final now = DateTime.now();

      final payAtVenueBooking = Booking(
        id: 'test-booking-venue-1',
        businessId: 'biz-1',
        clientId: 'client-1',
        bookingModel: 'slot_based',
        status: 'confirmed',
        totalPrice: 200.00,
        createdAt: now,
      );

      final created = await notifier.createBooking(payAtVenueBooking);

      expect(created.status, 'confirmed');
      expect(created.paymentStatus, 'unpaid');
      expect(created.holdExpiresAt, isNull);
      expect(created.amountDue, 200.00);
      expect(created.amountPaid, 0.0);
    });

    test('PaymentService offline/mock fallback executes simulateMockPaymentSuccess and calls onSuccess', () async {
      final dummyClient = SupabaseClient('https://mock.supabase.co', 'mock-key');
      final paymentService = PaymentService(dummyClient);

      bool callbackCalled = false;
      bool wasMock = false;

      await paymentService.initiateCheckout(
        bookingId: 'mock-booking-id',
        returnUrl: 'https://bookit.dev/return',
        cancelUrl: 'https://bookit.dev/cancel',
        onSuccess: (isMock) {
          callbackCalled = true;
          wasMock = isMock;
        },
      );

      expect(callbackCalled, isTrue);
      expect(wasMock, isTrue);
    });

    test('PaymentService simulateMockPaymentSuccess handles deposit payment and inserts records', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Seed a test booking in mockBookings
      final testBooking = Booking(
        id: 'bk-mock-deposit-test',
        businessId: '11111111-1111-1111-1111-111111111111',
        clientId: '00000000-0000-0000-0000-000000000003',
        bookingModel: 'slot_based',
        status: 'awaiting_payment',
        paymentStatus: 'unpaid',
        totalPrice: 100.00,
        createdAt: DateTime.now(),
      );
      SupabaseService.mockBookings.add(testBooking);

      final paymentService = container.read(paymentServiceProvider);
      final initialPaymentCount = SupabaseService.mockPayments.length;
      final initialNotifCount = SupabaseService.mockNotifications.length;

      // Simulate partial deposit payment of $30
      await paymentService.simulateMockPaymentSuccess('bk-mock-deposit-test', amount: 30.00);

      final updatedBooking = SupabaseService.mockBookings.firstWhere((b) => b.id == 'bk-mock-deposit-test');
      expect(updatedBooking.status, 'confirmed');
      expect(updatedBooking.paymentStatus, 'deposit_paid');
      expect(updatedBooking.amountPaid, 30.00);
      expect(updatedBooking.amountDue, 70.00);
      expect(updatedBooking.holdExpiresAt, isNull);

      // Verify payment record inserted
      expect(SupabaseService.mockPayments.length, initialPaymentCount + 1);
      final newPayment = SupabaseService.mockPayments.first;
      expect(newPayment.bookingId, 'bk-mock-deposit-test');
      expect(newPayment.grossAmount, 30.00);

      // Verify notification inserted
      expect(SupabaseService.mockNotifications.length, initialNotifCount + 1);
      final newNotif = SupabaseService.mockNotifications.first;
      expect(newNotif.bookingId, 'bk-mock-deposit-test');
      expect(newNotif.title, contains('Deposit Payment Confirmed'));
    });

    test('PaymentService getConnectOnboardingUrl alias returns URL successfully', () async {
      final dummyClient = SupabaseClient('https://mock.supabase.co', 'mock-key');
      final paymentService = PaymentService(dummyClient);

      final url = await paymentService.getConnectOnboardingUrl(
        businessId: 'mock-biz-id',
        returnUrl: 'https://bookit.dev/admin/payments',
      );

      expect(url, contains('stripe_connected=true'));
      expect(url, contains('mock=true'));
    });

    test('businessPaymentsProvider returns mock payments without network in unconfigured mode', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final paymentsStream = container.read(
        businessPaymentsProvider('11111111-1111-1111-1111-111111111111').future,
      );

      final payments = await paymentsStream;
      expect(payments, isNotEmpty);
      expect(payments.every((p) => p.businessId == '11111111-1111-1111-1111-111111111111'), isTrue);
    });

    test('Riverpod paymentServiceProvider initializes cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final paymentService = container.read(paymentServiceProvider);
      expect(paymentService, isA<PaymentService>());
    });
  });
}
