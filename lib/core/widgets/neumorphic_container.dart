// Gene - Nov, 03, 2026: Tactile Neumorphic Container supporting extruded (raised) and debossed (inset) states
import 'package:flutter/material.dart';
import '../theme/neumorphic_colors.dart';
import '../theme/neumorphic_theme.dart';

class NeumorphicContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  // Gene - Nov, 14, 2026: Support minimum size constraints and accessible button semantics on tappable cards
  final BoxConstraints? constraints;
  final String? semanticLabel;
  final bool? isButton;
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
    this.constraints,
    this.semanticLabel,
    this.isButton,
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
    /*
    // Gene - Nov, 03, 2026: Previous AnimatedContainer without constraints parameter
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
    */
    // Gene - Nov, 14, 2026: Added constraints forwarding so buttons/chips can grow cleanly at 1.5x text scale
    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      width: width,
      height: height,
      constraints: constraints,
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
      /*
      // Gene - Nov, 03, 2026: GestureDetector without Semantics wrapper
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
      */
      // Gene - Nov, 14, 2026: Expose interactive Semantics node for screen readers on tappable NeumorphicContainer
      return Semantics(
        button: isButton ?? true,
        label: semanticLabel,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      );
    }

    return content;
  }
}
