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
}
