import 'package:flutter/material.dart';

/// Pure light-theme color palette matching the modern, airy calendar design
/// (`Kartik 2083 calendar.html`) with WCAG AA compliance (>= 4.5:1 contrast).
class AppColors {
  AppColors._();

  // Core Surfaces & Structure
  static const Color background = Color(0xFFF4F5FA); // --bg: #f4f5fa
  static const Color surface = Color(0xFFFFFFFF);    // --card: #ffffff
  static const Color border = Color(0xFFE8EAF3);     // --line: #e8eaf3
  static const Color divider = Color(0xFFEEF0F3);

  // Typography Tokens (High contrast ink & muted)
  static const Color textPrimary = Color(0xFF171A2E); // --ink: #171a2e
  static const Color textMuted = Color(0xFF6B7280);   // --mute: #6b7280 (meets >= 4.5:1)

  // Brand / Accent (Solid vibrant Indigo)
  static const Color primary = Color(0xFF3B44D1);     // --accent: #3b44d1
  static const Color primarySoft = Color(0xFFE9EBFC); // --accent-soft: #e9ebfc

  // Attendance Statuses & Alerts from HTML
  static const Color alert = Color(0xFFC8321F);       // --alert: #c8321f
  static const Color alertSoft = Color(0xFFFDEEEB);   // --alert-soft: #fdeeeb
  static const Color alertBorder = Color(0xFFF2C4BC); // --alert-border: #f2c4bc

  static const Color event = Color(0xFF147A39);       // Deep emerald green (meets WCAG AA >= 4.5:1)
  static const Color eventSoft = Color(0xFFE3F5EC);   // --event-soft: #e3f5ec
  static const Color eventBorder = Color(0xFFA9DCC3); // --event-border: #a9dcc3

  // Status mapping
  static const Color present = event;
  static const Color presentBg = eventSoft;
  static const Color presentBorder = eventBorder;

  static const Color holiday = alert;
  static const Color holidayBg = Color(0xFFFDECEC);
  static const Color holidayBorder = Color(0xFFFCA5A5);

  static const Color replacement = Color(0xFFC2410C);
  static const Color replacementBg = Color(0xFFFFF0E5);
  static const Color replacementBorder = Color(0xFFFDBA74);

  // Missing Data Alerts
  static const Color missingStatus = alert;
  static const Color missingStatusBg = alertSoft;
  static const Color missingStatusBorder = alertBorder;

  static const Color missingKm = Color(0xFFB45309);
  static const Color missingKmBg = Color(0xFFFEF6E0);
  static const Color missingKmBorder = Color(0xFFFDE68A);

  // Financial Indicators
  static const Color incomePositive = event;
  static const Color incomeNegative = alert;

  // Net income amount on the navy hero card (bright tones for high contrast
  // against the indigo gradient: positive = green, negative = red).
  static const Color netIncomePositiveOnHero = Color(0xFF7DF3C4);
  static const Color netIncomeNegativeOnHero = Color(0xFFFF8A75);

  // Dashboard Hero & Monthly Summary Tokens from HTML template
  static const Color coral = Color(0xFFFF9D8A);       // --coral: #ff9d8a
  static const Color coralInk = Color(0xFF5A1208);    // Dark crimson text on coral
  static const Color mintGreen = Color(0xFF6EE7B7);   // Mint green bar segment
  static const Color heroNavyStart = Color(0xFF1B1F86);
  static const Color heroNavyMid = Color(0xFF2C33B8);
  static const Color heroNavyEnd = Color(0xFF4A52E0);

  // Subtle Shadow
  static const Color shadow = Color(0x0F171A2E); // 6% ink shadow

  // Backward compatibility aliases
  static const Color backgroundLight = background;
  static const Color surfaceLight = surface;
  static const Color borderLight = border;
  static const Color textPrimaryLight = textPrimary;
  static const Color textSecondaryLight = textMuted;
  static const Color textMutedLight = textMuted;
  static const Color presentLight = presentBg;
  static const Color holidayLight = holidayBg;
  static const Color replacementLight = replacementBg;
  static const Color missingStatusIcon = missingStatus;
  static const Color missingKmIcon = missingKm;
  static const Color missingCellBgLight = missingStatusBg;
  static const Color missingCellBorderLight = missingStatusBorder;
  static const Color calendarShadow = shadow;
  static const Color todayRing = primary;
  static const Color todayChip = primary;
  static const Color error = alert;
  static const Color success = event;
  static const Color warning = replacement;
  static const Color replacementDark = replacement;
  static const Color primarySubtle = primarySoft;
  static const Color weekdayHeader = textMuted;
  static const Color adDateMuted = textMuted;
}
