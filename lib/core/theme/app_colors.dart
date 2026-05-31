import 'package:flutter/material.dart';

/// Strivo Design System Colors — "Elite Performance" palette.
///
/// Theme: deep-black canvas, periwinkle-blue primary (the "ignition" color),
/// lime-green accent (success / PR / "go"). Derived from DESIGN.md + Stitch.
///
/// IMPORTANT: `primary` (#adc6ff) is a *light* periwinkle. It reads as a
/// high-contrast accent for text/icons on dark surfaces, AND serves as the
/// background of primary buttons — in which case text/icons must use
/// [onPrimary] (dark navy), never white.
class AppColors {
  AppColors._();

  // ── Primary (Periwinkle / Electric Blue)
  static const Color primary = Color(0xFFADC6FF); // accent on dark + button bg
  static const Color primaryLight = Color(0xFFD8E2FF); // primary-fixed
  static const Color primaryDark = Color(0xFF4B8EFF); // primary-container fill
  static const Color primaryContainer = Color(0xFF4B8EFF);
  static const Color onPrimary = Color(0xFF002E69); // navy — text/icon ON primary
  static const Color onPrimaryContainer = Color(0xFFD8E2FF);
  static const Color primaryMuted = Color(0xFFADC6FF);

  // ── Accent (Neon / Lime Green) — success, PR, "go", intensity
  static const Color accent = Color(0xFFABD600);
  static const Color accentBright = Color(0xFFC3F400); // tertiary-fixed
  static const Color onAccent = Color(0xFF283500); // dark — text/icon ON accent

  // ── Backgrounds
  static const Color background = Color(0xFF0A0A0A); // Z-0 true black
  static const Color surface = Color(0xFF161616); // Z-1 cards
  static const Color surfaceLight = Color(0xFF1F1F1F); // inset fields
  static const Color surfaceElevated = Color(0xFF2A2A2A); // Z-2 popovers
  static const Color surfaceHover = Color(0xFF353534);

  // ── Text
  static const Color textPrimary = Color(0xFFF2F3F5); // on-surface
  static const Color textSecondary = Color(0xFFC1C6D7); // on-surface-variant (cool)
  static const Color textTertiary = Color(0xFF8B90A0); // outline
  static const Color textDisabled = Color(0xFF5A5F6B);

  // ── Borders
  static const Color border = Color(0xFF2A2A2A);
  static const Color borderLight = Color(0xFF3A3A3C);
  static const Color borderFocused = primary;

  // ── Semantic
  static const Color success = Color(0xFFABD600); // lime
  static const Color successMuted = Color(0xFF1E2A00);
  static const Color warning = Color(0xFFFFC247); // amber — streak / caution
  static const Color warningMuted = Color(0xFF332300);
  static const Color error = Color(0xFFFFB4AB); // soft red (Stitch error)
  static const Color errorMuted = Color(0xFF3D1210);
  static const Color info = Color(0xFF64D2FF);

  // ── Accent Variants
  static const Color pr = Color(0xFFC3F400); // Personal Record (bright lime)
  static const Color increase = Color(0xFFABD600); // weight/volume up
  static const Color decrease = Color(0xFFFFB4AB); // weight/volume down
  static const Color stagnant = Color(0xFF8B90A0); // no change

  // ── Chart Colors
  static const Color chartLine = primary;
  static const Color chartFill = Color(0x33ADC6FF);
  static const Color chartGrid = Color(0xFF2A2A2A);
  static const Color chartVolume = Color(0xFF5E5CE6); // indigo (distinct line)

  // ── Overlay
  static const Color overlay = Color(0x99000000);
  static const Color shimmerBase = Color(0xFF1C1C1E);
  static const Color shimmerHighlight = Color(0xFF2C2C2E);
}
