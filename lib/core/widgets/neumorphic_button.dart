// Gene - Nov, 03, 2026: Neumorphic interactive button with tap depth transitions and accent styling
import 'package:flutter/material.dart';
// Gene - Nov, 14, 2026: Added services import for keyboard Enter/Space activation shortcuts
import 'package:flutter/services.dart';
import '../theme/neumorphic_colors.dart';
import 'neumorphic_container.dart';

class NeumorphicButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double height;
  final double borderRadius;
  final bool isPrimary;
  final bool isLoading;
  final EdgeInsetsGeometry padding;
  final IconData? icon;

  const NeumorphicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 50.0,
    this.borderRadius = 16.0,
    this.isPrimary = false,
    this.isLoading = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.icon,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (mounted) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    /*
    // Gene - Nov, 03, 2026: Original NeumorphicButton build using low-contrast dark-mode primary teal and fixed height without Semantics/Flexible
    Color? buttonColor;
    if (widget.isPrimary) {
      buttonColor = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    }

    final textColor = widget.isPrimary
        ? Colors.white
        : (isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: NeumorphicContainer(
          width: widget.width,
          height: widget.height,
          borderRadius: widget.borderRadius,
          isInset: _isPressed,
          color: buttonColor,
          padding: widget.padding,
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 18, color: textColor),
                        const SizedBox(width: 8),
                      ],
                      DefaultTextStyle(
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        child: widget.child,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
    */
    // Gene - Nov, 14, 2026: Ensure >= 4.5:1 primary fill in both themes (#0A665E on #FFFFFF = 6.83:1), min 48dp hit target with elastic height at 1.5x scale, Flexible child, Semantics & keyboard support
    Color? buttonColor;
    if (widget.isPrimary) {
      buttonColor = NeumorphicColors.tealPrimary;
    }

    final textColor = widget.isPrimary
        ? Colors.white
        : (isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary);

    final bool isEnabled = widget.onPressed != null && !widget.isLoading;
    final double minHeight = widget.height < 48.0 ? 48.0 : widget.height;

    return Semantics(
      button: true,
      enabled: isEnabled,
      child: FocusableActionDetector(
        enabled: isEnabled,
        mouseCursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (isEnabled) widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: widget.isLoading ? null : widget.onPressed,
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: NeumorphicContainer(
              width: widget.width,
              constraints: BoxConstraints(
                minWidth: 48.0,
                minHeight: minHeight,
              ),
              borderRadius: widget.borderRadius,
              isInset: _isPressed,
              color: buttonColor,
              border: (isDark && widget.isPrimary)
                  ? Border.all(
                      color: NeumorphicColors.tealLight.withValues(alpha: 0.35),
                      width: 1.0,
                    )
                  : null,
              padding: widget.padding,
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(textColor),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 18, color: textColor),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: DefaultTextStyle(
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              child: widget.child,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
