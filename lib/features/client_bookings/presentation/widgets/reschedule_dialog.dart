// Gene - Nov, 05, 2026: Tactile Neumorphic Reschedule Appointment Dialog supporting slot-based and date-range models
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/booking.dart';
import '../../../../services/booking_service.dart';

class RescheduleBookingDialog extends ConsumerStatefulWidget {
  final Booking booking;

  const RescheduleBookingDialog({super.key, required this.booking});

  static Future<void> show(BuildContext context, Booking booking) {
    return showDialog(
      context: context,
      builder: (ctx) => RescheduleBookingDialog(booking: booking),
    );
  }

  @override
  ConsumerState<RescheduleBookingDialog> createState() => _RescheduleBookingDialogState();
}

class _RescheduleBookingDialogState extends ConsumerState<RescheduleBookingDialog> {
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    if (widget.booking.isSlotBased) {
      _selectedDate = widget.booking.startTime?.add(const Duration(days: 1)) ?? DateTime.now().add(const Duration(days: 1));
      if (widget.booking.startTime != null) {
        _selectedTime = TimeOfDay.fromDateTime(widget.booking.startTime!);
      }
    } else {
      final from = widget.booking.dateFrom?.add(const Duration(days: 3)) ?? DateTime.now().add(const Duration(days: 3));
      final to = widget.booking.dateTo?.add(const Duration(days: 3)) ?? DateTime.now().add(const Duration(days: 6));
      _selectedDateRange = DateTimeRange(start: from, end: to);
      _selectedDate = from;
    }
  }

  void _handlePickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _handlePickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _handlePickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _submitReschedule() {
    if (widget.booking.isSlotBased) {
      final newStart = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final duration = widget.booking.endTime != null && widget.booking.startTime != null
          ? widget.booking.endTime!.difference(widget.booking.startTime!)
          : const Duration(minutes: 45);
      final newEnd = newStart.add(duration);

      ref.read(bookingsProvider.notifier).rescheduleBooking(
        bookingId: widget.booking.id,
        newStartTime: newStart,
        newEndTime: newEnd,
      );
    } else {
      if (_selectedDateRange != null) {
        ref.read(bookingsProvider.notifier).rescheduleBooking(
          bookingId: widget.booking.id,
          newDateFrom: _selectedDateRange!.start,
          newDateTo: _selectedDateRange!.end,
        );
      }
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appointment with ${widget.booking.businessName} rescheduled successfully!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: NeumorphicColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final textPrimary = isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;
    final textSecondary = isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary;

    return AlertDialog(
      title: Text('Reschedule Appointment', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a new date and time for your booking with ${widget.booking.businessName}.',
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
            const SizedBox(height: 18),

            if (widget.booking.isSlotBased) ...[
              // Date Picker Field
              Text('New Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 6),
              NeumorphicContainer(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                borderRadius: 14,
                onTap: _handlePickDate,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('EEE, MMM d, yyyy').format(_selectedDate), style: TextStyle(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w600)),
                    Icon(Icons.calendar_today_rounded, size: 18, color: accent),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Time Picker Field
              Text('New Time Slot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 6),
              NeumorphicContainer(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                borderRadius: 14,
                onTap: _handlePickTime,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_selectedTime.format(context), style: TextStyle(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w600)),
                    Icon(Icons.schedule_rounded, size: 18, color: accent),
                  ],
                ),
              ),
            ] else ...[
              // Date Range Picker Field
              Text('New Stay Date Range', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 6),
              NeumorphicContainer(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                borderRadius: 14,
                onTap: _handlePickDateRange,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDateRange != null
                          ? '${DateFormat('MMM d').format(_selectedDateRange!.start)} → ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.end)}'
                          : 'Select range',
                      style: TextStyle(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w600),
                    ),
                    Icon(Icons.date_range_rounded, size: 18, color: accent),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        NeumorphicButton(
          isPrimary: true,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          onPressed: _submitReschedule,
          child: const Text('Confirm Reschedule', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
