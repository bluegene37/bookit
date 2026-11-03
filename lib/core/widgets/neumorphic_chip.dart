// Gene - Nov, 03, 2026: Neumorphic toggle chip for categories, dates, and slot time selection
import 'package:flutter/material.dart';
import '../theme/neumorphic_colors.dart';
import 'neumorphic_container.dart';

class NeumorphicChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final double height;
  final String? subtitle;

  const NeumorphicChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.height = 42.0,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    final textColor = isSelected
        ? accent
        : (isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary);

    return GestureDetector(
      onTap: onTap,
      child: NeumorphicContainer(
        height: subtitle != null ? height + 16 : height,
        borderRadius: 20.0,
        isInset: isSelected,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: isSelected ? Border.all(color: accent.withValues(alpha: 0.7), width: 1.5) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 8),
            ],
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (subtitle != null) ...[
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: isDark ? NeumorphicColors.darkTextMuted : NeumorphicColors.lightTextMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
