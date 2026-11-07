// Gene - Nov 06, 2026: Service Revenue & Booking Share Donut Chart for Admin Web Dashboard
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookit/core/theme/neumorphic_colors.dart';
import 'package:bookit/core/widgets/neumorphic_container.dart';

class ServiceShareItem {
  final String name;
  final double amount;
  final int count;
  final Color color;

  const ServiceShareItem({
    required this.name,
    required this.amount,
    required this.count,
    required this.color,
  });
}

class ServiceDonutChart extends StatefulWidget {
  final List<ServiceShareItem> items;
  final String title;

  const ServiceDonutChart({
    super.key,
    required this.items,
    this.title = 'Revenue by Service',
  });

  @override
  State<ServiceDonutChart> createState() => _ServiceDonutChartState();
}

class _ServiceDonutChartState extends State<ServiceDonutChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final textPrimary = isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;
    final textSecondary = isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary;

    final totalAmount = widget.items.fold<double>(0.0, (sum, i) => sum + i.amount);

    final activeItem = (_hoveredIndex != null && _hoveredIndex! >= 0 && _hoveredIndex! < widget.items.length)
        ? widget.items[_hoveredIndex!]
        : null;

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
                    Icon(Icons.pie_chart_rounded, size: 18, color: accent),
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
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.items.length} Services',
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

          // Donut canvas + Center Metric
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 170),
                    painter: _DonutChartPainter(
                      items: widget.items,
                      totalAmount: totalAmount,
                      hoveredIndex: _hoveredIndex,
                    ),
                  ),
                  // Center cutout metric text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activeItem != null
                            ? '\$${NumberFormat('#,##0').format(activeItem.amount)}'
                            : '\$${NumberFormat('#,##0').format(totalAmount)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: activeItem?.color ?? textPrimary,
                        ),
                      ),
                      Text(
                        activeItem != null
                            ? '${totalAmount > 0 ? ((activeItem.amount / totalAmount) * 100).toStringAsFixed(1) : '0'}%'
                            : 'Total Share',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Ranked Service Breakdown Legend
          Column(
            children: widget.items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final pct = totalAmount > 0 ? (item.amount / totalAmount) * 100 : 0.0;
              final isHovered = _hoveredIndex == idx;

              return MouseRegion(
                onEnter: (_) => setState(() => _hoveredIndex = idx),
                onExit: (_) => setState(() => _hoveredIndex = null),
                child: GestureDetector(
                  onTap: () => setState(() => _hoveredIndex = isHovered ? null : idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isHovered
                          ? item.color.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isHovered ? FontWeight.w700 : FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${NumberFormat('#,##0').format(item.amount)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textSecondary,
                          ),
                        ),
                      ],
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
}

class _DonutChartPainter extends CustomPainter {
  final List<ServiceShareItem> items;
  final double totalAmount;
  final int? hoveredIndex;

  _DonutChartPainter({
    required this.items,
    required this.totalAmount,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty || totalAmount <= 0) {
      // Empty placeholder ring
      final paint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 65, paint);
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    final strokeWidth = 22.0;

    double startAngle = -math.pi / 2; // Start from top 12 o'clock

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final sweepAngle = (item.amount / totalAmount) * (2 * math.pi);
      final isHovered = hoveredIndex == i;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? strokeWidth + 6 : strokeWidth
        ..strokeCap = StrokeCap.round;

      // Small 2-degree visual gap between slices
      final gap = items.length > 1 ? 0.06 : 0.0;
      final adjustedSweep = math.max(0.01, sweepAngle - gap);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (gap / 2),
        adjustedSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.items != items ||
        oldDelegate.totalAmount != totalAmount ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}
