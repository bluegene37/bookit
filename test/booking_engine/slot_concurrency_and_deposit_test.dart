import 'package:flutter_test/flutter_test.dart';
import 'package:bookit/features/booking_engine/domain/slot_calculator.dart';
import 'package:bookit/models/booking.dart';
import 'package:bookit/models/service_item.dart';
import 'package:bookit/features/booking_engine/providers/booking_wizard_provider.dart';

void main() {
  group('Slot Concurrency & Lock Expiration', () {
    test('Active awaiting_payment booking within 15 mins blocks slot', () {
      final now = DateTime.now();
      final targetSlotStart = DateTime(now.year, now.month, now.day, 10, 0);
      final targetSlotEnd = DateTime(now.year, now.month, now.day, 10, 30);

      final activeLockBooking = Booking(
        id: 'bk-lock-1',
        businessId: 'biz-1',
        clientId: 'usr-1',
        bookingModel: 'slot_based',
        startTime: targetSlotStart,
        endTime: targetSlotEnd,
        status: 'awaiting_payment',
        holdExpiresAt: now.add(const Duration(minutes: 10)),
        totalPrice: 100.0,
        createdAt: now,
      );

      final isOccupied = SlotCalculator.isSlotOccupied(
        slotStart: targetSlotStart,
        slotEnd: targetSlotEnd,
        bookings: [activeLockBooking],
      );

      expect(isOccupied, isTrue);
    });

    test('Expired awaiting_payment booking releases slot for other customers', () {
      final now = DateTime.now();
      final targetSlotStart = DateTime(now.year, now.month, now.day, 10, 0);
      final targetSlotEnd = DateTime(now.year, now.month, now.day, 10, 30);

      final expiredBooking = Booking(
        id: 'bk-lock-2',
        businessId: 'biz-1',
        clientId: 'usr-2',
        bookingModel: 'slot_based',
        startTime: targetSlotStart,
        endTime: targetSlotEnd,
        status: 'awaiting_payment',
        holdExpiresAt: now.subtract(const Duration(minutes: 5)), // Expired 5 mins ago
        totalPrice: 100.0,
        createdAt: now.subtract(const Duration(minutes: 20)),
      );

      final isOccupied = SlotCalculator.isSlotOccupied(
        slotStart: targetSlotStart,
        slotEnd: targetSlotEnd,
        bookings: [expiredBooking],
      );

      expect(isOccupied, isFalse);
    });

    test('Deposit math calculates correctly for percentage and fixed', () {
      const srvPercentage = ServiceItem(
        id: 's1',
        businessId: 'b1',
        name: 'Auto Detail',
        price: 120.00,
        durationMinutes: 60,
        paymentPolicy: 'deposit',
        depositType: 'percentage',
        depositAmount: 25.00, // 25% of 120 = $30.00
      );
      expect(srvPercentage.calculateDepositAmount(), 30.00);

      const srvFixed = ServiceItem(
        id: 's2',
        businessId: 'b1',
        name: 'Dental Cleaning',
        price: 150.00,
        durationMinutes: 45,
        paymentPolicy: 'deposit',
        depositType: 'fixed',
        depositAmount: 35.00, // Fixed $35.00
      );
      expect(srvFixed.calculateDepositAmount(), 35.00);
    });

    test('BookingWizardState calculates deposit and balance amounts correctly', () {
      const srvPercentage = ServiceItem(
        id: 's1',
        businessId: 'b1',
        name: 'Auto Detail',
        price: 120.00,
        durationMinutes: 60,
        paymentPolicy: 'deposit',
        depositType: 'percentage',
        depositAmount: 25.00,
      );

      final stateDeposit = BookingWizardState(selectedService: srvPercentage);
      expect(stateDeposit.dueTodayAmount, 30.00);
      expect(stateDeposit.dueAtVenueAmount, 90.00);
      expect(stateDeposit.isDepositOnly, isTrue);
      expect(stateDeposit.isPayAtVenue, isFalse);

      const srvPayAtVenue = ServiceItem(
        id: 's3',
        businessId: 'b1',
        name: 'Consultation',
        price: 80.00,
        durationMinutes: 30,
        paymentPolicy: 'pay_at_venue',
      );

      final stateVenue = BookingWizardState(selectedService: srvPayAtVenue);
      expect(stateVenue.dueTodayAmount, 0.0);
      expect(stateVenue.dueAtVenueAmount, 80.0);
      expect(stateVenue.isDepositOnly, isFalse);
      expect(stateVenue.isPayAtVenue, isTrue);
    });
  });
}
