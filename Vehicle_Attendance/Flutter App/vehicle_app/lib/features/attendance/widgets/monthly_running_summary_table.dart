import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../../core/utils/nepali_calendar_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../models/attendance_log.dart';

/// Clean, high-legibility Monthly Running Summary Table displaying total kilometers run
/// in the currently selected month.
///
/// Dual date display is strictly formatted as requested:
///   - Nepali date (Bikram Sambat) on top (bold, primary visual hierarchy, e.g. २०८३ मंसिर २५)
///   - English date (Gregorian) directly below (subtle, secondary hierarchy, e.g. 2026 Dec 11)
///
/// Responsive, card-enclosed design matching the sample format with WCAG AA compliance.
class MonthlyRunningSummaryTable extends StatelessWidget {
  final int bsYear;
  final int bsMonthIndex;
  final List<AttendanceLog> logs;

  const MonthlyRunningSummaryTable({
    super.key,
    required this.bsYear,
    required this.bsMonthIndex,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    // Filter logs that belong to the selected month and have recorded KM readings
    final kmLogs = logs
        .where((log) => !log.isUnselected && log.kmTotal != null && log.kmTotal! > 0)
        .toList()
      ..sort((a, b) => a.logDate.compareTo(b.logDate));

    final totalMonthKm = kmLogs.fold<int>(0, (sum, item) => sum + (item.kmTotal ?? 0));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.speed_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.km_summary_table_title,
                    style: const TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (totalMonthKm > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppFormatters.formatUnit(totalMonthKm, 'km', locale),
                      style: const TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Table Header (Date, Start, End, Total)
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    l10n.km_summary_col_date,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.km_summary_col_start,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.km_summary_col_end,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.km_summary_col_total,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Body Rows or Empty State
          if (kmLogs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Center(
                child: Text(
                  l10n.km_summary_empty,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kmLogs.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                thickness: 0.5,
                color: Color(0xFFF1F3F9),
              ),
              itemBuilder: (context, index) {
                final item = kmLogs[index];
                final adDate = NepalClock.parseDate(item.logDate);
                final nepaliDate = adDate.toNepaliDateTime();

                // Dual date strings
                final bsMonth = NepaliCalendarHelper.nepaliMonths[nepaliDate.month - 1];
                final bsDay = NepaliCalendarHelper.toNepaliNumber(nepaliDate.day);
                final bsYearNum = NepaliCalendarHelper.toNepaliNumber(nepaliDate.year);
                final nepaliDateFormatted = '$bsYearNum $bsMonth $bsDay';

                // English date (e.g. 2026 Dec 11)
                const adMonthNamesShort = [
                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                ];
                final adMonth = adMonthNamesShort[adDate.month - 1];
                final englishDateFormatted = '${adDate.year} $adMonth ${adDate.day.toString().padLeft(2, '0')}';

                final startKmStr = AppFormatters.formatNumber(item.kmStart ?? 0, locale);
                final endKmStr = AppFormatters.formatNumber(item.kmEnd ?? 0, locale);
                final totalKmStr = AppFormatters.formatUnit(item.kmTotal ?? 0, 'km', locale);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Dual Date column: Nepali on top (bold), English below
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nepaliDateFormatted,
                              style: const TextStyle(
                                fontFamily: 'Mukta',
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              englishDateFormatted,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Start KM
                      Expanded(
                        flex: 3,
                        child: Text(
                          startKmStr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      // End KM
                      Expanded(
                        flex: 3,
                        child: Text(
                          endKmStr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      // Total KM
                      Expanded(
                        flex: 3,
                        child: Text(
                          totalKmStr,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Summary Footer Row (Total of all recorded KM in this month)
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 11,
                    child: Text(
                      l10n.km_summary_month_total,
                      style: const TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      AppFormatters.formatUnit(totalMonthKm, 'km', locale),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  ),
);
  }
}
