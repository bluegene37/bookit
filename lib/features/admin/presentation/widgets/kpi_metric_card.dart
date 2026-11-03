// Gene - Nov, 03, 2026: KPI metric card with Neumorphic extruded styling for admin dashboard
import 'package:flutter/material.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';

class KpiMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor;
  final String? subtitle;

  const KpiMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? (isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary);

    return NeumorphicContainer(
      borderRadius: 20.0,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                ),
              ),
              NeumorphicContainer(
                isCircle: true,
                width: 36,
                height: 36,
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
            ),
          ],
        ],
      ),
    );
  }
}
