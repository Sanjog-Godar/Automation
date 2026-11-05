import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/attendance_log.dart';

/// Highly responsive, compact day card for the Bikram Sambat monthly calendar grid.
/// Fits 100% device width within responsive 7-column layout with ZERO horizontal scrolling.
class DayCard extends StatelessWidget {
  final AttendanceLog log;
  final String nepaliDayNumber; // Devanagari digit (e.g. '१', '२')
  final String dateLabel; // Gregorian label (e.g. '28')
  final bool isToday;
  final bool hasMissingData;
  final bool isSaving;
  final VoidCallback onTap;
  final ValueChanged<AttendanceStatus>? onChangeStatus;
  final VoidCallback? onOpenTip;
  final VoidCallback? onOpenKm;
  final VoidCallback? onOpenExtraTrip;

  const DayCard({
    super.key,
    required this.log,
    required this.nepaliDayNumber,
    required this.dateLabel,
    required this.isToday,
    required this.hasMissingData,
    required this.isSaving,
    required this.onTap,
    this.onChangeStatus,
    this.onOpenTip,
    this.onOpenKm,
    this.onOpenExtraTrip,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = log.status == AttendanceStatus.present && !log.isUnselected;
    final isAbsentHoliday = log.status == AttendanceStatus.absentHoliday && !log.isUnselected;
    final isUnselected = log.isUnselected;

    // Status Badge Configuration
    final String badgeLabel;
    final Color badgeBg;
    final Color badgeTextColor;

    if (isUnselected) {
      badgeLabel = '—';
      badgeBg = const Color(0xFFF1F5F9);
      badgeTextColor = const Color(0xFF94A3B8);
    } else if (isPresent) {
      badgeLabel = '✓ P';
      badgeBg = AppColors.present;
      badgeTextColor = Colors.white;
    } else if (isAbsentHoliday) {
      badgeLabel = 'H';
      badgeBg = AppColors.holiday;
      badgeTextColor = Colors.white;
    } else {
      badgeLabel = 'R';
      badgeBg = AppColors.replacement;
      badgeTextColor = Colors.white;
    }

    // Card border and background styling
    Color cardBg = Colors.white;
    Color borderColor = const Color(0xFFE2E8F0);

    if (hasMissingData) {
      cardBg = const Color(0xFFFFFBFB);
      borderColor = const Color(0xFFF87171); // red-400
    } else if (isToday) {
      cardBg = const Color(0xFFF8FAFC);
      borderColor = const Color(0xFF60A5FA); // blue-400
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            border: Border.all(
              color: borderColor,
              width: isToday || hasMissingData ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 3.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Row: Nepali Day + English Day + Today Dot
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      nepaliDayNumber,
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isToday ? AppColors.primary : const Color(0xFF1E293B),
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: Color(0xFF64748B),
                      height: 1.0,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
              const SizedBox(height: 2),

              // Status Pill / Badge
              Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child: isSaving
                    ? const SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                      )
                    : Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                          height: 1.1,
                        ),
                        maxLines: 1,
                      ),
              ),
              const SizedBox(height: 2),

              // Bottom Indicator Row: KM, Tip, Warning dot
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (log.kmTotal != null && log.kmTotal! > 0)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: const Color(0xFFDDD6FE), width: 0.5),
                      ),
                      child: Text(
                        '${log.kmTotal}k',
                        style: const TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7E22CE),
                          height: 1.0,
                        ),
                      ),
                    ),
                  if (log.extraTipAmount != null && log.extraTipAmount! > 0)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: const Color(0xFFBFDBFE), width: 0.5),
                      ),
                      child: Text(
                        '₹${log.extraTipAmount}',
                        style: const TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          height: 1.0,
                        ),
                      ),
                    ),
                  if (hasMissingData)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 1),
                      child: Text('⚠️', style: TextStyle(fontSize: 8, height: 1.0)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
