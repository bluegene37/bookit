// Gene - Nov, 03, 2026: Time Slot calculation engine for appointment-based clinics
import 'package:intl/intl.dart';
import '../../../models/business.dart';
import '../../../models/booking.dart';

class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  String get formattedTime => DateFormat('h:mm a').format(startTime);
  String get formattedRange =>
      '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}';
}

class SlotCalculator {
  SlotCalculator._();

  // Gene - Nov, 04, 2026: Enhanced slot availability to check 15-minute reservation hold on awaiting_payment
  static bool isSlotOccupied({
    required DateTime slotStart,
    required DateTime slotEnd,
    required List<Booking> bookings,
    String? staffId,
  }) {
    final now = DateTime.now();
    for (final b in bookings) {
      if (staffId != null && b.staffId != null && b.staffId != staffId) {
        continue;
      }

      // Ignore cancelled or rejected bookings
      if (b.status == 'cancelled' || b.status == 'rejected') continue;

      // Check awaiting_payment expiration
      if (b.status == 'awaiting_payment') {
        if (b.holdExpiresAt == null || b.holdExpiresAt!.isBefore(now)) {
          continue; // Expired lock, slot is free
        }
      }

      if (b.startTime != null && b.endTime != null) {
        // Overlap check: start1 < end2 && end1 > start2
        if (slotStart.isBefore(b.endTime!) && slotEnd.isAfter(b.startTime!)) {
          return true;
        }
      }
    }
    return false;
  }

  static List<TimeSlot> calculateAvailableSlots({
    required Business business,
    required DateTime date,
    required List<Booking> existingBookings,
    int? customDurationMinutes,
    String? filterStaffId,
  }) {
    final weekdayName = DateFormat('EEEE').format(date).toLowerCase();
    final workingHoursMap = business.workingHours;

    if (workingHoursMap == null || !workingHoursMap.containsKey(weekdayName)) {
      return _generateDefaultSlots(date, business.slotIntervalMinutes, existingBookings, filterStaffId);
    }

    final dayConfig = workingHoursMap[weekdayName] as Map<String, dynamic>?;
    if (dayConfig == null || dayConfig['is_open'] == false) {
      return []; // Business closed on this day
    }

    final openStr = dayConfig['open'] as String? ?? '09:00';
    final closeStr = dayConfig['close'] as String? ?? '18:00';

    final openParts = openStr.split(':').map(int.parse).toList();
    final closeParts = closeStr.split(':').map(int.parse).toList();

    final dayStart = DateTime(date.year, date.month, date.day, openParts[0], openParts[1]);
    final dayEnd = DateTime(date.year, date.month, date.day, closeParts[0], closeParts[1]);

    final interval = customDurationMinutes ?? business.slotIntervalMinutes;
    final List<TimeSlot> slots = [];

    DateTime current = dayStart;
    while (current.add(Duration(minutes: interval)).isBefore(dayEnd) ||
        current.add(Duration(minutes: interval)).isAtSameMomentAs(dayEnd)) {
      final slotEnd = current.add(Duration(minutes: interval));

      /*
      // Check conflict with active bookings
      final hasConflict = existingBookings.any((booking) {
        if (booking.status == 'cancelled' || booking.status == 'rejected') {
          return false;
        }

        // If filtering by specific doctor/staff, only check their conflicts
        if (filterStaffId != null && booking.staffId != null && booking.staffId != filterStaffId) {
          return false;
        }

        if (booking.startTime == null || booking.endTime == null) return false;

        // Overlap: slotStart < bookingEnd AND slotEnd > bookingStart
        return current.isBefore(booking.endTime!) && slotEnd.isAfter(booking.startTime!);
      });
      */

      // Gene - Nov, 04, 2026: Delegate conflict check to isSlotOccupied for awaiting_payment lock handling
      final hasConflict = isSlotOccupied(
        slotStart: current,
        slotEnd: slotEnd,
        bookings: existingBookings,
        staffId: filterStaffId,
      );

      slots.add(TimeSlot(
        startTime: current,
        endTime: slotEnd,
        isAvailable: !hasConflict,
      ));

      current = current.add(Duration(minutes: interval));
    }

    return slots;
  }

  static List<TimeSlot> _generateDefaultSlots(
    DateTime date,
    int interval,
    List<Booking> existingBookings,
    String? filterStaffId,
  ) {
    final dayStart = DateTime(date.year, date.month, date.day, 9, 0);
    final dayEnd = DateTime(date.year, date.month, date.day, 17, 0);

    final List<TimeSlot> slots = [];
    DateTime current = dayStart;
    while (current.add(Duration(minutes: interval)).isBefore(dayEnd) ||
        current.add(Duration(minutes: interval)).isAtSameMomentAs(dayEnd)) {
      final slotEnd = current.add(Duration(minutes: interval));
      /*
      final hasConflict = existingBookings.any((b) =>
          b.status != 'cancelled' &&
          b.status != 'rejected' &&
          (filterStaffId == null || b.staffId == null || b.staffId == filterStaffId) &&
          b.startTime != null &&
          b.endTime != null &&
          current.isBefore(b.endTime!) &&
          slotEnd.isAfter(b.startTime!));
      */

      // Gene - Nov, 04, 2026: Delegate conflict check to isSlotOccupied for awaiting_payment lock handling
      final hasConflict = isSlotOccupied(
        slotStart: current,
        slotEnd: slotEnd,
        bookings: existingBookings,
        staffId: filterStaffId,
      );

      slots.add(TimeSlot(
        startTime: current,
        endTime: slotEnd,
        isAvailable: !hasConflict,
      ));

      current = current.add(Duration(minutes: interval));
    }
    return slots;
  }
}
