import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../../core/utils/nepali_calendar_helper.dart';
import '../models/attendance_log.dart';

/// Bottom sheet opened when tapping any day cell on the responsive Calendar Grid.
/// Provides large, thumb-friendly touch targets for drivers to mark attendance, KM, and tips.
class DayDetailsBottomSheet extends StatelessWidget {
  final int dayNumber;
  final int bsYear;
  final int bsMonthIndex;
  final AttendanceLog log;
  final bool isSaving;
  final void Function(String logDate, AttendanceStatus status) onStatusChange;
  final void Function(AttendanceLog log) onOpenTip;
  final void Function(AttendanceLog log) onOpenKm;
  final void Function(AttendanceLog log)? onOpenExtraTrip;

  const DayDetailsBottomSheet({
    super.key,
    required this.dayNumber,
    required this.bsYear,
    required this.bsMonthIndex,
    required this.log,
    required this.isSaving,
    required this.onStatusChange,
    required this.onOpenTip,
    required this.onOpenKm,
    this.onOpenExtraTrip,
  });

  static Future<void> show({
    required BuildContext context,
    required int dayNumber,
    required int bsYear,
    required int bsMonthIndex,
    required AttendanceLog log,
    required bool isSaving,
    required void Function(String logDate, AttendanceStatus status) onStatusChange,
    required void Function(AttendanceLog log) onOpenTip,
    required void Function(AttendanceLog log) onOpenKm,
    void Function(AttendanceLog log)? onOpenExtraTrip,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DayDetailsBottomSheet(
        dayNumber: dayNumber,
        bsYear: bsYear,
        bsMonthIndex: bsMonthIndex,
        log: log,
        isSaving: isSaving,
        onStatusChange: onStatusChange,
        onOpenTip: onOpenTip,
        onOpenKm: onOpenKm,
        onOpenExtraTrip: onOpenExtraTrip,
      ),
    );
  }

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
    final monthNameDevanagari = NepaliCalendarHelper.nepaliMonths[bsMonthIndex];
    final nepaliDayNum = NepaliCalendarHelper.toNepaliNumber(dayNumber);
    final adDate = NepalClock.parseDate(log.logDate);
    const monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateLabel = '${adDate.day} ${monthNames[adDate.month]} ${adDate.year}';
    final weekdayIndex = adDate.weekday % 7;
    final nepaliWeekdayName = nepaliWeekdays[weekdayIndex];
    final isToday = NepalClock.isToday(log.logDate);
    final isPast = NepalClock.isPast(log.logDate);

    final isPresent = log.status == AttendanceStatus.present && !log.isUnselected;
    final isHoliday = log.status == AttendanceStatus.absentHoliday && !log.isUnselected;
    final isReplace = log.status == AttendanceStatus.absentReplacement && !log.isUnselected;

    final hasMissingData = isPast &&
        (log.isUnselected ||
            (log.status == AttendanceStatus.present &&
                (log.kmTotal == null || log.kmTotal! <= 0)));

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Nepali Date, English Date & Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.primary : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      nepaliDayNum,
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : const Color(0xFF1E293B),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
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
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Missing Data Alert Banner
          if (hasMissingData) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.isUnselected ? 'Attendance status is unmarked for this date' : 'KM reading is missing',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Attendance Status Section Title
          const Text(
            'Attendance Status / उपस्थिति स्थिति',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),

          // 3 Large Touch-Friendly Status Buttons
          Row(
            children: [
              _buildStatusButton(
                context: context,
                label: 'Present',
                nepaliLabel: 'उपस्थित',
                subtext: 'Rs. 1,200',
                isActive: isPresent,
                activeBg: AppColors.present,
                onTap: () {
                  onStatusChange(log.logDate, AttendanceStatus.present);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8),
              _buildStatusButton(
                context: context,
                label: 'Holiday',
                nepaliLabel: 'विदा',
                subtext: 'No pay',
                isActive: isHoliday,
                activeBg: AppColors.holiday,
                onTap: () {
                  onStatusChange(log.logDate, AttendanceStatus.absentHoliday);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8),
              _buildStatusButton(
                context: context,
                label: 'Replace',
                nepaliLabel: 'सट्टा',
                subtext: '-Rs. 3,000',
                isActive: isReplace,
                activeBg: AppColors.replacement,
                onTap: () {
                  onStatusChange(log.logDate, AttendanceStatus.absentReplacement);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Actions: KM, Tip, Extra Trip
          const Text(
            'Details & Records / विवरणहरू',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),

          // Odometer KM Button
          _buildActionRow(
            icon: Icons.speed_rounded,
            iconColor: const Color(0xFF7E22CE),
            title: log.kmTotal != null && log.kmTotal! > 0
                ? '${log.kmTotal} km Run (${log.kmStart ?? 0} - ${log.kmEnd ?? 0})'
                : 'Enter Odometer KM',
            subtitle: log.kmTotal != null && log.kmTotal! > 0
                ? 'Tap to update starting & ending KM'
                : 'Starting & ending odometer reading',
            buttonText: log.kmTotal != null && log.kmTotal! > 0 ? 'Edit' : '+ Add',
            buttonColor: const Color(0xFF7E22CE),
            onTap: () {
              Navigator.pop(context);
              onOpenKm(log);
            },
          ),
          const SizedBox(height: 8),

          // Extra Tip Button
          _buildActionRow(
            icon: Icons.volunteer_activism_rounded,
            iconColor: AppColors.primary,
            title: log.extraTipAmount != null && log.extraTipAmount! > 0
                ? 'Extra Tip: Rs. ${log.extraTipAmount}${log.extraTipNote != null ? " (${log.extraTipNote})" : ""}'
                : 'Add Extra Tip',
            subtitle: 'Additional customer tips or gratuities',
            buttonText: log.extraTipAmount != null && log.extraTipAmount! > 0 ? 'Edit' : '+ Add',
            buttonColor: AppColors.primary,
            onTap: () {
              Navigator.pop(context);
              onOpenTip(log);
            },
          ),

          // Extra Trip Income (if Present)
          if (isPresent && onOpenExtraTrip != null) ...[
            const SizedBox(height: 8),
            _buildActionRow(
              icon: Icons.add_circle_outline_rounded,
              iconColor: const Color(0xFF0F766E),
              title: log.extraTripIncome > 0
                  ? 'Extra Trip Income: Rs. ${log.extraTripIncome}'
                  : 'Add Extra Trip Income',
              subtitle: 'Earnings from extra trips beyond regular route',
              buttonText: log.extraTripIncome > 0 ? 'Edit' : '+ Add',
              buttonColor: const Color(0xFF0F766E),
              onTap: () {
                Navigator.pop(context);
                onOpenExtraTrip!(log);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required BuildContext context,
    required String label,
    required String nepaliLabel,
    required String subtext,
    required bool isActive,
    required Color activeBg,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? activeBg : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? activeBg : const Color(0xFFCBD5E1),
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeBg.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  nepaliLabel,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: 11,
                    color: isActive ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: buttonColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: buttonColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: buttonColor,
            ),
            onPressed: onTap,
            child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

