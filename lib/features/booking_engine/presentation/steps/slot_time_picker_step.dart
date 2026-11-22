// Gene - Nov, 03, 2026: Step 2A - Time Slot and Doctor picker for appointment-based clinics
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_chip.dart';
import '../../../../models/business.dart';
import '../../../../models/business_staff.dart';
import '../../../../models/booking.dart';
import '../../../../services/booking_service.dart';
import '../../../../services/supabase_service.dart';
import '../../domain/slot_calculator.dart';

/*
class SlotTimePickerStep extends StatelessWidget {
...
}
*/

// Gene - Nov, 22, 2026: Converted to StatefulWidget with live RPC slot fetching, dynamic advanceBookingDays & minNoticeHours bounds, and universal venue messaging
class SlotTimePickerStep extends StatefulWidget {
  final Business business;
  final List<BusinessStaff> staffList;
  final List<Booking> existingBookings;
  final DateTime selectedDate;
  final TimeSlot? selectedSlot;
  final BusinessStaff? selectedStaff;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<TimeSlot> onSlotSelected;
  final ValueChanged<BusinessStaff?> onStaffSelected;
  final int? serviceDurationMinutes;

  const SlotTimePickerStep({
    super.key,
    required this.business,
    required this.staffList,
    required this.existingBookings,
    required this.selectedDate,
    required this.selectedSlot,
    required this.selectedStaff,
    required this.onDateSelected,
    required this.onSlotSelected,
    required this.onStaffSelected,
    this.serviceDurationMinutes,
  });

  @override
  State<SlotTimePickerStep> createState() => _SlotTimePickerStepState();
}

class _SlotTimePickerStepState extends State<SlotTimePickerStep> {
  List<TimeSlot>? _liveSlots;
  bool _loadingLiveSlots = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadLiveSlots());
  }

  @override
  void didUpdateWidget(covariant SlotTimePickerStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.business.id != widget.business.id ||
        !DateUtils.isSameDay(oldWidget.selectedDate, widget.selectedDate) ||
        oldWidget.selectedStaff?.id != widget.selectedStaff?.id ||
        oldWidget.serviceDurationMinutes != widget.serviceDurationMinutes) {
      _maybeLoadLiveSlots();
    }
  }

  Future<void> _maybeLoadLiveSlots() async {
    if (SupabaseService.client == null) return;
    setState(() => _loadingLiveSlots = true);
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final slots = await container.read(bookingsProvider.notifier).fetchAvailableSlots(
            business: widget.business,
            date: widget.selectedDate,
            customDurationMinutes: widget.serviceDurationMinutes,
            filterStaffId: widget.selectedStaff?.id,
            staffMember: widget.selectedStaff,
          );
      if (mounted) {
        setState(() {
          _liveSlots = slots;
          _loadingLiveSlots = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLiveSlots = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final business = widget.business;
    final staffList = widget.staffList;
    final selectedDate = widget.selectedDate;
    final selectedSlot = widget.selectedSlot;
    final selectedStaff = widget.selectedStaff;

    final minNoticeCutoff = DateTime.now().add(Duration(hours: business.minNoticeHours));
    final firstSelectableDay = DateTime(minNoticeCutoff.year, minNoticeCutoff.month, minNoticeCutoff.day);
    final advanceDays = business.advanceBookingDays;

    final rawSlots = _liveSlots ??
        SlotCalculator.calculateAvailableSlots(
          business: business,
          date: selectedDate,
          existingBookings: widget.existingBookings,
          customDurationMinutes: widget.serviceDurationMinutes,
          filterStaffId: selectedStaff?.id,
          staffMember: selectedStaff,
        );

    final availableSlots = rawSlots
        .where((s) => !s.startTime.isBefore(minNoticeCutoff))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*
          // Gene - Nov, 03, 2026: Hardcoded staff selector
          if (staffList.isNotEmpty) ...[
            Text(
              'Select Specialist or Doctor',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  NeumorphicChip(
                    label: 'Any Specialist',
                    isSelected: selectedStaff == null,
                    onTap: () => onStaffSelected(null),
                  ),
                  const SizedBox(width: 10),
                  ...staffList.map((st) {
                    final isSelected = selectedStaff?.id == st.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: NeumorphicChip(
                        label: st.name,
                        subtitle: st.specialty,
                        isSelected: isSelected,
                        onTap: () => onStaffSelected(st),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          */
          // Gene - Nov, 04, 2026: Dynamic resource selector driven by business template ui_config
          if (business.showStaffSelection && staffList.isNotEmpty) ...[
            Text(
              'Select ${business.resourceLabel}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  NeumorphicChip(
                    label: 'Any ${business.resourceLabel}',
                    isSelected: selectedStaff == null,
                    onTap: () => widget.onStaffSelected(null),
                  ),
                  const SizedBox(width: 10),
                  ...staffList.map((st) {
                    final isSelected = selectedStaff?.id == st.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: NeumorphicChip(
                        label: st.name,
                        subtitle: st.specialty,
                        isSelected: isSelected,
                        onTap: () => widget.onStaffSelected(st),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 2. Horizontal Date Selector Strip (advanceBookingDays Window)
          Text(
            'Select Date',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: advanceDays,
              itemBuilder: (context, index) {
                final date = firstSelectableDay.add(Duration(days: index));
                final isSelected = DateUtils.isSameDay(date, selectedDate);
                final dayOfWeek = DateFormat('EEE').format(date);
                final dayNum = DateFormat('d').format(date);

                return Padding(
                  padding: const EdgeInsets.only(right: 10, bottom: 4),
                  child: GestureDetector(
                    onTap: () => widget.onDateSelected(date),
                    child: NeumorphicContainer(
                      width: 60,
                      borderRadius: 16.0,
                      isInset: isSelected,
                      border: isSelected ? Border.all(color: accent, width: 2) : null,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayOfWeek,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? accent : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayNum,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? accent : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 3. Time Slots Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Time Slots',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                ),
              ),
              Text(
                '${availableSlots.where((s) => s.isAvailable).length} slots open',
                style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_loadingLiveSlots) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            ),
          ] else if (availableSlots.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No available slots on ${DateFormat('EEEE, MMM d').format(selectedDate)}. This ${business.venueLabel.toLowerCase()} may be closed or outside its advance notice window.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                ),
              ),
            ),
          ] else ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: availableSlots.map((slot) {
                final isSelected = selectedSlot?.startTime == slot.startTime;

                if (!slot.isAvailable) {
                  return Opacity(
                    opacity: 0.35,
                    child: NeumorphicContainer(
                      borderRadius: 14.0,
                      isInset: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        slot.formattedTime,
                        style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 13),
                      ),
                    ),
                  );
                }

                return GestureDetector(
                  onTap: () => widget.onSlotSelected(slot),
                  child: NeumorphicContainer(
                    borderRadius: 14.0,
                    isInset: isSelected,
                    border: isSelected ? Border.all(color: accent, width: 2) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Text(
                      slot.formattedTime,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? accent : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
