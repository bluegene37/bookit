// Gene - Nov, 03, 2026: Step 2B - Date Range Picker ("Date From" and "Date To") for stays, retreats, and rentals
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../models/business.dart';
import '../../../../models/service_item.dart';

class DateRangePickerStep extends StatelessWidget {
  final Business business;
  final ServiceItem? service;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime start, DateTime end) onRangeSelected;

  const DateRangePickerStep({
    super.key,
    required this.business,
    required this.service,
    required this.startDate,
    required this.endDate,
    required this.onRangeSelected,
  });

  Future<void> _pickDateRange(BuildContext context) async {
    final initialRange = DateTimeRange(
      start: startDate ?? DateTime.now().add(const Duration(days: 1)),
      end: endDate ?? DateTime.now().add(const Duration(days: 4)),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: NeumorphicColors.tealPrimary,
              onPrimary: Colors.white,
              surface: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onRangeSelected(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    final hasRange = startDate != null && endDate != null;
    final totalDays = hasRange ? endDate!.difference(startDate!).inDays : 0;
    final pricePerDay = service?.price ?? 0.0;
    final totalPrice = totalDays * pricePerDay;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Booking Dates (From & To)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your arrival check-in date and departure check-out date.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Date From and Date To Display Cards
          Row(
            children: [
              Expanded(
                child: NeumorphicContainer(
                  borderRadius: 18.0,
                  isInset: startDate != null,
                  onTap: () => _pickDateRange(context),
                  padding: const EdgeInsets.all(16),
                  border: startDate != null ? Border.all(color: accent.withValues(alpha: 0.5)) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flight_land, size: 16, color: accent),
                          const SizedBox(width: 6),
                          Text(
                            'DATE FROM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        startDate != null ? DateFormat('MMM d, yyyy').format(startDate!) : 'Select Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        business.settings['checkin_time'] != null
                            ? 'Check-in: ${business.settings['checkin_time']}'
                            : 'Check-in: 2:00 PM',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: NeumorphicContainer(
                  borderRadius: 18.0,
                  isInset: endDate != null,
                  onTap: () => _pickDateRange(context),
                  padding: const EdgeInsets.all(16),
                  border: endDate != null ? Border.all(color: accent.withValues(alpha: 0.5)) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flight_takeoff, size: 16, color: accent),
                          const SizedBox(width: 6),
                          Text(
                            'DATE TO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        endDate != null ? DateFormat('MMM d, yyyy').format(endDate!) : 'Select Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        business.settings['checkout_time'] != null
                            ? 'Check-out: ${business.settings['checkout_time']}'
                            : 'Check-out: 11:00 AM',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tap to change dates button
          Center(
            child: OutlinedButton.icon(
              onPressed: () => _pickDateRange(context),
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(hasRange ? 'Change Date Range' : 'Open Calendar Picker'),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Total Price Calculation Card
          if (hasRange) ...[
            NeumorphicContainer(
              borderRadius: 18.0,
              isInset: true,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Duration',
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                      Text(
                        '$totalDays ${totalDays == 1 ? 'Night' : 'Nights'}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Rate (\$${pricePerDay.toStringAsFixed(0)} x $totalDays)',
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                      Text(
                        '\$${totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
