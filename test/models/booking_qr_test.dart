import 'package:flutter_test/flutter_test.dart';
import 'package:bookit/models/booking.dart';

void main() {
  group('Booking QR & Reception Model Extensions', () {
    test('supports checked_in and in_service statuses with timestamps and qrToken', () {
      final now = DateTime.now();
      final tenMinutesAgo = now.subtract(const Duration(minutes: 10));

      final booking = Booking(
        id: 'b-101',
        businessId: 'biz-1',
        clientId: 'c-1',
        bookingModel: 'slot_based',
        totalPrice: 120.0,
        createdAt: now,
        status: 'checked_in',
        checkedInAt: tenMinutesAgo,
        qrToken: 'BK-A8F29C',
      );

      expect(booking.isCheckedIn, isTrue);
      expect(booking.isInService, isFalse);
      expect(booking.qrToken, equals('BK-A8F29C'));
      expect(booking.currentWaitDuration?.inMinutes, greaterThanOrEqualTo(9));
    });

    test('copyWith updates checkedInAt, inServiceAt, and status immutably', () {
      final now = DateTime.now();
      final booking = Booking(
        id: 'b-102',
        businessId: 'biz-1',
        clientId: 'c-1',
        bookingModel: 'slot_based',
        totalPrice: 100.0,
        createdAt: now,
        status: 'confirmed',
      );

      final checkedIn = booking.copyWith(
        status: 'checked_in',
        checkedInAt: now,
        qrToken: 'BK-Z9921',
      );

      expect(checkedIn.status, equals('checked_in'));
      expect(checkedIn.checkedInAt, equals(now));
      expect(checkedIn.qrToken, equals('BK-Z9921'));
      expect(booking.status, equals('confirmed')); // Original unchanged
    });

    test('in_service status updates isInService and calculates fixed waitDuration', () {
      final now = DateTime.now();
      final twentyMinsAgo = now.subtract(const Duration(minutes: 20));
      final fiveMinsAgo = now.subtract(const Duration(minutes: 5));

      final booking = Booking(
        id: 'b-103',
        businessId: 'biz-1',
        clientId: 'c-1',
        bookingModel: 'slot_based',
        totalPrice: 150.0,
        createdAt: twentyMinsAgo,
        status: 'in_service',
        checkedInAt: twentyMinsAgo,
        inServiceAt: fiveMinsAgo,
        qrToken: 'BK-SRV103',
      );

      expect(booking.isCheckedIn, isFalse);
      expect(booking.isInService, isTrue);
      expect(booking.currentWaitDuration?.inMinutes, equals(15));
    });

    test('fromJson and toJson serialize check-in timestamps and fallback qrToken correctly', () {
      final now = DateTime.now();
      final json = {
        'id': 'b-104-xyz',
        'business_id': 'biz-1',
        'client_id': 'c-1',
        'booking_model': 'slot_based',
        'total_price': 80.0,
        'created_at': now.toIso8601String(),
        'status': 'checked_in',
        'checked_in_at': now.toIso8601String(),
      };

      final booking = Booking.fromJson(json);
      expect(booking.checkedInAt, isNotNull);
      // Fallback qrToken should be BK- prefix with uppercase first 6 chars of id
      expect(booking.qrToken, equals('BK-B-104-'));

      final serialized = booking.toJson();
      expect(serialized['checked_in_at'], equals(now.toIso8601String()));
      expect(serialized['qr_token'], equals('BK-B-104-'));
    });
  });
}
