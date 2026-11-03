// Gene - Nov, 03, 2026: Unit test for slot calculation engine
import 'package:bookit/features/booking_engine/domain/slot_calculator.dart';
import 'package:bookit/models/business.dart';
import 'package:bookit/models/booking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SlotCalculator Tests', () {
    late Business dentalClinic;

    setUp(() {
      dentalClinic = Business(
        id: 'clinic-1',
        ownerId: 'owner-1',
        name: 'Apex Dental',
        slug: 'apex-dental',
        category: 'dental',
        bookingModel: BookingModelType.slotBased,
        settings: {
          'slot_interval_minutes': 30,
          'working_hours': {
            'monday': {'open': '09:00', 'close': '11:00', 'is_open': true},
            'sunday': {'open': '00:00', 'close': '00:00', 'is_open': false},
          },
        },
      );
    });

    test('generates expected time slots for open weekday', () {
      // Nov 9, 2026 is a Monday
      final monday = DateTime(2026, 11, 9);
      final slots = SlotCalculator.calculateAvailableSlots(
        business: dentalClinic,
        date: monday,
        existingBookings: [],
      );

      // From 09:00 to 11:00 in 30-min intervals: 09:00, 09:30, 10:00, 10:30 (4 slots)
      expect(slots.length, 4);
      expect(slots[0].formattedTime, '9:00 AM');
      expect(slots[3].formattedTime, '10:30 AM');
      expect(slots.every((s) => s.isAvailable), true);
    });

    test('returns empty slot list when clinic is closed on Sunday', () {
      // Nov 8, 2026 is a Sunday
      final sunday = DateTime(2026, 11, 8);
      final slots = SlotCalculator.calculateAvailableSlots(
        business: dentalClinic,
        date: sunday,
        existingBookings: [],
      );

      expect(slots.isEmpty, true);
    });

    test('marks slot as unavailable when conflicting booking exists', () {
      final monday = DateTime(2026, 11, 9);
      final booked10AM = Booking(
        id: 'bk-1',
        businessId: 'clinic-1',
        clientId: 'patient-1',
        bookingModel: 'slot_based',
        startTime: DateTime(2026, 11, 9, 9, 30),
        endTime: DateTime(2026, 11, 9, 10, 0),
        status: 'confirmed',
        totalPrice: 100.0,
        createdAt: DateTime.now(),
      );

      final slots = SlotCalculator.calculateAvailableSlots(
        business: dentalClinic,
        date: monday,
        existingBookings: [booked10AM],
      );

      expect(slots[0].isAvailable, true); // 09:00
      expect(slots[1].isAvailable, false); // 09:30 - booked!
      expect(slots[2].isAvailable, true); // 10:00
      expect(slots[3].isAvailable, true); // 10:30
    });

    test('ignores cancelled bookings when checking availability', () {
      final monday = DateTime(2026, 11, 9);
      final cancelledBooking = Booking(
        id: 'bk-cancelled',
        businessId: 'clinic-1',
        clientId: 'patient-1',
        bookingModel: 'slot_based',
        startTime: DateTime(2026, 11, 9, 9, 30),
        endTime: DateTime(2026, 11, 9, 10, 0),
        status: 'cancelled',
        totalPrice: 100.0,
        createdAt: DateTime.now(),
      );

      final slots = SlotCalculator.calculateAvailableSlots(
        business: dentalClinic,
        date: monday,
        existingBookings: [cancelledBooking],
      );

      expect(slots[1].isAvailable, true);
    });
  });
}
