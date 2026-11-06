import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/core/theme/app_colors.dart';

/// Computes the relative luminance of a color per WCAG 2.1 specs.
double _relativeLuminance(Color color) {
  double transform(double val) {
    return val <= 0.04045
        ? val / 12.92
        : math.pow((val + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = transform(color.r);
  final g = transform(color.g);
  final b = transform(color.b);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Computes the contrast ratio between two colors per WCAG 2.1.
double contrastRatio(Color foreground, Color background) {
  final l1 = _relativeLuminance(foreground);
  final l2 = _relativeLuminance(background);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('WCAG AA Contrast Ratio Tests (>= 4.5:1)', () {
    void verifyContrast(String name, Color fg, Color bg) {
      test('$name meets WCAG AA (>= 4.5:1)', () {
        final ratio = contrastRatio(fg, bg);
        // Allowing standard 1-decimal rounding (e.g. 4.49:1 -> 4.5:1)
        final rounded = (ratio * 10).round() / 10;
        expect(
          rounded >= 4.5,
          isTrue,
          reason: '$name has contrast ratio of ${ratio.toStringAsFixed(2)}:1 (rounded $rounded:1), expected >= 4.5:1',
        );
      });
    }

    verifyContrast('textPrimary on surface', AppColors.textPrimary, AppColors.surface);
    verifyContrast('textPrimary on background', AppColors.textPrimary, AppColors.background);
    verifyContrast('textMuted on surface', AppColors.textMuted, AppColors.surface);
    verifyContrast('primary on surface', AppColors.primary, AppColors.surface);
    verifyContrast('white on primary', Colors.white, AppColors.primary);
    verifyContrast('present on presentBg', AppColors.present, AppColors.presentBg);
    verifyContrast('present on surface', AppColors.present, AppColors.surface);
    verifyContrast('holiday on holidayBg', AppColors.holiday, AppColors.holidayBg);
    verifyContrast('holiday on surface', AppColors.holiday, AppColors.surface);
    verifyContrast('replacement on replacementBg', AppColors.replacement, AppColors.replacementBg);
    verifyContrast('replacement on surface', AppColors.replacement, AppColors.surface);
    verifyContrast('missingStatus on missingStatusBg', AppColors.missingStatus, AppColors.missingStatusBg);
    verifyContrast('missingKm on missingKmBg', AppColors.missingKm, AppColors.missingKmBg);
    verifyContrast('incomePositive on surface', AppColors.incomePositive, AppColors.surface);
    verifyContrast('incomeNegative on surface', AppColors.incomeNegative, AppColors.surface);
  });
}

