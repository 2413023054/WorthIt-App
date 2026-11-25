import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Secondary (Modern Tech Indigo & Vibrant Cyan)
  static const Color primary = Color(0xFF1E293B);
  static const Color primaryIndigo = Color(0xFF1A237E);
  static const Color primaryLightIndigo = Color(0xFF303F9F);
  static const Color secondaryCyan = Color(0xFF00E5FF);
  static const Color accentCyan = Color(0xFF00B4D8);
  static const Color darkCyan = Color(0xFF0077B6);

  // Semantic Status Colors
  static const Color worthItGreen = Color(0xFF10B981);
  static const Color worthItLightGreen = Color(0xFFD1FAE5);
  static const Color considerAmber = Color(0xFFF59E0B);
  static const Color considerLightAmber = Color(0xFFFEF3C7);
  static const Color notWorthItRed = Color(0xFFEF4444);
  static const Color notWorthItLightRed = Color(0xFFFEE2E2);

  // Dark Theme Backgrounds & Surfaces (Deep Indigo Slate)
  static const Color darkBackground = Color(0xFF0A0E17);
  static const Color darkSurface = Color(0xFF121826);
  static const Color darkSurfaceElevated = Color(0xFF1E2638);
  static const Color darkCard = Color(0xFF1A2133);
  static const Color darkBorder = Color(0xFF2A344D);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Light Theme Backgrounds & Surfaces (Clean Indigo Mist)
  static const Color lightBackground = Color(0xFFF4F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryIndigo, Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF00B4D8), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardAccentGradient = LinearGradient(
    colors: [Color(0xFF1A237E), Color(0xFF0077B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
