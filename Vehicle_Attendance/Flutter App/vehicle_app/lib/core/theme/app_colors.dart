import 'package:flutter/material.dart';

/// Tailwind-extracted color palette for vehicle attendance application.
class AppColors {
  AppColors._();

  // Primary Gradient (Blue 600 -> Blue 700)
  static const Color primary = Color(0xFF2563EB); // blue-600
  static const Color primaryDark = Color(0xFF1D4ED8); // blue-700
  static const Color primaryLight = Color(0xFFDBEAFE); // blue-100
  static const Color primarySubtle = Color(0xFFEFF6FF); // blue-50

  // Secondary Accent (Purple 600 -> Purple 700)
  static const Color secondary = Color(0xFF9333EA); // purple-600
  static const Color secondaryDark = Color(0xFF7E22CE); // purple-700
  static const Color secondaryLight = Color(0xFFF3E8FF); // purple-100
  static const Color secondarySubtle = Color(0xFFFAF5FF); // purple-50

  // Present Status (Green 600)
  static const Color present = Color(0xFF16A34A); // green-600
  static const Color presentDark = Color(0xFF15803D); // green-700
  static const Color presentLight = Color(0xFFDCFCE7); // green-100
  static const Color presentSubtle = Color(0xFFF0FDF4); // green-50

  // Holiday Status / Warning / Deductions (Red 600)
  static const Color holiday = Color(0xFFDC2626); // red-600
  static const Color holidayDark = Color(0xFFB91C1C); // red-700
  static const Color holidayLight = Color(0xFFFEE2E2); // red-100
  static const Color holidaySubtle = Color(0xFFFEF2F2); // red-50
  static const Color missingBorder = Color(0xFFEF4444); // red-500

  // Replacement Status / Fuel Bills (Orange 600)
  static const Color replacement = Color(0xFFEA580C); // orange-600
  static const Color replacementDark = Color(0xFFC2410C); // orange-700
  static const Color replacementLight = Color(0xFFFFEDD5); // orange-100
  static const Color replacementSubtle = Color(0xFFFFF7ED); // orange-50
  static const Color replacementBorder = Color(0xFFFDBA74); // orange-300

  // Neutral Colors (Light Theme)
  static const Color backgroundLight = Color(0xFFF9FAFB); // gray-50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5E7EB); // gray-200
  static const Color textPrimaryLight = Color(0xFF111827); // gray-900
  static const Color textSecondaryLight = Color(0xFF4B5563); // gray-600
  static const Color textMutedLight = Color(0xFF9CA3AF); // gray-400

  // Neutral Colors (Dark Theme)
  static const Color backgroundDark = Color(0xFF111827); // gray-900
  static const Color surfaceDark = Color(0xFF1F2937); // gray-800
  static const Color borderDark = Color(0xFF374151); // gray-700
  static const Color textPrimaryDark = Color(0xFFF9FAFB); // gray-50
  static const Color textSecondaryDark = Color(0xFFD1D5DB); // gray-300
  static const Color textMutedDark = Color(0xFF9CA3AF); // gray-400

  // Unselected Day Card
  static const Color unselectedBg = Color(0xFFF3F4F6); // gray-100
  static const Color unselectedBorder = Color(0xFFD1D5DB); // gray-300
  static const Color unselectedText = Color(0xFF9CA3AF); // gray-400

  // Status aliases
  static const Color success = present;
  static const Color error = holiday;
  static const Color warning = replacement;

  // Today Highlight
  static const Color todayBorder = Color(0xFF93C5FD); // blue-300
  static const Color todayBg = Color(0xFFEFF6FF); // blue-50
}

