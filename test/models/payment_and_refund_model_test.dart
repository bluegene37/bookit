// Gene - Nov, 04, 2026: Unit tests for Stripe payment, refund, and deposit policy serialization
import 'package:flutter_test/flutter_test.dart';
import 'package:bookit/models/payment.dart';
import 'package:bookit/models/refund.dart';
import 'package:bookit/models/booking.dart';
import 'package:bookit/models/service_item.dart';
import 'package:bookit/models/business.dart';

void main() {
  group('Payment and Refund Models', () {
    test('Payment model serializes and deserializes correctly', () {
      final json = {
        'id': 'pay-123',
        'booking_id': 'bk-456',
        'business_id': 'biz-789',
        'client_id': 'usr-001',
        'stripe_session_id': 'cs_test_123',
        'stripe_payment_intent_id': 'pi_test_123',
        'gross_amount': 30.00,
        'application_fee_amount': 1.05,
        'stripe_fee_amount': 0.88,
        'net_amount': 28.07,
        'currency': 'usd',
        'payment_status': 'succeeded',
        'receipt_url': 'https://stripe.com/receipt/123',
        'created_at': '2026-11-04T10:00:00Z',
      };

      final payment = Payment.fromJson(json);
      expect(payment.id, 'pay-123');
      expect(payment.grossAmount, 30.00);
      expect(payment.applicationFeeAmount, 1.05);
      expect(payment.netAmount, 28.07);

      final encoded = payment.toJson();
      expect(encoded['id'], 'pay-123');
      expect(encoded['gross_amount'], 30.00);
      expect(encoded['net_amount'], 28.07);
    });

    test('Refund model serializes and deserializes correctly', () {
      final json = {
        'id': 'ref-123',
        'payment_id': 'pay-123',
        'booking_id': 'bk-456',
        'stripe_refund_id': 're_test_123',
        'amount': 15.00,
        'reason': 'Customer requested cancellation',
        'status': 'succeeded',
        'created_by': 'usr-admin',
        'created_at': '2026-11-04T11:00:00Z',
      };

      final refund = Refund.fromJson(json);
      expect(refund.id, 'ref-123');
      expect(refund.amount, 15.00);
      expect(refund.reason, 'Customer requested cancellation');

      final encoded = refund.toJson();
      expect(encoded['id'], 'ref-123');
      expect(encoded['amount'], 15.00);
      expect(encoded['reason'], 'Customer requested cancellation');
    });

    test('Booking model handles payment_status and hold_expires_at', () {
      final json = {
        'id': 'bk-123',
        'business_id': 'biz-1',
        'client_id': 'usr-1',
        'booking_model': 'slot_based',
        'status': 'awaiting_payment',
        'payment_status': 'deposit_paid',
        'hold_expires_at': '2026-11-04T10:15:00Z',
        'total_price': 150.00,
        'amount_paid': 30.00,
        'amount_due': 120.00,
        'created_at': '2026-11-04T10:00:00Z',
      };

      final booking = Booking.fromJson(json);
      expect(booking.paymentStatus, 'deposit_paid');
      expect(booking.amountPaid, 30.00);
      expect(booking.amountDue, 120.00);
      expect(booking.holdExpiresAt, isNotNull);

      final encoded = booking.toJson();
      expect(encoded['payment_status'], 'deposit_paid');
      expect(encoded['amount_paid'], 30.00);
      expect(encoded['amount_due'], 120.00);
      expect(encoded['hold_expires_at'], isNotNull);
    });

    test('ServiceItem handles deposit and payment policy', () {
      final json = {
        'id': 'srv-1',
        'business_id': 'biz-1',
        'name': 'Dental Cleaning',
        'price': 150.00,
        'payment_policy': 'deposit',
        'deposit_type': 'percentage',
        'deposit_amount': 20.00,
      };

      final service = ServiceItem.fromJson(json);
      expect(service.paymentPolicy, 'deposit');
      expect(service.depositType, 'percentage');
      expect(service.depositAmount, 20.00);
      expect(service.calculateDepositAmount(), 30.00);

      // Test other calculateDepositAmount branches
      final fullService = ServiceItem(
        id: 'srv-2',
        businessId: 'biz-1',
        name: 'Full Upfront',
        price: 200.00,
        paymentPolicy: 'full_upfront',
      );
      expect(fullService.calculateDepositAmount(), 200.00);

      final venueService = ServiceItem(
        id: 'srv-3',
        businessId: 'biz-1',
        name: 'Pay At Venue',
        price: 100.00,
        paymentPolicy: 'pay_at_venue',
      );
      expect(venueService.calculateDepositAmount(), 0.0);

      final fixedService = ServiceItem(
        id: 'srv-4',
        businessId: 'biz-1',
        name: 'Fixed Deposit',
        price: 150.00,
        paymentPolicy: 'deposit',
        depositType: 'fixed',
        depositAmount: 50.00,
      );
      expect(fixedService.calculateDepositAmount(), 50.00);

      final cappedFixedService = ServiceItem(
        id: 'srv-5',
        businessId: 'biz-1',
        name: 'Capped Fixed Deposit',
        price: 150.00,
        paymentPolicy: 'deposit',
        depositType: 'fixed',
        depositAmount: 250.00,
      );
      expect(cappedFixedService.calculateDepositAmount(), 150.00);
    });

    test('Business model handles Stripe Connect fields', () {
      final json = {
        'id': 'biz-1',
        'owner_id': 'owner-1',
        'name': 'Apex Dental',
        'slug': 'apex-dental',
        'category': 'dental',
        'booking_model': 'slot_based',
        'stripe_account_id': 'acct_123456789',
        'stripe_charges_enabled': true,
        'platform_fee_percent': 3.5,
        'platform_fee_fixed': 0.30,
        'settings': {},
      };

      final business = Business.fromJson(json);
      expect(business.stripeAccountId, 'acct_123456789');
      expect(business.stripeChargesEnabled, true);
      expect(business.platformFeePercent, 3.5);
      expect(business.platformFeeFixed, 0.30);

      final encoded = business.toJson();
      expect(encoded['stripe_account_id'], 'acct_123456789');
      expect(encoded['stripe_charges_enabled'], true);
      expect(encoded['platform_fee_percent'], 3.5);
      expect(encoded['platform_fee_fixed'], 0.30);
    });
  });
}
