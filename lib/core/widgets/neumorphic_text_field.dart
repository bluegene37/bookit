// Gene - Nov, 03, 2026: Inset Neumorphic text field for search and form inputs
import 'package:flutter/material.dart';
import '../theme/neumorphic_colors.dart';
import 'neumorphic_container.dart';

class NeumorphicTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final String? errorText;

  const NeumorphicTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? NeumorphicColors.darkTextMuted : NeumorphicColors.lightTextMuted;
    final textColor = isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              labelText!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
              ),
            ),
          ),
        ],
        NeumorphicContainer(
          borderRadius: 14.0,
          isInset: true,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            maxLines: maxLines,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: hintColor, fontSize: 14),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (errorText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              errorText!,
              style: const TextStyle(color: NeumorphicColors.error, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}
