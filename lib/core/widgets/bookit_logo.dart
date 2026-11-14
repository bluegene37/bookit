// Gene - Nov, 08, 2026: Minimalist Geometric 'B' + Checkmark vector logo widget and CustomPainter for BookIt
import 'package:flutter/material.dart';
import '../theme/neumorphic_colors.dart';
import 'neumorphic_container.dart';

class BookItLogo extends StatelessWidget {
  final double size;
  final bool showBadge;
  final bool isCircle;
  final bool showWordmark;
  final String? subtitle;

  const BookItLogo({
    super.key,
    this.size = 44.0,
    this.showBadge = true,
    this.isCircle = true,
    this.showWordmark = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final accent = isDark ? NeumorphicColors.cyanLight : NeumorphicColors.cyanAccent;

    final markSize = showBadge ? size * 0.62 : size;

    /*
    // Gene - Nov, 08, 2026: Unexcluded vector CustomPaint mark triggered screen-reader unlabeled graphic noise
    final markWidget = SizedBox(
      width: markSize,
      height: markSize,
      child: CustomPaint(
        painter: BookItLogoPainter(
          primaryColor: primary,
          accentColor: accent,
          isDark: isDark,
        ),
      ),
    );
    */
    // Gene - Nov, 14, 2026: Wrap decorative vector logo mark in ExcludeSemantics to avoid unlabeled graphic semantics
    final markWidget = ExcludeSemantics(
      child: SizedBox(
        width: markSize,
        height: markSize,
        child: CustomPaint(
          painter: BookItLogoPainter(
            primaryColor: primary,
            accentColor: accent,
            isDark: isDark,
          ),
        ),
      ),
    );

    final badgeOrMark = showBadge
        ? NeumorphicContainer(
            isCircle: isCircle,
            borderRadius: isCircle ? size / 2 : size * 0.28,
            width: size,
            height: size,
            child: Center(child: markWidget),
          )
        : SizedBox(
            width: size,
            height: size,
            child: Center(child: markWidget),
          );

    if (!showWordmark) {
      return badgeOrMark;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badgeOrMark,
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BookIt',
              style: TextStyle(
                fontSize: size * 0.48,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark
                    ? NeumorphicColors.darkTextPrimary
                    : NeumorphicColors.lightTextPrimary,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: (size * 0.26).clamp(10.0, 14.0),
                  color: isDark
                      ? NeumorphicColors.darkTextSecondary
                      : NeumorphicColors.lightTextSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class BookItLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final bool isDark;

  const BookItLogoPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final scale = w / 100.0;

    // 1. Subtle Ambient Squircle Halo inside the mark
    final haloPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withValues(alpha: isDark ? 0.16 : 0.10),
          accentColor.withValues(alpha: isDark ? 0.08 : 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8 * scale, 8 * scale, 84 * scale, 84 * scale),
        Radius.circular(24 * scale),
      ),
      haloPaint,
    );

    // 2. Geometric 'B' Monogram Backbone & Upper/Lower Loops
    final bStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryColor, accentColor],
      ).createShader(Rect.fromLTWH(20 * scale, 16 * scale, 50 * scale, 68 * scale));

    /*
    // Gene - Nov, 08, 2026: Initial B + Checkmark path where bottom base (48,78) overlapped check vertex (56,72)
    final bPath = Path()
      // Start at bottom-right of the lower loop base
      ..moveTo(48 * scale, 78 * scale)
      // Horizontal base to bottom-left spine corner
      ..lineTo(30 * scale, 78 * scale)
      ..quadraticBezierTo(24 * scale, 78 * scale, 24 * scale, 72 * scale)
      // Vertical spine up to top-left corner
      ..lineTo(24 * scale, 26 * scale)
      ..quadraticBezierTo(24 * scale, 20 * scale, 30 * scale, 20 * scale)
      // Top bar of upper loop
      ..lineTo(50 * scale, 20 * scale)
      // Semicircular upper bowl of 'B' (from y=20 to y=48, radius=14)
      ..arcToPoint(
        Offset(50 * scale, 48 * scale),
        radius: Radius.circular(14 * scale),
        clockwise: true,
      )
      // Waist bar tucking back toward spine
      ..lineTo(35 * scale, 48 * scale);

    canvas.drawPath(bPath, bStrokePaint);

    // 3. Integrated Confirmation Checkmark (✓) completing the lower-right silhouette of 'B'
    final checkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [primaryColor, accentColor],
      ).createShader(Rect.fromLTWH(42 * scale, 38 * scale, 42 * scale, 36 * scale));

    final checkPath = Path()
      ..moveTo(44 * scale, 60 * scale)
      ..lineTo(56 * scale, 72 * scale)
      ..lineTo(80 * scale, 42 * scale);

    canvas.drawPath(checkPath, checkPaint);
    */

    /*
    // Gene - Nov, 08, 2026: Refined minimalist Gestalt 'B' + Checkmark geometry with closed upper bowl and clean negative-space separation
    final bPath = Path()
      // Start at bottom-left base (leaving clean negative-space gap before check vertex)
      ..moveTo(37 * scale, 75 * scale)
      ..lineTo(30 * scale, 75 * scale)
      ..quadraticBezierTo(24 * scale, 75 * scale, 24 * scale, 69 * scale)
      // Vertical spine up to top-left corner
      ..lineTo(24 * scale, 28 * scale)
      ..quadraticBezierTo(24 * scale, 22 * scale, 30 * scale, 22 * scale)
      // Top bar of upper loop
      ..lineTo(48 * scale, 22 * scale)
      // Semicircular upper bowl of 'B' (y=22 to y=49, radius=13.5)
      ..arcToPoint(
        Offset(48 * scale, 49 * scale),
        radius: Radius.circular(13.5 * scale),
        clockwise: true,
      )
      // Close waist bar cleanly into vertical spine
      ..lineTo(24 * scale, 49 * scale);

    canvas.drawPath(bPath, bStrokePaint);

    // 3. Integrated Confirmation Checkmark (✓) forming the lower-right bowl of 'B'
    final checkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [primaryColor, accentColor],
      ).createShader(Rect.fromLTWH(44 * scale, 40 * scale, 38 * scale, 36 * scale));

    final checkPath = Path()
      ..moveTo(46 * scale, 62 * scale)
      ..lineTo(57 * scale, 74 * scale)
      ..lineTo(79 * scale, 45 * scale);

    canvas.drawPath(checkPath, checkPaint);
    */

    // Gene - Nov, 08, 2026: Complete Geometric 'B' (upper & lower bowls) with negative-space knockout Checkmark (✓) for instant letter B + check recognition
    final bPath = Path()
      // Vertical spine with rounded top-left and bottom-left corners
      ..moveTo(24 * scale, 49 * scale)
      ..lineTo(24 * scale, 28 * scale)
      ..quadraticBezierTo(24 * scale, 22 * scale, 30 * scale, 22 * scale)
      // Upper bowl of 'B' (y=22 to y=49, radius=13.5)
      ..lineTo(46 * scale, 22 * scale)
      ..arcToPoint(
        Offset(46 * scale, 49 * scale),
        radius: Radius.circular(13.5 * scale),
        clockwise: true,
      )
      ..lineTo(24 * scale, 49 * scale)
      // Continue down spine to bottom-left corner
      ..lineTo(24 * scale, 70 * scale)
      ..quadraticBezierTo(24 * scale, 76 * scale, 30 * scale, 76 * scale)
      // Lower bowl base and curve of 'B' (y=76 up to y=49, radius=13.5)
      ..lineTo(48 * scale, 76 * scale)
      ..arcToPoint(
        Offset(48 * scale, 49 * scale),
        radius: Radius.circular(13.5 * scale),
        clockwise: false,
      );

    canvas.drawPath(bPath, bStrokePaint);

    // 3. Negative-Space Knockout + Confirmation Checkmark (✓) intersecting the lower-right bowl
    final checkPath = Path()
      ..moveTo(46 * scale, 61 * scale)
      ..lineTo(57 * scale, 72 * scale)
      ..lineTo(80 * scale, 44 * scale);

    final knockoutColor = isDark
        ? const Color(0xFF1A202C)
        : const Color(0xFFE3ECF6);

    final knockoutPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = knockoutColor;

    canvas.drawPath(checkPath, knockoutPaint);

    final checkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [primaryColor, accentColor],
      ).createShader(Rect.fromLTWH(44 * scale, 42 * scale, 38 * scale, 34 * scale));

    canvas.drawPath(checkPath, checkPaint);

    // 4. Minimalist Calendar-Pin Accent Dot at top-right
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accentColor;

    canvas.drawCircle(
      Offset(76 * scale, 22 * scale),
      5.5 * scale,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant BookItLogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}
