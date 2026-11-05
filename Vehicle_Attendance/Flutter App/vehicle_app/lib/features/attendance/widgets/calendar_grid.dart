import 'package:flutter/material.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../../core/utils/nepali_calendar_helper.dart';
import '../models/attendance_log.dart';
import 'day_card.dart';
import 'day_details_bottom_sheet.dart';

/// 100% device-responsive 7-column Bikram Sambat monthly attendance calendar grid.
/// Automatically expands across the full device width with ZERO horizontal scrolling.
class CalendarGrid extends StatelessWidget {
  final int bsYear;
  final int bsMonthIndex;
  final List<AttendanceLog> logs;
  final Set<String> savingDates;
  final void Function(String logDate, AttendanceStatus status) onStatusChange;
  final void Function(AttendanceLog log) onOpenTip;
  final void Function(AttendanceLog log) onOpenKm;
  final void Function(AttendanceLog log)? onOpenExtraTrip;

  const CalendarGrid({
    super.key,
    required this.bsYear,
    required this.bsMonthIndex,
    required this.logs,
    required this.savingDates,
    required this.onStatusChange,
    required this.onOpenTip,
    required this.onOpenKm,
    this.onOpenExtraTrip,
  });

  static const List<String> weekdayHeaders = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final firstAD = NepaliCalendarHelper.toGregorian(bsYear, bsMonthIndex, 1);
    // In Dart DateTime, weekday: 1=Mon, 7=Sun.
    // In our UI, 0=Sun, 1=Mon, ..., 6=Sat.
    final firstDayOfWeek = firstAD.weekday % 7;
    final todayStr = NepalClock.todayDateString();

    const double cellHeight = 74.0;

    // Construct cells list: leading blanks + day logs + trailing blanks
    final totalDays = NepaliCalendarHelper.getDaysInMonth(bsYear, bsMonthIndex);
    final cellsCount = firstDayOfWeek + totalDays;
    final trailingBlanks = (7 - (cellsCount % 7)) % 7;
    final totalGridCells = cellsCount + trailingBlanks;
    final totalWeeks = totalGridCells ~/ 7;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Responsive Weekday Header Row (Fits 100% width)
            Row(
              children: weekdayHeaders.map((dayName) {
                final isSat = dayName == 'Sat';
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    alignment: Alignment.center,
                    child: Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSat
                            ? const Color(0xFFDC2626) // Red for Saturday
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),

            // Responsive Calendar Week Rows (Fits 100% width with zero horizontal scroll)
            ...List.generate(totalWeeks, (weekIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: List.generate(7, (dayOfWeekIndex) {
                    final cellIndex = weekIndex * 7 + dayOfWeekIndex;

                    // Leading blank cell
                    if (cellIndex < firstDayOfWeek) {
                      return const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 1.5),
                          child: SizedBox(height: cellHeight),
                        ),
                      );
                    }

                    // Trailing blank cell
                    final dayNumber = cellIndex - firstDayOfWeek + 1;
                    if (dayNumber > totalDays) {
                      return const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 1.5),
                          child: SizedBox(height: cellHeight),
                        ),
                      );
                    }

                    // Active day cell
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

                    final nepaliDayNumber = NepaliCalendarHelper.toNepaliNumber(dayNumber);
                    final adDate = NepalClock.parseDate(log.logDate);
                    final dateLabel = '${adDate.day}';

                    final isToday = log.logDate == todayStr;
                    final isPast = NepalClock.isPast(log.logDate);
                    final hasMissingData = isPast &&
                        (log.isUnselected ||
                            (log.status == AttendanceStatus.present &&
                                (log.kmTotal == null || log.kmTotal! <= 0)));

                    final isSaving = savingDates.contains(log.logDate);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: SizedBox(
                          height: cellHeight,
                          child: DayCard(
                            log: log,
                            nepaliDayNumber: nepaliDayNumber,
                            dateLabel: dateLabel,
                            isToday: isToday,
                            hasMissingData: hasMissingData,
                            isSaving: isSaving,
                            onTap: () {
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
                            onChangeStatus: (status) =>
                                onStatusChange(log.logDate, status),
                            onOpenTip: () => onOpenTip(log),
                            onOpenKm: () => onOpenKm(log),
                            onOpenExtraTrip: onOpenExtraTrip != null
                                ? () => onOpenExtraTrip!(log)
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
