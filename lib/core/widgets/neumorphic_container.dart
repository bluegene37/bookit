// Gene - Nov, 03, 2026: Tactile Neumorphic Container supporting extruded (raised) and debossed (inset) states
import 'package:flutter/material.dart';
import '../theme/neumorphic_colors.dart';
import '../theme/neumorphic_theme.dart';

class NeumorphicContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isInset;
  final bool isCircle;
  final Color? color;
  final Border? border;
  final VoidCallback? onTap;

  const NeumorphicContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.isInset = false,
    this.isCircle = false,
    this.color,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = color ?? (isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface);

    final decoration = BoxDecoration(
      color: baseColor,
      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
      border: border,
      boxShadow: isInset
          ? NeumorphicTheme.getInsetShadows(context)
          : NeumorphicTheme.getRaisedShadows(context),
    );

    // Gene - Nov, 03, 2026: Wrapped child in transparent Material to prevent DecoratedBox ink/ListTile background assertions
    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: decoration,
      child: child != null ? Material(type: MaterialType.transparency, child: child!) : null,
    );
    /*
    // Gene - Nov, 03, 2026: Previous implementation without transparent Material wrapper
    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: decoration,
      child: child,
    );
    */

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
