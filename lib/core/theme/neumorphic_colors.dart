// Gene - Nov, 03, 2026: Neumorphic color palette for Light and Dark modes
import 'package:flutter/material.dart';

class NeumorphicColors {
  NeumorphicColors._();

  // --- Light Palette ---
  static const Color lightCanvas = Color(0xFFE6ECF5);
  static const Color lightSurface = Color(0xFFE6ECF5);
  static const Color lightHighlight = Color(0xFFFFFFFF);
  static const Color lightShadow = Color(0xFFB0BFD2);

  static const Color lightTextPrimary = Color(0xFF1E293B);
  /*
  // Gene - Nov, 03, 2026: Original light/dark muted & accent palette (failed WCAG 2.1 AA contrast ratios)
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // --- Dark Palette ---
  static const Color darkCanvas = Color(0xFF181C24);
  static const Color darkSurface = Color(0xFF181C24);
  static const Color darkHighlight = Color(0xFF242A36);
  static const Color darkShadow = Color(0xFF0C0F14);

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // --- Brand Accents (Medical / Dental) ---
  static const Color tealPrimary = Color(0xFF0D9488);
  static const Color tealLight = Color(0xFF14B8A6);
  static const Color cyanAccent = Color(0xFF0284C7);
  static const Color cyanLight = Color(0xFF38BDF8);

  // --- Semantic Feedback Colors ---
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  */
  // Gene - Nov, 14, 2026: Upgraded palette to meet WCAG 2.1 AA >= 4.5:1 contrast across Light (#E6ECF5), Dark (#181C24), White (#FFFFFF), and tinted surfaces
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF526075);

  // --- Dark Palette ---
  static const Color darkCanvas = Color(0xFF181C24);
  static const Color darkSurface = Color(0xFF181C24);
  static const Color darkHighlight = Color(0xFF242A36);
  static const Color darkShadow = Color(0xFF0C0F14);

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF8E9DB5);

  // --- Brand Accents (Medical / Dental) ---
  static const Color tealPrimary = Color(0xFF0A665E);
  static const Color tealLight = Color(0xFF14B8A6);
  static const Color cyanAccent = Color(0xFF035E8B);
  static const Color cyanLight = Color(0xFF38BDF8);

  // --- Semantic Feedback Colors (Light & Dark surface pairs) ---
  static const Color success = Color(0xFF065F46);
  static const Color successLight = Color(0xFF34D399);
  static const Color warning = Color(0xFF92400E);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color error = Color(0xFFB91C1C);
  static const Color errorLight = Color(0xFFF87171);
  static const Color info = Color(0xFF1D4ED8);
  static const Color infoLight = Color(0xFF60A5FA);

  static Color successFor(bool isDark) => isDark ? successLight : success;
  static Color warningFor(bool isDark) => isDark ? warningLight : warning;
  static Color errorFor(bool isDark) => isDark ? errorLight : error;
  static Color infoFor(bool isDark) => isDark ? infoLight : info;
}
