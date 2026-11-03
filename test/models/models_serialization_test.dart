// Gene - Nov, 03, 2026: Unit tests verifying data model serialization and JSON decoding
import 'package:bookit/models/business.dart';
import 'package:bookit/models/booking.dart';
import 'package:bookit/models/service_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Data Models Serialization Tests', () {
    test('Business parses JSON with slot_based model correctly', () {
      final json = {
        'id': 'b1-uuid',
        'owner_id': 'owner-1',
        'name': 'Apex Dental',
        'slug': 'apex-dental',
        'category': 'dental',
        'booking_model': 'slot_based',
        'settings': {
          'slot_interval_minutes': 45,
          'buffer_minutes': 15,
          'requires_approval': true,
        },
        'rating_avg': 4.95,
        'rating_count': 120,
        'is_active': true,
      };

      final business = Business.fromJson(json);
      expect(business.id, 'b1-uuid');
      expect(business.name, 'Apex Dental');
      expect(business.bookingModel, BookingModelType.slotBased);
      expect(business.slotIntervalMinutes, 45);
      expect(business.bufferMinutes, 15);
      expect(business.requiresApproval, true);
    });

    test('Booking parses slot_based schedule accurately', () {
      final json = {
        'id': 'bk-1',
        'business_id': 'b1-uuid',
        'client_id': 'c1-uuid',
        'booking_model': 'slot_based',
        'start_time': '2026-11-10T10:00:00.000Z',
        'end_time': '2026-11-10T10:45:00.000Z',
        'status': 'confirmed',
        'total_price': 150.0,
        'created_at': '2026-11-03T12:00:00.000Z',
      };

      final booking = Booking.fromJson(json);
      expect(booking.isSlotBased, true);
      expect(booking.status, 'confirmed');
      expect(booking.totalPrice, 150.0);
      expect(booking.startTime, isNotNull);
      expect(booking.formattedSchedule, contains('10:00 AM'));
    });

    test('Booking parses date_range model accurately', () {
      final json = {
        'id': 'bk-2',
        'business_id': 'b2-uuid',
        'client_id': 'c2-uuid',
        'booking_model': 'date_range',
        'date_from': '2026-12-01',
        'date_to': '2026-12-05',
        'status': 'pending',
        'total_price': 1800.0,
        'created_at': '2026-11-03T12:00:00.000Z',
      };

      final booking = Booking.fromJson(json);
      expect(booking.isDateRange, true);
      expect(booking.formattedSchedule, contains('4 days'));
    });

    test('ServiceItem formats price and duration nicely', () {
      final service = ServiceItem(
        id: 's1',
        businessId: 'b1',
        name: 'Teeth Whitening',
        durationMinutes: 60,
        price: 350.00,
      );

      expect(service.formattedPrice, '\$350.0');
      expect(service.formattedDuration, '60 min');
    });
  });
}
