import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/core/config/app_constants.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/models/monthly_summary.dart';

void main() {
  group('MonthlySummary Calculation Tests', () {
    test('Calculates exact financial formulas matching Next.js lib/attendance.ts', () {
      final logs = [
        // Present day with extra trip & tip
        const AttendanceLog(
          logDate: '2026-01-15',
          status: AttendanceStatus.present,
          extraTripIncome: 500,
          extraTipAmount: 500,
          extraTipNote: 'Evening market return',
          kmTotal: 65,
          isUnselected: false,
        ),
        // Present day normal
        const AttendanceLog(
          logDate: '2026-01-16',
          status: AttendanceStatus.present,
          extraTripIncome: 0,
          kmTotal: 50,
          isUnselected: false,
        ),
        // Replacement day
        const AttendanceLog(
          logDate: '2026-01-17',
          status: AttendanceStatus.absentReplacement,
          extraTripIncome: 0,
          kmTotal: 0,
          isUnselected: false,
        ),
        // Holiday day
        const AttendanceLog(
          logDate: '2026-01-18',
          status: AttendanceStatus.absentHoliday,
          extraTripIncome: 0,
          kmTotal: 0,
          isUnselected: false,
        ),
        // Unselected placeholder day (must not count towards salary or deductions)
        AttendanceLog.unselectedPlaceholder('2026-01-19'),
      ];

      final summary = MonthlySummary.calculate(logs);

      // Present days: 2 -> 2 * 1200 = 2400
      expect(summary.totalPresentDays, 2);
      expect(summary.totalExtraIncome, 500);
      expect(summary.totalExtraTips, 500);
      expect(summary.grossIncome, 2 * AppConstants.dailyWage + 500); // 2900

      // Replacement days: 1 -> 1 * 3000 = 3000
      expect(summary.totalReplacementDays, 1);
      expect(summary.totalDeductions, 1 * AppConstants.replacementDeduction); // 3000

      // Net Income: 2900 - 3000 = -100
      expect(summary.netIncome, -100);

      // KM
      expect(summary.totalKm, 115);
    });
  });
}

