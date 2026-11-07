// Gene - Nov 06, 2026: Interactive Revenue & Booking Volume Velocity Chart for Admin Web Dashboard
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookit/core/theme/neumorphic_colors.dart';
import 'package:bookit/core/widgets/neumorphic_container.dart';

class TrendDataPoint {
  final DateTime date;
  final String label;
  final double revenue;
  final int bookingCount;

  const TrendDataPoint({
    required this.date,
    required this.label,
    required this.revenue,
    required this.bookingCount,
  });
}

class RevenueTrendChart extends StatefulWidget {
  final List<TrendDataPoint> dataPoints;
  final String timeRangeLabel;
  final ValueChanged<String>? onTimeRangeChanged;

  const RevenueTrendChart({
    super.key,
    required this.dataPoints,
    this.timeRangeLabel = '7D',
    this.onTimeRangeChanged,
  });

  @override
  State<RevenueTrendChart> createState() => _RevenueTrendChartState();
}

class _RevenueTrendChartState extends State<RevenueTrendChart> {
  int? _hoveredIndex;
  bool _showRevenue = true; // true = Revenue ($), false = Bookings Volume (#)

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final textPrimary = isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;
    final textSecondary = isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary;

    final totalRevenue = widget.dataPoints.fold<double>(0.0, (sum, p) => sum + p.revenue);
    final totalBookings = widget.dataPoints.fold<int>(0, (sum, p) => sum + p.bookingCount);

    final activePoint = (_hoveredIndex != null && _hoveredIndex! >= 0 && _hoveredIndex! < widget.dataPoints.length)
        ? widget.dataPoints[_hoveredIndex!]
        : (widget.dataPoints.isNotEmpty ? widget.dataPoints.last : null);

    return NeumorphicContainer(
      borderRadius: 22.0,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Timeframe Filters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.insights_rounded, size: 18, color: accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Revenue & Booking Velocity',
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
                      _showRevenue
                          ? 'Total Gross Volume: \$${NumberFormat('#,##0.00').format(totalRevenue)}'
                          : 'Total Appointments Booked: $totalBookings',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),

              // Mode toggle (Revenue vs Volume)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPillButton(
                    label: '\$',
                    tooltip: 'Revenue (\$)',
                    isSelected: _showRevenue,
                    accent: accent,
                    isDark: isDark,
                    onTap: () => setState(() => _showRevenue = true),
                  ),
                  const SizedBox(width: 6),
                  _buildPillButton(
                    label: '#',
                    tooltip: 'Booking Volume (#)',
                    isSelected: !_showRevenue,
                    accent: accent,
                    isDark: isDark,
                    onTap: () => setState(() => _showRevenue = false),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Active hover tooltip preview banner
          if (activePoint != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.2)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEE, MMM d').format(activePoint.date),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        'Revenue: ',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      Text(
                        '\$${NumberFormat('#,##0').format(activePoint.revenue)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Visits: ',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      Text(
                        '${activePoint.bookingCount}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Interactive Chart Canvas
          SizedBox(
            height: 180,
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
                      size: Size(constraints.maxWidth, 180),
                      painter: _TrendChartPainter(
                        dataPoints: widget.dataPoints,
                        showRevenue: _showRevenue,
                        hoveredIndex: _hoveredIndex,
                        accentColor: accent,
                        gridColor: isDark ? Colors.white10 : Colors.black12,
                        textSecondary: textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // X-Axis Labels
          Row(
            children: widget.dataPoints.map((point) {
              return Expanded(
                child: Center(
                  child: Text(
                    point.label,
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
    if (widget.dataPoints.isEmpty) return;
    final count = widget.dataPoints.length;
    final step = width / (count - 1);
    final index = (dx / step).round().clamp(0, count - 1);
    if (_hoveredIndex != index) {
      setState(() => _hoveredIndex = index);
    }
  }

  Widget _buildPillButton({
    required String label,
    required String tooltip,
    required bool isSelected,
    required Color accent,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? accent
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<TrendDataPoint> dataPoints;
  final bool showRevenue;
  final int? hoveredIndex;
  final Color accentColor;
  final Color gridColor;
  final Color textSecondary;

  _TrendChartPainter({
    required this.dataPoints,
    required this.showRevenue,
    required this.hoveredIndex,
    required this.accentColor,
    required this.gridColor,
    required this.textSecondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paddingBottom = 10.0;
    final chartHeight = size.height - paddingBottom;
    final chartWidth = size.width;

    // Determine scale
    final values = dataPoints.map((p) => showRevenue ? p.revenue : p.bookingCount.toDouble()).toList();
    final maxValue = math.max(values.reduce(math.max), 1.0) * 1.15; // 15% headroom

    // Draw horizontal grid lines (3 levels)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 3; i++) {
      final y = chartHeight - (chartHeight * (i / 3));
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    // Compute pixel points
    final count = dataPoints.length;
    final stepX = count > 1 ? chartWidth / (count - 1) : chartWidth;
    final points = <Offset>[];

    for (int i = 0; i < count; i++) {
      final x = i * stepX;
      final normalized = (values[i] / maxValue).clamp(0.0, 1.0);
      final y = chartHeight - (normalized * chartHeight);
      points.add(Offset(x, y));
    }

    if (points.length < 2) return;

    // Build smooth cubic bezier path
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY1 = p0.dy;
      final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY2 = p1.dy;
      path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
    }

    // Gradient fill under the curve
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, chartHeight)
      ..lineTo(points.first.dx, chartHeight)
      ..close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        accentColor.withValues(alpha: 0.35),
        accentColor.withValues(alpha: 0.02),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Draw data points & hovered highlight
    for (int i = 0; i < points.length; i++) {
      final isHovered = hoveredIndex == i;
      final point = points[i];

      if (isHovered) {
        // Outer halo
        canvas.drawCircle(
          point,
          10.0,
          Paint()..color = accentColor.withValues(alpha: 0.25),
        );
        // Vertical indicator line
        canvas.drawLine(
          Offset(point.dx, 0),
          Offset(point.dx, chartHeight),
          Paint()
            ..color = accentColor.withValues(alpha: 0.4)
            ..strokeWidth = 1.5,
        );
      }

      // Inner solid point
      canvas.drawCircle(
        point,
        isHovered ? 5.5 : 3.5,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        point,
        isHovered ? 4.0 : 2.5,
        Paint()..color = accentColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.showRevenue != showRevenue ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.accentColor != accentColor;
  }
}
