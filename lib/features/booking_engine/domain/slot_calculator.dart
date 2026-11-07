// Gene - Nov, 03, 2026: Time Slot calculation engine for appointment-based clinics
import 'package:intl/intl.dart';
import '../../../models/business.dart';
import '../../../models/booking.dart';
// Gene - Nov 06, 2026: Added business_staff import for shift matrix & break schedule enforcement
import '../../../models/business_staff.dart';

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

  /*
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
  */

  // Gene - Nov 07, 2026: Enhanced slot occupancy check to enforce post-appointment turnaround bufferMinutes
  static bool isSlotOccupied({
    required DateTime slotStart,
    required DateTime slotEnd,
    required List<Booking> bookings,
    String? staffId,
    int bufferMinutes = 0,
  }) {
    final now = DateTime.now();
    final effectiveSlotEnd = slotEnd.add(Duration(minutes: bufferMinutes));
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
        final effectiveBookingEnd = b.endTime!.add(Duration(minutes: bufferMinutes));
        // Overlap check including post-appointment buffer: start1 < (end2 + buffer) && (end1 + buffer) > start2
        if (slotStart.isBefore(effectiveBookingEnd) && effectiveSlotEnd.isAfter(b.startTime!)) {
          return true;
        }
      }
    }
    return false;
  }

  // Gene - Nov 06, 2026: Helper to check if slot falls within staff shift hours and outside lunch break
  static bool isWithinStaffShift({
    required DateTime slotStart,
    required DateTime slotEnd,
    required BusinessStaff staff,
    required String weekdayName,
  }) {
    if (!staff.isWorkingOn(weekdayName)) return false;

    try {
      final startStr = staff.shiftStart(weekdayName);
      final endStr = staff.shiftEnd(weekdayName);

      final startParts = startStr.split(':').map(int.parse).toList();
      final endParts = endStr.split(':').map(int.parse).toList();

      final shiftStart = DateTime(slotStart.year, slotStart.month, slotStart.day, startParts[0], startParts[1]);
      final shiftEnd = DateTime(slotStart.year, slotStart.month, slotStart.day, endParts[0], endParts[1]);

      if (slotStart.isBefore(shiftStart) || slotEnd.isAfter(shiftEnd)) {
        return false;
      }

      if (staff.hasBreak(weekdayName)) {
        final bStartStr = staff.breakStart(weekdayName);
        final bEndStr = staff.breakEnd(weekdayName);
        final bStartParts = bStartStr.split(':').map(int.parse).toList();
        final bEndParts = bEndStr.split(':').map(int.parse).toList();

        final breakStart = DateTime(slotStart.year, slotStart.month, slotStart.day, bStartParts[0], bStartParts[1]);
        final breakEnd = DateTime(slotStart.year, slotStart.month, slotStart.day, bEndParts[0], bEndParts[1]);

        // Conflict if slot overlaps with break: slotStart < breakEnd && slotEnd > breakStart
        if (slotStart.isBefore(breakEnd) && slotEnd.isAfter(breakStart)) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return true; // Defensive fallback if time string parsing fails
    }
  }

  /*
  // Gene - Nov, 04, 2026: Previous calculateAvailableSlots without staff shift and lunch break awareness
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
  */

  /*
  // Gene - Nov 06, 2026: Enhanced calculateAvailableSlots with practitioner shift hours and lunch break suppression
  static List<TimeSlot> calculateAvailableSlots({
    required Business business,
    required DateTime date,
    required List<Booking> existingBookings,
    int? customDurationMinutes,
    String? filterStaffId,
    BusinessStaff? staffMember,
  }) {
    final weekdayName = DateFormat('EEEE').format(date).toLowerCase();
    final workingHoursMap = business.workingHours;

    if (workingHoursMap == null || !workingHoursMap.containsKey(weekdayName)) {
      return _generateDefaultSlots(
        date,
        business.slotIntervalMinutes,
        existingBookings,
        filterStaffId,
        staffMember: staffMember,
      );
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

      final hasConflict = isSlotOccupied(
        slotStart: current,
        slotEnd: slotEnd,
        bookings: existingBookings,
        staffId: filterStaffId,
      );

      final isStaffAvailable = staffMember != null
          ? isWithinStaffShift(
              slotStart: current,
              slotEnd: slotEnd,
              staff: staffMember,
              weekdayName: weekdayName,
            )
          : true;

      slots.add(TimeSlot(
        startTime: current,
        endTime: slotEnd,
        isAvailable: !hasConflict && isStaffAvailable,
      ));

      current = current.add(Duration(minutes: interval));
    }

    return slots;
  }
  */

  // Gene - Nov 07, 2026: Step start times by slotIntervalMinutes while sizing candidate slots by customDurationMinutes and enforcing business.bufferMinutes
  static List<TimeSlot> calculateAvailableSlots({
    required Business business,
    required DateTime date,
    required List<Booking> existingBookings,
    int? customDurationMinutes,
    String? filterStaffId,
    BusinessStaff? staffMember,
  }) {
    final weekdayName = DateFormat('EEEE').format(date).toLowerCase();
    final workingHoursMap = business.workingHours;
    final stepInterval = business.slotIntervalMinutes > 0 ? business.slotIntervalMinutes : 30;
    final slotDuration = (customDurationMinutes != null && customDurationMinutes > 0)
        ? customDurationMinutes
        : stepInterval;
    // Gene - Nov 07, 2026: Pre-filter existingBookings to target date and practitioner before iterating candidate slots
    final dayBookings = filterBookingsForDate(
      existingBookings,
      date,
      staffId: filterStaffId,
    );

    if (workingHoursMap == null || !workingHoursMap.containsKey(weekdayName)) {
      return _generateDefaultSlots(
        date,
        stepInterval,
        dayBookings,
        filterStaffId,
        staffMember: staffMember,
        slotDurationMinutes: slotDuration,
        bufferMinutes: business.bufferMinutes,
      );
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

    final List<TimeSlot> slots = [];

    DateTime current = dayStart;
    while (current.add(Duration(minutes: slotDuration)).isBefore(dayEnd) ||
        current.add(Duration(minutes: slotDuration)).isAtSameMomentAs(dayEnd)) {
      final slotEnd = current.add(Duration(minutes: slotDuration));

      final hasConflict = isSlotOccupied(
        slotStart: current,
        slotEnd: slotEnd,
        bookings: dayBookings,
        staffId: filterStaffId,
        bufferMinutes: business.bufferMinutes,
      );

      final isStaffAvailable = staffMember != null
          ? isWithinStaffShift(
              slotStart: current,
              slotEnd: slotEnd,
              staff: staffMember,
              weekdayName: weekdayName,
            )
          : true;

      slots.add(TimeSlot(
        startTime: current,
        endTime: slotEnd,
        isAvailable: !hasConflict && isStaffAvailable,
      ));

      current = current.add(Duration(minutes: stepInterval));
    }

    return slots;
  }

  /*
  // Gene - Nov, 04, 2026: Previous _generateDefaultSlots without staff shift and lunch break awareness
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
  */

  /*
  // Gene - Nov 06, 2026: Enhanced _generateDefaultSlots with practitioner shift hours and lunch break suppression
  static List<TimeSlot> _generateDefaultSlots(
    DateTime date,
    int interval,
    List<Booking> existingBookings,
    String? filterStaffId, {
    BusinessStaff? staffMember,
  }) {
    final dayStart = DateTime(date.year, date.month, date.day, 9, 0);
    final dayEnd = DateTime(date.year, date.month, date.day, 17, 0);
    final weekdayName = DateFormat('EEEE').format(date).toLowerCase();

    final List<TimeSlot> slots = [];
    DateTime current = dayStart;
    while (current.add(Duration(minutes: interval)).isBefore(dayEnd) ||
        current.add(Duration(minutes: interval)).isAtSameMomentAs(dayEnd)) {
      final slotEnd = current.add(Duration(minutes: interval));

      final hasConflict = isSlotOccupied(
        slotStart: current,
        slotEnd: slotEnd,
        bookings: existingBookings,
        staffId: filterStaffId,
      );

      final isStaffAvailable = staffMember != null
          ? isWithinStaffShift(
              slotStart: current,
              slotEnd: slotEnd,
              staff: staffMember,
              weekdayName: weekdayName,
            )
          : true;

      slots.add(TimeSlot(
        startTime: current,
        endTime: slotEnd,
        isAvailable: !hasConflict && isStaffAvailable,
      ));

      current = current.add(Duration(minutes: interval));
    }
    return slots;
  }
  */

  // Gene - Nov 07, 2026: Enhanced _generateDefaultSlots to support custom service duration and post-appointment bufferMinutes
  static List<TimeSlot> _generateDefaultSlots(
    DateTime date,
    int stepInterval,
    List<Booking> existingBookings,
    String? filterStaffId, {
    BusinessStaff? staffMember,
    int? slotDurationMinutes,
    int bufferMinutes = 0,
  }) {
    final dayStart = DateTime(date.year, date.month, date.day, 9, 0);
    final dayEnd = DateTime(date.year, date.month, date.day, 17, 0);
    final weekdayName = DateFormat('EEEE').format(date).toLowerCase();
    final duration = slotDurationMinutes ?? stepInterval;

    final List<TimeSlot> slots = [];
    DateTime current = dayStart;
    while (current.add(Duration(minutes: duration)).isBefore(dayEnd) ||
        current.add(Duration(minutes: duration)).isAtSameMomentAs(dayEnd)) {
      final slotEnd = current.add(Duration(minutes: duration));

      final hasConflict = isSlotOccupied(
        slotStart: current,
        slotEnd: slotEnd,
        bookings: existingBookings,
        staffId: filterStaffId,
        bufferMinutes: bufferMinutes,
      );

      final isStaffAvailable = staffMember != null
          ? isWithinStaffShift(
              slotStart: current,
              slotEnd: slotEnd,
              staff: staffMember,
              weekdayName: weekdayName,
            )
          : true;

      slots.add(TimeSlot(
        startTime: current,
        endTime: slotEnd,
        isAvailable: !hasConflict && isStaffAvailable,
      ));

      current = current.add(Duration(minutes: stepInterval));
    }
    return slots;
  }

  // Gene - Nov 07, 2026: Pre-filter bookings to target calendar day, business, and practitioner to reduce slot calculation complexity to O(S * N_day)
  static List<Booking> filterBookingsForDate(
    List<Booking> bookings,
    DateTime date, {
    String? businessId,
    String? staffId,
  }) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return bookings.where((b) {
      if (businessId != null && b.businessId != businessId) return false;
      if (staffId != null && b.staffId != null && b.staffId != staffId) return false;
      if (b.status == 'cancelled' || b.status == 'rejected') return false;
      if (b.startTime == null || b.endTime == null) return false;
      return b.startTime!.isBefore(dayEnd) && b.endTime!.isAfter(dayStart);
    }).toList();
  }

  // Gene - Nov 07, 2026: Parse PostgreSQL `get_available_slots` RPC rows into TimeSlot objects while enforcing practitioner shift and break rules
  static List<TimeSlot> fromRpcResponse(
    List<dynamic> rpcRows, {
    BusinessStaff? staffMember,
  }) {
    final List<TimeSlot> slots = [];
    for (final raw in rpcRows) {
      if (raw is! Map) continue;
      final startRaw = raw['slot_start']?.toString();
      final endRaw = raw['slot_end']?.toString();
      if (startRaw == null || endRaw == null) continue;

      final startTime = DateTime.tryParse(startRaw)?.toLocal();
      final endTime = DateTime.tryParse(endRaw)?.toLocal();
      if (startTime == null || endTime == null) continue;

      final rpcAvailable = raw['is_available'] as bool? ?? true;
      final weekdayName = DateFormat('EEEE').format(startTime).toLowerCase();

      final isStaffAvailable = staffMember != null
          ? isWithinStaffShift(
              slotStart: startTime,
              slotEnd: endTime,
              staff: staffMember,
              weekdayName: weekdayName,
            )
          : true;

      slots.add(
        TimeSlot(
          startTime: startTime,
          endTime: endTime,
          isAvailable: rpcAvailable && isStaffAvailable,
        ),
      );
    }
    return slots;
  }
}
