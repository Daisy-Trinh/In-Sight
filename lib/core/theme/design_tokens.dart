import 'package:flutter/material.dart';

/// Design tokens — nguồn chân lý duy nhất cho toàn bộ màu sắc, typography,
/// spacing của In-Sight. Derived từ design-tokens.md.
abstract class DesignTokens {
  // ─────────────────────────────────────────
  // BRAND COLORS
  // ─────────────────────────────────────────
  static const Color primary = Color(0xFF5C8270);          // Sage green
  static const Color primaryContainer = Color(0xFFD4E8DC);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Persona — Lầy (Bestie)
  static const Color bestie = Color(0xFFE8B49B);
  static const Color bestieContainer = Color(0xFFFAEDE4);
  static const Color onBestie = Color(0xFF5C3D2A);

  // Persona — Mentor
  static const Color mentor = Color(0xFF6A8A9E);
  static const Color mentorContainer = Color(0xFFDCEAF2);
  static const Color onMentor = Color(0xFF1E3A4A);

  // Persona — Soul (Soulmate)
  static const Color soulmate = Color(0xFFB8A0C0);
  static const Color soulmateContainer = Color(0xFFEEE6F4);
  static const Color onSoulmate = Color(0xFF3A2A4A);

  // ─────────────────────────────────────────
  // NEUTRAL / SURFACE (LIGHT)
  // ─────────────────────────────────────────
  static const Color background = Color(0xFFF5F0EB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEDE8E3);
  static const Color outline = Color(0xFFD4CEC9);
  static const Color outlineVariant = Color(0xFFEDE8E3);

  static const Color textPrimary = Color(0xFF2C2825);
  static const Color textSecondary = Color(0xFF6B6560);
  static const Color textDisabled = Color(0xFFADA8A3);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ─────────────────────────────────────────
  // NEUTRAL / SURFACE (DARK)
  // ─────────────────────────────────────────
  static const Color darkBackground = Color(0xFF1A1816);
  static const Color darkSurface = Color(0xFF242120);
  static const Color darkSurfaceVariant = Color(0xFF2E2B28);
  static const Color darkOutline = Color(0xFF3D3A37);

  static const Color darkTextPrimary = Color(0xFFEDE8E3);
  static const Color darkTextSecondary = Color(0xFFADA8A3);

  // ─────────────────────────────────────────
  // SEMANTIC
  // ─────────────────────────────────────────
  static const Color success = Color(0xFF4CAF82);
  static const Color warning = Color(0xFFE8A855);
  static const Color error = Color(0xFFD97B6B);
  static const Color info = Color(0xFF6A8A9E);

  // SOS / Crisis
  static const Color sos = Color(0xFFD97B6B);
  static const Color sosBackground = Color(0xFFFAEDE4);

  // ─────────────────────────────────────────
  // SPACING
  // ─────────────────────────────────────────
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // ─────────────────────────────────────────
  // BORDER RADIUS
  // ─────────────────────────────────────────
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radius2xl = 24.0;
  static const double radiusFull = 999.0;

  // ─────────────────────────────────────────
  // TYPOGRAPHY
  // ─────────────────────────────────────────
  static const String fontBody = 'BeVietnamPro';
  static const String fontDisplay = 'Lora';

  static const double fontXs = 11.0;
  static const double fontSm = 13.0;
  static const double fontMd = 15.0;
  static const double fontLg = 17.0;
  static const double fontXl = 20.0;
  static const double font2xl = 24.0;
  static const double font3xl = 28.0;

  // ─────────────────────────────────────────
  // ELEVATION / SHADOW
  // ─────────────────────────────────────────
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x0D2C2825), blurRadius: 4, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x142C2825), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x1F2C2825), blurRadius: 24, offset: Offset(0, 8)),
  ];

  // ─────────────────────────────────────────
  // ANIMATION DURATIONS
  // ─────────────────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);
  static const Duration durationXSlow = Duration(milliseconds: 600);

  // ─────────────────────────────────────────
  // QUOTA / PROGRESS
  // ─────────────────────────────────────────
  static const int quotaFreeDaily = 20;
  static const int quotaAdReward = 10;

  // ─────────────────────────────────────────
  // PERSONA COLORS — helper accessor
  // ─────────────────────────────────────────
  static Color personaColor(String persona) {
    switch (persona) {
      case 'lay':
        return bestie;
      case 'mentor':
        return mentor;
      case 'soul':
        return soulmate;
      default:
        return primary;
    }
  }

  static Color personaContainerColor(String persona) {
    switch (persona) {
      case 'lay':
        return bestieContainer;
      case 'mentor':
        return mentorContainer;
      case 'soul':
        return soulmateContainer;
      default:
        return primaryContainer;
    }
  }
}
