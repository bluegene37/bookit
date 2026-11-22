// Gene - Nov, 03, 2026: Step 2B - Date Range Picker ("Date From" and "Date To") for stays, retreats, and rentals
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../models/business.dart';
import '../../../../models/service_item.dart';
// Gene - Nov, 22, 2026: Added PlatformConfig import for dynamic multi-currency formatting
import '../../../../models/platform_config.dart';

class DateRangePickerStep extends StatelessWidget {
  final Business business;
  final ServiceItem? service;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime start, DateTime end) onRangeSelected;

  // Gene - Nov, 22, 2026: Added optional minDays/maxDays constraints, dark-mode DateRangePicker theme, notice window bounds, and dynamic currency formatting
  final int? minDays;
  final int? maxDays;

  const DateRangePickerStep({
    super.key,
    required this.business,
    required this.service,
    required this.startDate,
    required this.endDate,
    required this.onRangeSelected,
    this.minDays,
    this.maxDays,
  });

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final minStart = now.add(Duration(hours: business.minNoticeHours));
    final firstDate = DateTime(minStart.year, minStart.month, minStart.day);
    final maxHorizon = business.advanceBookingDays > 30 ? business.advanceBookingDays : 365;
    final lastDate = firstDate.add(Duration(days: maxHorizon));
    final initialStart = (startDate != null && !startDate!.isBefore(firstDate))
        ? startDate!
        : firstDate.add(const Duration(days: 1));
    final defaultEnd = initialStart.add(Duration(days: minDays ?? business.minDays));
    final initialEnd = (endDate != null && endDate!.isAfter(initialStart))
        ? endDate!
        : (defaultEnd.isAfter(lastDate) ? initialStart.add(const Duration(days: 1)) : defaultEnd);

    final initialRange = DateTimeRange(start: initialStart, end: initialEnd);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: NeumorphicColors.tealLight,
                    onPrimary: Colors.black,
                    surface: NeumorphicColors.darkSurface,
                  )
                : ColorScheme.light(
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
    // Gene - Nov, 22, 2026: Enforce minDays/maxDays constraints cleanly with inline validation banner
    final effectiveMin = minDays ?? business.minDays;
    final effectiveMax = maxDays ?? business.maxDays;
    final isRangeOutOfBounds = hasRange && (totalDays < effectiveMin || totalDays > effectiveMax);

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
                  /*
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
                  */
                  // Gene - Nov, 22, 2026: Dynamic multi-currency rate & total formatting + min/max nights warning banner
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Rate (${PlatformConfig.formatCurrency(pricePerDay, currencyCode: business.currency, decimals: 0)} x $totalDays)',
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                      Text(
                        PlatformConfig.formatCurrency(totalPrice, currencyCode: business.currency),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent),
                      ),
                    ],
                  ),
                  if (isRangeOutOfBounds) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: NeumorphicColors.error.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: NeumorphicColors.error.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 16, color: NeumorphicColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please select between $effectiveMin and $effectiveMax nights.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: NeumorphicColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
