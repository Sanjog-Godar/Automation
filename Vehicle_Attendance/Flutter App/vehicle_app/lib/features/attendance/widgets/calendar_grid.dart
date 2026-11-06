import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../../core/utils/nepali_calendar_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../models/attendance_log.dart';
import 'day_card.dart';
import 'day_details_bottom_sheet.dart';

/// Redesigned 7-column Bikram Sambat monthly calendar grid.
/// Clean light-only styling, zero horizontal scroll, and WCAG AA contrast.
/// Fully localized with strict single-language rendering.
class CalendarGrid extends StatelessWidget {
  final int bsYear;
  final int bsMonthIndex; // 0-based: 0 (Baisakh) to 11 (Chaitra)
  final List<AttendanceLog> logs;
  final Set<String> savingDates;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final void Function(String logDate, AttendanceStatus newStatus) onStatusChange;
  final void Function(AttendanceLog log) onOpenTip;
  final void Function(AttendanceLog log) onOpenKm;
  final void Function(AttendanceLog log)? onOpenExtraTrip;
  final void Function(String logDate)? onFutureDateTap;

  const CalendarGrid({
    super.key,
    required this.bsYear,
    required this.bsMonthIndex,
    required this.logs,
    required this.savingDates,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onStatusChange,
    required this.onOpenTip,
    required this.onOpenKm,
    this.onOpenExtraTrip,
    this.onFutureDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    final monthName = AppFormatters.bsMonthName(bsMonthIndex, locale);
    final yearNumber = AppFormatters.formatNumber(bsYear, locale);
    final rawSubtitle = NepaliCalendarHelper.getEnglishMonthSubtitle(bsYear, bsMonthIndex);
    final localizedSubtitle = AppFormatters.formatAdMonthSpan(rawSubtitle, locale);

    // Compute calendar grid layout
    final firstAD = NepaliCalendarHelper.toGregorian(bsYear, bsMonthIndex, 1);
    final firstDayOfWeek = firstAD.weekday % 7; // 0=Sun, 6=Sat
    final todayStr = NepalClock.todayDateString();

    final totalDays = NepaliCalendarHelper.getDaysInMonth(bsYear, bsMonthIndex);
    final cellsCount = firstDayOfWeek + totalDays;
    final trailingBlanks = (7 - (cellsCount % 7)) % 7;
    final totalGridCells = cellsCount + trailingBlanks;
    final totalWeeks = totalGridCells ~/ 7;

    // Derived missing days count
    final List<Map<String, dynamic>> missingEntries = [];
    for (int i = 0; i < logs.length; i++) {
      final log = logs[i];
      final isPast = NepalClock.isPast(log.logDate);
      final isMissingStatus = isPast && log.isUnselected;
      final isMissingKm = isPast &&
          !log.isUnselected &&
          log.status == AttendanceStatus.present &&
          (log.kmTotal == null || log.kmTotal! <= 0);

      if (isMissingStatus || isMissingKm) {
        missingEntries.add({
          'dayNumber': i + 1,
          'log': log,
        });
      }
    }
    final missingDaysCount = missingEntries.length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.border,
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: 1.0,
            maxScaleFactor: 1.3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Month Header (Chevrons + Centered Month + Today chip)
                Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 28),
                        color: AppColors.textPrimary,
                        onPressed: onPreviousMonth,
                        tooltip: l10n.calendar_prevMonthTooltip,
                      ),
                    ),

                    // Centered Month + Year & Subtitle
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$monthName $yearNumber',
                            style: const TextStyle(
                              fontFamily: 'Mukta',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localizedSubtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Today Chip
                    OutlinedButton(
                      key: const Key('calendar_header_today_chip'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        minimumSize: const Size(0, 40),
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                      onPressed: onToday,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.today_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            l10n.calendar_todayChip,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Next Month Chevron
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 28),
                        color: AppColors.textPrimary,
                        onPressed: onNextMonth,
                        tooltip: l10n.calendar_nextMonthTooltip,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 2. Weekday Header Row (Sun - Sat, Saturday in red)
                Row(
                  children: List.generate(7, (index) {
                    final dayName = AppFormatters.weekdayName(index, locale);
                    final isSat = index == 6;
                    return Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        alignment: Alignment.center,
                        child: Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: isSat ? AppColors.holiday : AppColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),

                // 3. Calendar Grid Rows (7 columns)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3).scale(1.0);
                    const double gridGap = 6.0;
                    final totalWidth = constraints.maxWidth;
                    final cellWidth = (totalWidth - (6 * gridGap)) / 7;
                    final baseHeight = math.max(72.0, cellWidth * 1.15);
                    final cellHeight = baseHeight * textScale;

                    return Column(
                      children: List.generate(totalWeeks, (weekIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: gridGap),
                          child: Row(
                            children: List.generate(7, (dayOfWeekIndex) {
                              final cellIndex = weekIndex * 7 + dayOfWeekIndex;

                              if (cellIndex < firstDayOfWeek) {
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: dayOfWeekIndex < 6 ? gridGap : 0),
                                    child: SizedBox(height: cellHeight),
                                  ),
                                );
                              }

                              final dayNumber = cellIndex - firstDayOfWeek + 1;
                              if (dayNumber > totalDays) {
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: dayOfWeekIndex < 6 ? gridGap : 0),
                                    child: SizedBox(height: cellHeight),
                                  ),
                                );
                              }

                              final logIndex = dayNumber - 1;
                              final log = logIndex < logs.length
                                  ? logs[logIndex]
                                  : AttendanceLog(
                                      logDate: NepalClock.formatDate(
                                        NepaliCalendarHelper.toGregorian(
                                          bsYear,
                                          bsMonthIndex,
                                          dayNumber,
                                        ),
                                      ),
                                      status: AttendanceStatus.present,
                                      isUnselected: true,
                                    );

                              final primaryDayNumber = locale.languageCode == 'ne'
                                  ? AppFormatters.toDevanagariDigits('$dayNumber')
                                  : '$dayNumber';
                              final adDate = NepalClock.parseDate(log.logDate);
                              final secondaryDateLabel = locale.languageCode == 'ne'
                                  ? AppFormatters.toDevanagariDigits('${adDate.day}')
                                  : '${adDate.day}';

                              final isToday = log.logDate == todayStr;
                              final isPast = NepalClock.isPast(log.logDate);
                              final isFuture = NepalClock.isFuture(log.logDate);
                              final isSaturday = dayOfWeekIndex == 6;

                              final isMissingStatus = isPast && log.isUnselected;
                              final isMissingKm = isPast &&
                                  !log.isUnselected &&
                                  log.status == AttendanceStatus.present &&
                                  (log.kmTotal == null || log.kmTotal! <= 0);

                              final isSaving = savingDates.contains(log.logDate);

                              // Accessibility semantics label
                              final statusWord = log.isUnselected
                                  ? l10n.status_unselected
                                  : (log.status == AttendanceStatus.present
                                      ? l10n.status_present
                                      : (log.status == AttendanceStatus.absentHoliday
                                          ? l10n.status_holiday
                                          : l10n.status_replace));
                              final kmStr = AppFormatters.formatNumber(log.kmTotal ?? 0, locale);
                              final semanticsLabel = l10n.calendar_semantics_day(
                                primaryDayNumber,
                                monthName,
                                statusWord,
                                kmStr,
                              );

                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: dayOfWeekIndex < 6 ? gridGap : 0),
                                  child: SizedBox(
                                    height: cellHeight,
                                    child: DayCard(
                                      key: Key('day_cell_$dayNumber'),
                                      log: log,
                                      dayNumber: dayNumber,
                                      nepaliDayNumber: primaryDayNumber,
                                      dateLabel: secondaryDateLabel,
                                      semanticsLabel: semanticsLabel,
                                      isToday: isToday,
                                      isPast: isPast,
                                      isFuture: isFuture,
                                      isMissingStatus: isMissingStatus,
                                      isMissingKm: isMissingKm,
                                      isSaving: isSaving,
                                      isSaturday: isSaturday,
                                      onTap: () {
                                        if (isFuture) {
                                          onFutureDateTap?.call(log.logDate);
                                          return;
                                        }

                                        DayDetailsBottomSheet.show(
                                          context: context,
                                          dayNumber: dayNumber,
                                          bsYear: bsYear,
                                          bsMonthIndex: bsMonthIndex,
                                          log: log,
                                          isSaving: isSaving,
                                          onStatusChange: onStatusChange,
                                          onOpenTip: onOpenTip,
                                          onOpenKm: onOpenKm,
                                          onOpenExtraTrip: onOpenExtraTrip,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 4. Missing Data Summary Chip
                if (missingDaysCount > 0) ...[
                  InkWell(
                    key: const Key('calendar_missing_summary_chip'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final first = missingEntries.first;
                      DayDetailsBottomSheet.show(
                        context: context,
                        dayNumber: first['dayNumber'] as int,
                        bsYear: bsYear,
                        bsMonthIndex: bsMonthIndex,
                        log: first['log'] as AttendanceLog,
                        isSaving: savingDates.contains((first['log'] as AttendanceLog).logDate),
                        onStatusChange: onStatusChange,
                        onOpenTip: onOpenTip,
                        onOpenKm: onOpenKm,
                        onOpenExtraTrip: onOpenExtraTrip,
                      );
                    },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.missingStatusBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.missingStatusBorder,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 20,
                            color: AppColors.missingStatus,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.calendar_missingDays(missingDaysCount),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.missingStatus,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: AppColors.missingStatus,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 5. Tidy 3-Column Legend
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildLegendItem(
                              indicator: _buildLegendPill('P', AppColors.present, AppColors.presentBg),
                              label: l10n.calendar_legend_present,
                            ),
                          ),
                          Expanded(
                            child: _buildLegendItem(
                              indicator: _buildLegendPill('H', AppColors.holiday, AppColors.holidayBg),
                              label: l10n.calendar_legend_holiday,
                            ),
                          ),
                          Expanded(
                            child: _buildLegendItem(
                              indicator: _buildLegendPill('R', AppColors.replacement, AppColors.replacementBg),
                              label: l10n.calendar_legend_replace,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLegendItem(
                              indicator: const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.missingStatus),
                              label: l10n.calendar_legend_missingStatus,
                            ),
                          ),
                          Expanded(
                            child: _buildLegendItem(
                              indicator: const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.missingKm),
                              label: l10n.calendar_legend_missingKm,
                            ),
                          ),
                          Expanded(
                            child: _buildLegendItem(
                              indicator: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  locale.languageCode == 'ne' ? '१' : '1',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              label: l10n.calendar_legend_today,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem({required Widget indicator, required String label}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        indicator,
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendPill(String text, Color textColor, Color bgColor) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
