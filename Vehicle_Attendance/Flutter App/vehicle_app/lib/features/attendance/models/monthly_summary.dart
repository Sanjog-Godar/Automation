import '../../../core/config/app_constants.dart';
import 'attendance_log.dart';

/// Aggregated monthly summary calculations replicating Next.js `calculateMonthlySummary`.
class MonthlySummary {
  final int totalPresentDays;
  final int totalReplacementDays;
  final int totalExtraIncome;
  final int totalExtraTips;
  final int totalKm;
  final int grossIncome;
  final int totalDeductions;
  final int netIncome;

  const MonthlySummary({
    required this.totalPresentDays,
    required this.totalReplacementDays,
    required this.totalExtraIncome,
    required this.totalExtraTips,
    required this.totalKm,
    required this.grossIncome,
    required this.totalDeductions,
    required this.netIncome,
  });

  /// Calculates monthly summary statistics from a list of attendance logs.
  /// Exactly mirrors `calculateMonthlySummary` in `lib/attendance.ts`:
  /// - Gross = Present * 1200 + ExtraTrip
  /// - Deductions = Replace * 3000
  /// - Net = Gross - Deductions
  /// - Tips & KM are summed informatively (not part of salary / no TDS).
  factory MonthlySummary.calculate(List<AttendanceLog> logs) {
    int totalPresentDays = 0;
    int totalReplacementDays = 0;
    int totalExtraIncome = 0;
    int totalExtraTips = 0;
    int totalKm = 0;

    for (final log in logs) {
      if (log.isUnselected) {
        continue;
      }

      if (log.status == AttendanceStatus.present) {
        totalPresentDays += 1;
        totalExtraIncome += log.extraTripIncome;
      } else if (log.status == AttendanceStatus.absentReplacement) {
        totalReplacementDays += 1;
      }

      totalExtraTips += log.extraTipAmount ?? 0;
      totalKm += log.kmTotal ?? 0;
    }

    final grossIncome = totalPresentDays * AppConstants.dailyWage + totalExtraIncome;
    final totalDeductions = totalReplacementDays * AppConstants.replacementDeduction;
    final netIncome = grossIncome - totalDeductions;

    return MonthlySummary(
      totalPresentDays: totalPresentDays,
      totalReplacementDays: totalReplacementDays,
      totalExtraIncome: totalExtraIncome,
      totalExtraTips: totalExtraTips,
      totalKm: totalKm,
      grossIncome: grossIncome,
      totalDeductions: totalDeductions,
      netIncome: netIncome,
    );
  }
}

