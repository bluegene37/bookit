// Gene - Nov 06, 2026: Staff & Resource/Bay Workload Utilization Chart for Admin Web Dashboard
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookit/core/theme/neumorphic_colors.dart';
import 'package:bookit/core/widgets/neumorphic_container.dart';

class StaffUtilizationData {
  final String id;
  final String name;
  final String role;
  final int completedBookings;
  final double revenueGenerated;
  final double utilizationRate; // 0.0 to 1.0

  const StaffUtilizationData({
    required this.id,
    required this.name,
    required this.role,
    required this.completedBookings,
    required this.revenueGenerated,
    required this.utilizationRate,
  });
}

class StaffUtilizationChart extends StatelessWidget {
  final List<StaffUtilizationData> staffList;
  final String title;

  const StaffUtilizationChart({
    super.key,
    required this.staffList,
    this.title = 'Specialist & Resource Utilization',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final textPrimary = isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;
    final textSecondary = isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary;

    return NeumorphicContainer(
      borderRadius: 22.0,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.badge_rounded, size: 18, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${staffList.length} Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (staffList.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No staff or resource allocation data recorded.',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ),
            ),
          ] else ...[
            ...staffList.map((staff) {
              final pct = (staff.utilizationRate * 100).toInt();
              final isHigh = staff.utilizationRate >= 0.8;
              final isOptimal = staff.utilizationRate >= 0.5 && staff.utilizationRate < 0.8;
              // Gene - Nov, 14, 2026: Use WCAG AA warningFor and light/dark-appropriate cyan tokens
              /*
              final statusColor = isHigh
                  ? NeumorphicColors.warning
                  : (isOptimal ? NeumorphicColors.tealPrimary : NeumorphicColors.cyanLight);
              */
              final statusColor = isHigh
                  ? NeumorphicColors.warningFor(isDark)
                  : (isOptimal ? accent : (isDark ? NeumorphicColors.cyanLight : NeumorphicColors.cyanAccent));

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /*
                    // Gene - Nov 06, 2026: Static staff header Row overflowed by 19-35px on 320px @ 1.5x
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                staff.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                staff.role,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${NumberFormat('#,##0').format(staff.revenueGenerated)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              '${staff.completedBookings} visits • $pct%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    */
                    // Gene - Nov, 14, 2026: Stack staff metrics under identity below 280dp*scale to eliminate 320px @ 1.5x Row overflow
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                        final stackMetrics = constraints.maxWidth < 280 * textScale;
                        final nameColumn = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              staff.role,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        );
                        final revenueText = Text(
                          '\$${NumberFormat('#,##0').format(staff.revenueGenerated)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        );
                        final visitsText = Text(
                          '${staff.completedBookings} visits • $pct%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        );

                        if (stackMetrics) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              nameColumn,
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  revenueText,
                                  visitsText,
                                ],
                              ),
                            ],
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: nameColumn),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                revenueText,
                                visitsText,
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Container(
                            height: 7,
                            width: double.infinity,
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                          FractionallySizedBox(
                            widthFactor: staff.utilizationRate.clamp(0.05, 1.0),
                            child: Container(
                              height: 7,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    statusColor,
                                    statusColor.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
