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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

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
            itemCount: 10,
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index + 1));
              final isSelected = DateUtils.isSameDay(date, selectedDate);

              return GestureDetector(
                onTap: () => onDateSelected(date),
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
                          color: isSelected ? accent : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Full Day Pass Available',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                      ),
                    ],
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
