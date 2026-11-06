import 'package:flutter/material.dart';

/// Pure light-theme color palette designed for maximum calm, high contrast,
/// and senior-friendly readability (WCAG AA compliant >= 4.5:1).
class AppColors {
  AppColors._();

  // Core Surfaces & Structure
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFEEF0F3);

  // Typography Tokens (High contrast, never lighter than #6B7280)
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);

  // Brand / Primary
  static const Color primary = Color(0xFF1D4ED8);
  static const Color primarySoft = Color(0xFFE8EEFD);

  // Attendance Statuses
  static const Color present = Color(0xFF15803D);
  static const Color presentBg = Color(0xFFE7F6EC);

  static const Color holiday = Color(0xFFB91C1C);
  static const Color holidayBg = Color(0xFFFDECEC);

  static const Color replacement = Color(0xFFC2410C);
  static const Color replacementBg = Color(0xFFFFF0E5);

  // Missing Data Alerts & Badges
  static const Color missingStatus = Color(0xFFB91C1C);
  static const Color missingStatusBg = Color(0xFFFEF2F2);
  static const Color missingStatusBorder = Color(0xFFF3C5C5);

  static const Color missingKm = Color(0xFFB45309);
  static const Color missingKmBg = Color(0xFFFEF6E0);
  static const Color missingKmBorder = Color(0xFFFDE68A);

  // Financial Indicators
  static const Color incomePositive = Color(0xFF15803D);
  static const Color incomeNegative = Color(0xFFB91C1C);

  // Subtle Shadow (opacity <= 0.06)
  static const Color shadow = Color(0x0F000000); // 6% black

  // Backward compatibility aliases pointing strictly to the light palette
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
  static const Color error = holiday;
  static const Color success = present;
  static const Color warning = replacement;
  static const Color replacementBorder = Color(0xFFFDBA74);
  static const Color replacementDark = replacement;
  static const Color primarySubtle = primarySoft;
  static const Color weekdayHeader = textMuted;
  static const Color adDateMuted = textMuted;
}
