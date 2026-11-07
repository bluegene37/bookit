// Gene - Nov 06, 2026: Peak Booking Hours & Bay Heatmap Bar Chart for Admin Web Dashboard
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bookit/core/theme/neumorphic_colors.dart';
import 'package:bookit/core/widgets/neumorphic_container.dart';

class HourlyLoadItem {
  final String hourLabel;
  final int count;
  final double capacityRate; // 0.0 to 1.0

  const HourlyLoadItem({
    required this.hourLabel,
    required this.count,
    required this.capacityRate,
  });
}

class PeakHoursBarChart extends StatefulWidget {
  final List<HourlyLoadItem> hourlyData;
  final String title;
  final String subtitle;

  const PeakHoursBarChart({
    super.key,
    required this.hourlyData,
    this.title = 'Peak Hours & Traffic Distribution',
    this.subtitle = 'Hourly appointment volume across operating day',
  });

  @override
  State<PeakHoursBarChart> createState() => _PeakHoursBarChartState();
}

class _PeakHoursBarChartState extends State<PeakHoursBarChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final textPrimary = isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;
    final textSecondary = isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary;

    // Find peak hour
    HourlyLoadItem? peakHour;
    int maxCount = 0;
    for (final item in widget.hourlyData) {
      if (item.count > maxCount) {
        maxCount = item.count;
        peakHour = item;
      }
    }

    final activeItem = (_hoveredIndex != null && _hoveredIndex! >= 0 && _hoveredIndex! < widget.hourlyData.length)
        ? widget.hourlyData[_hoveredIndex!]
        : peakHour;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 18, color: accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.title,
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
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
              if (peakHour != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: NeumorphicColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NeumorphicColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, size: 14, color: NeumorphicColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        'Peak at ${peakHour.hourLabel}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: NeumorphicColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Active indicator pill
          if (activeItem != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Time Window: ${activeItem.hourLabel}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      Text(
                        'Bookings: ${activeItem.count}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Occupancy: ${(activeItem.capacityRate * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: activeItem.capacityRate >= 0.8
                              ? NeumorphicColors.warning
                              : NeumorphicColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Bar Chart Canvas
          SizedBox(
            height: 140,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return MouseRegion(
                  onHover: (event) {
                    _updateHoverIndex(event.localPosition.dx, constraints.maxWidth);
                  },
                  onExit: (_) {
                    setState(() => _hoveredIndex = null);
                  },
                  child: GestureDetector(
                    onTapDown: (details) {
                      _updateHoverIndex(details.localPosition.dx, constraints.maxWidth);
                    },
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, 140),
                      painter: _BarChartPainter(
                        hourlyData: widget.hourlyData,
                        hoveredIndex: _hoveredIndex,
                        accentColor: accent,
                        peakColor: NeumorphicColors.warning,
                        isDark: isDark,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Hour Labels
          Row(
            children: widget.hourlyData.map((item) {
              return Expanded(
                child: Center(
                  child: Text(
                    item.hourLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _updateHoverIndex(double dx, double width) {
    if (widget.hourlyData.isEmpty) return;
    final count = widget.hourlyData.length;
    final slotWidth = width / count;
    final index = (dx / slotWidth).floor().clamp(0, count - 1);
    if (_hoveredIndex != index) {
      setState(() => _hoveredIndex = index);
    }
  }
}

class _BarChartPainter extends CustomPainter {
  final List<HourlyLoadItem> hourlyData;
  final int? hoveredIndex;
  final Color accentColor;
  final Color peakColor;
  final bool isDark;

  _BarChartPainter({
    required this.hourlyData,
    required this.hoveredIndex,
    required this.accentColor,
    required this.peakColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hourlyData.isEmpty) return;

    final maxCount = math.max(hourlyData.map((d) => d.count).reduce(math.max), 1).toDouble();
    final count = hourlyData.length;
    final slotWidth = size.width / count;
    final barWidth = math.min(slotWidth * 0.55, 34.0);

    for (int i = 0; i < count; i++) {
      final item = hourlyData[i];
      final isHovered = hoveredIndex == i;
      final isPeak = item.capacityRate >= 0.8;

      final normalized = (item.count / maxCount).clamp(0.05, 1.0);
      final barHeight = size.height * normalized;
      final left = (i * slotWidth) + (slotWidth - barWidth) / 2;
      final top = size.height - barHeight;

      // Background track
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 0, barWidth, size.height),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        trackRect,
        Paint()..color = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
      );

      // Bar with gradient
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(8),
      );

      final barColor = isPeak ? peakColor : accentColor;
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          barColor,
          barColor.withValues(alpha: isHovered ? 0.9 : 0.6),
        ],
      );

      final barPaint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(left, top, barWidth, barHeight))
        ..style = PaintingStyle.fill;

      canvas.drawRRect(barRect, barPaint);

      // Draw value text on top of bar if count > 0
      if (item.count > 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${item.count}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final textX = left + (barWidth - textPainter.width) / 2;
        final textY = math.max(0.0, top - textPainter.height - 3);
        textPainter.paint(canvas, Offset(textX, textY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.hourlyData != hourlyData ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.accentColor != accentColor;
  }
}
