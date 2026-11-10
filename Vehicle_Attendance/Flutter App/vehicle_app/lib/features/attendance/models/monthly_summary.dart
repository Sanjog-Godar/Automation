import '../../../core/config/app_constants.dart';
import 'attendance_log.dart';

/// Aggregated monthly summary calculations replicating Next.js `calculateMonthlySummary`.
class MonthlySummary {
  final int totalPresentDays;
  final int totalReplacementDays;
  final int totalExtraIncome;
  final int totalKm;
  final int grossIncome;
  final int totalDeductions;
  final int netIncome;

  const MonthlySummary({
    required this.totalPresentDays,
    required this.totalReplacementDays,
    required this.totalExtraIncome,
    required this.totalKm,
    required this.grossIncome,
    required this.totalDeductions,
    required this.netIncome,
  });

  /// Calculates monthly summary statistics from a list of attendance logs.
  /// Exactly mirrors `calculateMonthlySummary` in `lib/attendance.ts`:
  /// - Gross = Present * dailyWage + ExtraTrip
  /// - Deductions = Replace * replacementDeduction
  /// - Net = Gross - Deductions
  /// - KM is summed informatively (not part of salary / no TDS).
  factory MonthlySummary.calculate(
    List<AttendanceLog> logs, {
    int dailyWage = AppConstants.dailyWage,
    int replacementDeduction = AppConstants.replacementDeduction,
  }) {
    int totalPresentDays = 0;
    int totalReplacementDays = 0;
    int totalExtraIncome = 0;
    int totalKm = 0;

    for (final log in logs) {
      if (log.isUnselected) {
        continue;
      }

      if (log.status == AttendanceStatus.present) {
        totalPresentDays += 1;
      } else if (log.status == AttendanceStatus.absentReplacement) {
        totalReplacementDays += 1;
      }

      totalExtraIncome += log.extraTripIncome;
      totalKm += log.kmTotal ?? 0;
    }

    final grossIncome = totalPresentDays * dailyWage + totalExtraIncome;
    final totalDeductions = totalReplacementDays * replacementDeduction;
    final netIncome = grossIncome - totalDeductions;

    return MonthlySummary(
      totalPresentDays: totalPresentDays,
      totalReplacementDays: totalReplacementDays,
      totalExtraIncome: totalExtraIncome,
      totalKm: totalKm,
      grossIncome: grossIncome,
      totalDeductions: totalDeductions,
      netIncome: netIncome,
    );
  }
}
