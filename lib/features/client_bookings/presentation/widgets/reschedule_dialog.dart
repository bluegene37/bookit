// Gene - Nov, 05, 2026: Tactile Neumorphic Reschedule Appointment Dialog supporting slot-based and date-range models
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/booking.dart';
import '../../../../services/booking_service.dart';
// Gene - Nov 07, 2026: Added SlotCalculator, Business, and SupabaseService imports for conflict-safe rescheduling
import '../../../../models/business.dart';
import '../../../../services/business_service.dart';
import '../../../../services/supabase_service.dart';
import '../../../booking_engine/domain/slot_calculator.dart';

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

/*
// Gene - Nov, 05, 2026: Original _RescheduleBookingDialogState using raw TimePicker without SlotCalculator conflict checks
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
  ...
}
*/

// Gene - Nov 07, 2026: Conflict-safe RescheduleBookingDialog using SlotCalculator time slots (excluding current booking ID)
// Gene - Nov, 22, 2026: Use businessStaffProvider, advanceBookingDays/minNoticeHours, awaited reschedule RPC feedback, and universal wording
class _RescheduleBookingDialogState extends ConsumerState<RescheduleBookingDialog> {
  late DateTime _selectedDate;
  TimeSlot? _selectedSlot;
  DateTimeRange? _selectedDateRange;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.booking.isSlotBased) {
      final candidate = widget.booking.startTime?.add(const Duration(days: 1)) ??
          DateTime.now().add(const Duration(days: 1));
      _selectedDate = candidate.weekday == DateTime.sunday
          ? candidate.add(const Duration(days: 1))
          : candidate;
    } else {
      final from = widget.booking.dateFrom?.add(const Duration(days: 3)) ??
          DateTime.now().add(const Duration(days: 3));
      final to = widget.booking.dateTo?.add(const Duration(days: 3)) ??
          DateTime.now().add(const Duration(days: 6));
      _selectedDateRange = DateTimeRange(start: from, end: to);
      _selectedDate = from;
    }
  }

  void _handlePickDate(Business business) async {
    final minCutoff = DateTime.now().add(Duration(hours: business.minNoticeHours));
    final firstDate = DateTime(minCutoff.year, minCutoff.month, minCutoff.day);
    final lastDate = firstDate.add(Duration(days: business.advanceBookingDays));
    final initial = _selectedDate.isBefore(firstDate)
        ? firstDate
        : (_selectedDate.isAfter(lastDate) ? lastDate : _selectedDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
    }
  }

  void _handlePickDateRange(Business business) async {
    final minCutoff = DateTime.now().add(Duration(hours: business.minNoticeHours));
    final firstDate = DateTime(minCutoff.year, minCutoff.month, minCutoff.day);
    final lastDate = firstDate.add(
      Duration(days: business.advanceBookingDays > 180 ? business.advanceBookingDays : 180),
    );
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  Future<void> _submitReschedule(TimeSlot? activeSlot) async {
    setState(() => _isSubmitting = true);
    try {
      if (widget.booking.isSlotBased) {
        if (activeSlot == null) {
          setState(() => _isSubmitting = false);
          return;
        }
        await ref.read(bookingsProvider.notifier).rescheduleBooking(
              bookingId: widget.booking.id,
              newStartTime: activeSlot.startTime,
              newEndTime: activeSlot.endTime,
            );
      } else if (_selectedDateRange != null) {
        await ref.read(bookingsProvider.notifier).rescheduleBooking(
              bookingId: widget.booking.id,
              newDateFrom: _selectedDateRange!.start,
              newDateTo: _selectedDateRange!.end,
            );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking with ${widget.booking.businessName ?? 'provider'} rescheduled successfully!',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: NeumorphicColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not reschedule: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: NeumorphicColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final textPrimary = isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;
    final textSecondary = isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary;

    final business = ref.watch(businessDetailProvider(widget.booking.businessId)).valueOrNull ??
        SupabaseService.mockBusinesses
            .where((b) => b.id == widget.booking.businessId)
            .firstOrNull ??
        Business.fallback(
          id: widget.booking.businessId,
          name: widget.booking.businessName ?? 'BookIt Business',
        );

    final staffList = ref.watch(businessStaffProvider(widget.booking.businessId)).valueOrNull ??
        SupabaseService.mockStaff;
    final staffMember = widget.booking.staffId != null
        ? staffList.where((s) => s.id == widget.booking.staffId).firstOrNull
        : null;

    final otherBookings = ref
        .watch(bookingsProvider)
        .where((b) => b.businessId == widget.booking.businessId && b.id != widget.booking.id)
        .toList();

    final durationMinutes = (widget.booking.endTime != null && widget.booking.startTime != null)
        ? widget.booking.endTime!.difference(widget.booking.startTime!).inMinutes
        : business.slotIntervalMinutes;

    final slots = widget.booking.isSlotBased
        ? SlotCalculator.calculateAvailableSlots(
            business: business,
            date: _selectedDate,
            existingBookings: otherBookings,
            customDurationMinutes: durationMinutes > 0 ? durationMinutes : null,
            filterStaffId: widget.booking.staffId,
            staffMember: staffMember,
          )
        : <TimeSlot>[];

    final effectiveSlot = _selectedSlot != null &&
            slots.any((s) => s.isAvailable && s.startTime == _selectedSlot!.startTime)
        ? _selectedSlot
        : slots.where((s) => s.isAvailable).firstOrNull;

    return AlertDialog(
      title: Text(
        'Reschedule ${business.bookingLabel}',
        style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a conflict-free date and time for your visit at ${widget.booking.businessName}.',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: 16),

              if (widget.booking.isSlotBased) ...[
                // Date Picker Field
                Text('New Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 6),
                NeumorphicContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  borderRadius: 14,
                  onTap: () => _handlePickDate(business),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                        style: TextStyle(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w600),
                      ),
                      Icon(Icons.calendar_today_rounded, size: 18, color: accent),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Available Slots Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Time Slots ($durationMinutes min)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    Text(
                      '${slots.where((s) => s.isAvailable).length} open',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (slots.where((s) => s.isAvailable).isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: NeumorphicColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'No available slots on this date. Please choose another date.',
                      style: TextStyle(fontSize: 12, color: NeumorphicColors.error, fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slots.map((slot) {
                      final isSelected = effectiveSlot?.startTime == slot.startTime;
                      if (!slot.isAvailable) {
                        return Opacity(
                          opacity: 0.35,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              slot.formattedTime,
                              style: const TextStyle(
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        );
                      }
                      return ChoiceChip(
                        label: Text(
                          slot.formattedTime,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? accent : textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: accent.withValues(alpha: 0.18),
                        onSelected: (_) => setState(() => _selectedSlot = slot),
                      );
                    }).toList(),
                  ),
              ] else ...[
                // Date Range Picker Field
                Text('New Stay Date Range', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 6),
                NeumorphicContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  borderRadius: 14,
                  onTap: () => _handlePickDateRange(business),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        NeumorphicButton(
          isPrimary: true,
          isLoading: _isSubmitting,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          onPressed: (!_isSubmitting && (!widget.booking.isSlotBased || effectiveSlot != null))
              ? () => _submitReschedule(effectiveSlot)
              : null,
          child: const Text('Confirm Reschedule', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
