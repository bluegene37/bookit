// Gene - Nov, 03, 2026: Step 2C - Daily single-date session picker
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../models/business.dart';

class DailyPickerStep extends StatelessWidget {
  final Business business;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DailyPickerStep({
    super.key,
    required this.business,
    required this.selectedDate,
    required this.onDateSelected,
  });

  /*
  // Next 14 days grid
  GridView.builder( ... itemCount: 10 ... )
  */
  // Gene - Nov, 22, 2026: Honor business.advanceBookingDays, minNoticeHours, and closed days from business.workingHours
  bool _isDayOpen(DateTime date) {
    final workingHoursMap = business.workingHours;
    if (workingHoursMap == null) return true;
    final weekdayName = DateFormat('EEEE').format(date).toLowerCase();
    if (!workingHoursMap.containsKey(weekdayName)) return true;
    final dayConfig = workingHoursMap[weekdayName];
    if (dayConfig is Map && dayConfig['is_open'] == false) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final minCutoff = DateTime.now().add(Duration(hours: business.minNoticeHours));
    final firstDate = DateTime(minCutoff.year, minCutoff.month, minCutoff.day);
    final dayCount = business.advanceBookingDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Booking Day',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This business offers full-day sessions and passes. Choose your scheduled date.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Next 14 days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: dayCount,
            itemBuilder: (context, index) {
              final date = firstDate.add(Duration(days: index));
              final isOpen = _isDayOpen(date);
              final isSelected = isOpen && DateUtils.isSameDay(date, selectedDate);

              return GestureDetector(
                onTap: isOpen ? () => onDateSelected(date) : null,
                child: Opacity(
                  opacity: isOpen ? 1.0 : 0.45,
                  child: NeumorphicContainer(
                    borderRadius: 16.0,
                    isInset: isSelected,
                    border: isSelected ? Border.all(color: accent, width: 2) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE, MMM d').format(date),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? accent
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOpen ? 'Full Day Pass Available' : 'Closed on this day',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
