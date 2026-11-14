// Gene - Nov, 03, 2026: Neumorphic toggle chip for categories, dates, and slot time selection
import 'package:flutter/material.dart';
// Gene - Nov, 14, 2026: Added services import for keyboard activation shortcuts and 48dp touch targets
import 'package:flutter/services.dart';
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
    /*
    // Gene - Nov, 03, 2026: Previous 42dp default chip height failed 48dp WCAG tap-target guidelines
    this.height = 42.0,
    */
    // Gene - Nov, 14, 2026: Default 48dp minimum height to satisfy WCAG / Material 48x48dp touch targets
    this.height = 48.0,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    final textColor = isSelected
        ? accent
        : (isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary);

    /*
    // Gene - Nov, 06, 2026: Previous GestureDetector + fixed height NeumorphicContainer without Semantics or keyboard support
    return GestureDetector(
      onTap: onTap,
      child: NeumorphicContainer(
        height: subtitle != null ? height + 16 : height,
        borderRadius: 20.0,
        isInset: isSelected,
    */
    // Gene - Nov, 14, 2026: Wrapped chip in Semantics + FocusableActionDetector with flexible minHeight constraints (>= 48dp) so chips expand at 1.5x text scale without clipping
    final minChipHeight = (subtitle != null ? height + 16 : height).clamp(48.0, double.infinity);

    return Semantics(
      button: true,
      selected: isSelected,
      label: subtitle != null ? '$label, $subtitle' : label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: NeumorphicContainer(
            constraints: BoxConstraints(
              minWidth: 48.0,
              minHeight: minChipHeight,
            ),
            borderRadius: 20.0,
            isInset: isSelected,
        /*
        // Original NeumorphicChip child layout
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
        */
        // Gene - Nov 06, 2026: Added Flexible container with text ellipsis to NeumorphicChip children to avoid RenderFlex overflow on mobile screens
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: isSelected ? Border.all(color: accent.withValues(alpha: 0.7), width: 1.5) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  if (subtitle != null) ...[
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? NeumorphicColors.darkTextMuted : NeumorphicColors.lightTextMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    ),
    );
  }
}
