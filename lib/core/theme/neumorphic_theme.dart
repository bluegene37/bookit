// Gene - Nov, 03, 2026: Neumorphic theme definition and shadow calculation helpers for Light and Dark modes
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'neumorphic_colors.dart';

class NeumorphicTheme {
  NeumorphicTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: NeumorphicColors.lightCanvas,
      colorScheme: const ColorScheme.light(
        surface: NeumorphicColors.lightSurface,
        primary: NeumorphicColors.tealPrimary,
        secondary: NeumorphicColors.cyanAccent,
        onSurface: NeumorphicColors.lightTextPrimary,
        onSurfaceVariant: NeumorphicColors.lightTextSecondary,
        error: NeumorphicColors.error,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme).copyWith(
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: NeumorphicColors.lightTextPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: NeumorphicColors.lightTextPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: NeumorphicColors.lightTextPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: NeumorphicColors.lightTextPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: NeumorphicColors.lightTextSecondary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: NeumorphicColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: NeumorphicColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NeumorphicColors.darkCanvas,
      colorScheme: const ColorScheme.dark(
        surface: NeumorphicColors.darkSurface,
        primary: NeumorphicColors.tealLight,
        secondary: NeumorphicColors.cyanLight,
        onSurface: NeumorphicColors.darkTextPrimary,
        onSurfaceVariant: NeumorphicColors.darkTextSecondary,
        error: NeumorphicColors.error,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).copyWith(
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: NeumorphicColors.darkTextPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: NeumorphicColors.darkTextPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: NeumorphicColors.darkTextPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: NeumorphicColors.darkTextPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: NeumorphicColors.darkTextSecondary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: NeumorphicColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: NeumorphicColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // --- Shadow Helpers ---
  static List<BoxShadow> getRaisedShadows(BuildContext context, {double depth = 6.0, double blur = 12.0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlight = isDark
        ? NeumorphicColors.darkHighlight.withValues(alpha: 0.8)
        : NeumorphicColors.lightHighlight.withValues(alpha: 0.9);
    final shadow = isDark
        ? NeumorphicColors.darkShadow.withValues(alpha: 0.9)
        : NeumorphicColors.lightShadow.withValues(alpha: 0.6);

    return [
      BoxShadow(
        color: highlight,
        offset: Offset(-depth, -depth),
        blurRadius: blur,
      ),
      BoxShadow(
        color: shadow,
        offset: Offset(depth, depth),
        blurRadius: blur,
      ),
    ];
  }

  static List<BoxShadow> getInsetShadows(BuildContext context, {double depth = 3.0, double blur = 6.0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.12);

    return [
      BoxShadow(
        color: shadowColor,
        offset: Offset(depth, depth),
        blurRadius: blur,
      ),
    ];
  }
}
