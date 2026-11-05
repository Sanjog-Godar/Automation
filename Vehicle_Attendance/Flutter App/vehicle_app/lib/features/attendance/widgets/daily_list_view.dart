import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../../core/utils/nepali_calendar_helper.dart';
import '../models/attendance_log.dart';

/// Full-width, mobile-optimized vertical list of daily attendance logs.
/// Provides large, thumb-friendly touch targets for drivers on mobile phones.
class DailyListView extends StatelessWidget {
  final int bsYear;
  final int bsMonthIndex;
  final List<AttendanceLog> logs;
  final Set<String> savingDates;
  final void Function(String logDate, AttendanceStatus status) onStatusChange;
  final void Function(AttendanceLog log) onOpenTip;
  final void Function(AttendanceLog log) onOpenKm;
  final void Function(AttendanceLog log)? onOpenExtraTrip;

  const DailyListView({
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

  static const List<String> nepaliWeekdays = [
    'आइतबार',
    'सोमबार',
    'मंगलबार',
    'बुधबार',
    'बिहीबार',
    'शुक्रबार',
    'शनिबार',
  ];

  @override
  Widget build(BuildContext context) {
    final todayStr = NepalClock.todayDateString();
    final monthNameDevanagari = NepaliCalendarHelper.nepaliMonths[bsMonthIndex];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final dayNumber = index + 1;
        final log = logs[index];
        final isToday = log.logDate == todayStr;
        final isPast = NepalClock.isPast(log.logDate);
        final isSaving = savingDates.contains(log.logDate);

        final hasMissingData = isPast &&
            (log.isUnselected ||
                (log.status == AttendanceStatus.present &&
                    (log.kmTotal == null || log.kmTotal! <= 0)));

        final adDate = NepalClock.parseDate(log.logDate);
        const monthNames = [
          '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final dateLabel = '${adDate.day} ${monthNames[adDate.month]} ${adDate.year}';

        // Nepali day of week (0=Sun, 6=Sat)
        final weekdayIndex = adDate.weekday % 7;
        final nepaliWeekdayName = nepaliWeekdays[weekdayIndex];
        final nepaliDayNum = NepaliCalendarHelper.toNepaliNumber(dayNumber);

        final isPresent = log.status == AttendanceStatus.present;
        final isHoliday = log.status == AttendanceStatus.absentHoliday;
        final isReplace = log.status == AttendanceStatus.absentReplacement;
        final isUnselected = log.isUnselected;

        // Card Border and Background
        Color cardBg = Colors.white;
        Border cardBorder = Border.all(color: const Color(0xFFE5E7EB));

        if (hasMissingData) {
          cardBg = const Color(0xFFFFF7F7);
          cardBorder = Border.all(color: const Color(0xFFEF4444), width: 1.5);
        } else if (isToday) {
          cardBg = const Color(0xFFF0F7FF);
          cardBorder = Border.all(color: const Color(0xFF3B82F6), width: 1.5);
        }

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: cardBorder,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Row: Date, Day of Week, and Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.primary
                              : weekdayIndex == 6
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          nepaliDayNum,
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? Colors.white
                                : weekdayIndex == 6
                                    ? AppColors.holiday
                                    : const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '$monthNameDevanagari $nepaliDayNum ($nepaliWeekdayName)',
                                style: const TextStyle(
                                  fontFamily: 'Mukta',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'TODAY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isSaving)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    _buildStatusBadge(
                      isUnselected: isUnselected,
                      isPresent: isPresent,
                      isHoliday: isHoliday,
                      isReplace: isReplace,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Status Toggle Buttons Row (Large, Touch-Friendly)
              Row(
                children: [
                  _buildLargeStatusButton(
                    label: 'Present',
                    nepaliLabel: 'उपस्थित',
                    isActive: isPresent && !isUnselected,
                    activeColor: AppColors.present,
                    onTap: () => onStatusChange(log.logDate, AttendanceStatus.present),
                  ),
                  const SizedBox(width: 8),
                  _buildLargeStatusButton(
                    label: 'Holiday',
                    nepaliLabel: 'विदा',
                    isActive: isHoliday && !isUnselected,
                    activeColor: AppColors.holiday,
                    onTap: () => onStatusChange(log.logDate, AttendanceStatus.absentHoliday),
                  ),
                  const SizedBox(width: 8),
                  _buildLargeStatusButton(
                    label: 'Replace',
                    nepaliLabel: 'सट्टा',
                    isActive: isReplace && !isUnselected,
                    activeColor: AppColors.replacement,
                    onTap: () => onStatusChange(log.logDate, AttendanceStatus.absentReplacement),
                  ),
                ],
              ),

              // Missing Data Warning Banner
              if (hasMissingData) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 6),
                      Text(
                        'Missing entry: ${isUnselected ? "Status not marked" : "KM odometer entry required"}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Action Chips (Extra Trip, Tip, KM)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  // KM Action Chip
                  ActionChip(
                    avatar: const Icon(Icons.speed, size: 16, color: Color(0xFF9333EA)),
                    label: Text(
                      log.kmTotal != null && log.kmTotal! > 0
                          ? '${log.kmTotal} km (${log.kmStart ?? 0}-${log.kmEnd ?? 0})'
                          : '+ Enter KM',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7E22CE),
                      ),
                    ),
                    backgroundColor: const Color(0xFFFAF5FF),
                    side: const BorderSide(color: Color(0xFFE9D5FF)),
                    onPressed: () => onOpenKm(log),
                  ),

                  // Tip Action Chip
                  ActionChip(
                    avatar: const Icon(Icons.volunteer_activism_outlined, size: 16, color: AppColors.primary),
                    label: Text(
                      log.extraTipAmount != null && log.extraTipAmount! > 0
                          ? 'Tip: Rs. ${log.extraTipAmount}${log.extraTipNote != null ? " (${log.extraTipNote})" : ""}'
                          : '+ Add Tip',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    onPressed: () => onOpenTip(log),
                  ),

                  // Extra Trip Income Chip (only relevant when Present)
                  if (isPresent && !isUnselected)
                    ActionChip(
                      avatar: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF0D9488)),
                      label: Text(
                        log.extraTripIncome > 0
                            ? 'Extra Trip: Rs. ${log.extraTripIncome}'
                            : '+ Extra Trip',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0D9488),
                        ),
                      ),
                      backgroundColor: const Color(0xFFF0FDFA),
                      side: const BorderSide(color: Color(0xFF99F6E4)),
                      onPressed: onOpenExtraTrip != null ? () => onOpenExtraTrip!(log) : null,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge({
    required bool isUnselected,
    required bool isPresent,
    required bool isHoliday,
    required bool isReplace,
  }) {
    if (isUnselected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: const Text(
          'Unmarked',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      );
    }

    final Color color = isPresent
        ? AppColors.present
        : isHoliday
            ? AppColors.holiday
            : AppColors.replacement;

    final String text = isPresent
        ? 'Present (Rs. 1,200)'
        : isHoliday
            ? 'Holiday'
            : 'Replace (-Rs. 3,000)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLargeStatusButton({
    required String label,
    required String nepaliLabel,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? activeColor : const Color(0xFFD1D5DB),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : const Color(0xFF374151),
                ),
              ),
              Text(
                nepaliLabel,
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: 11,
                  color: isActive ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

