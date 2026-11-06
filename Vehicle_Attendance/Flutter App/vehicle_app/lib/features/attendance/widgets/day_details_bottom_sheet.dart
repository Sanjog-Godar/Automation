import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../../l10n/app_localizations.dart';
import '../models/attendance_log.dart';

/// Modal bottom sheet displaying detailed attendance status, KM entry,
/// and extra tips for a specific day. Fully localized with strict single-language rendering.
class DayDetailsBottomSheet extends StatelessWidget {
  final int dayNumber;
  final int bsYear;
  final int bsMonthIndex;
  final AttendanceLog log;
  final bool isSaving;
  final void Function(String logDate, AttendanceStatus newStatus) onStatusChange;
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
    required void Function(String logDate, AttendanceStatus newStatus) onStatusChange,
    required void Function(AttendanceLog log) onOpenTip,
    required void Function(AttendanceLog log) onOpenKm,
    void Function(AttendanceLog log)? onOpenExtraTrip,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    final adDate = NepalClock.parseDate(log.logDate);
    final dayOfWeek = adDate.weekday % 7; // 0=Sun ... 6=Sat

    final bsMonth = AppFormatters.bsMonthName(bsMonthIndex, locale);
    final bsDayStr = AppFormatters.formatNumber(dayNumber, locale);
    final weekdayStr = AppFormatters.weekdayName(dayOfWeek, locale, full: true);
    final adDateStr = AppFormatters.formatAdDate(adDate, locale, fullMonth: false);

    final isToday = log.logDate == NepalClock.todayDateString();
    final isPast = NepalClock.isPast(log.logDate);
    final isMissingStatus = isPast && log.isUnselected;
    final isMissingKm = isPast &&
        !log.isUnselected &&
        log.status == AttendanceStatus.present &&
        (log.kmTotal == null || log.kmTotal! <= 0);

    final isPresent = log.status == AttendanceStatus.present && !log.isUnselected;
    final isHoliday = log.status == AttendanceStatus.absentHoliday && !log.isUnselected;
    final isReplace = log.status == AttendanceStatus.absentReplacement && !log.isUnselected;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header: Selected-date card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '$bsDayStr $bsMonth, $weekdayStr',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Mukta',
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    l10n.calendar_legend_today.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$weekdayStr, $adDateStr',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, size: 22, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Inline Missing Data Warnings
              if (isMissingStatus) ...[
                Container(
                  key: const Key('sheet_missing_status_warning'),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.missingStatusBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.missingStatusBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.missingStatus),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.day_sheet_missingStatusAlert,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.missingStatus,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else if (isMissingKm) ...[
                Container(
                  key: const Key('sheet_missing_km_warning'),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.missingKmBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.missingKmBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.missingKm),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.day_sheet_missingKmAlert,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.missingKm,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Section Label
              Text(
                l10n.day_sheet_attendanceStatusTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Three Segmented Status Buttons (P / H / R)
              Row(
                children: [
                  _buildStatusButton(
                    context: context,
                    key: const Key('sheet_status_btn_present'),
                    label: l10n.status_present,
                    subtext: AppFormatters.formatCurrency(AppConstants.dailyWage, locale),
                    isActive: isPresent,
                    activeColor: AppColors.present,
                    activeBg: AppColors.presentBg,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onStatusChange(log.logDate, AttendanceStatus.present);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildStatusButton(
                    context: context,
                    key: const Key('sheet_status_btn_holiday'),
                    label: l10n.status_holiday,
                    subtext: l10n.status_holidaySubtitle,
                    isActive: isHoliday,
                    activeColor: AppColors.holiday,
                    activeBg: AppColors.holidayBg,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onStatusChange(log.logDate, AttendanceStatus.absentHoliday);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildStatusButton(
                    context: context,
                    key: const Key('sheet_status_btn_replace'),
                    label: l10n.status_replace,
                    subtext: '-${AppFormatters.formatCurrency(AppConstants.replacementDeduction, locale)}',
                    isActive: isReplace,
                    activeColor: AppColors.replacement,
                    activeBg: AppColors.replacementBg,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onStatusChange(log.logDate, AttendanceStatus.absentReplacement);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Records & Modals Section (KM, Extra Tip, Extra Trip)
              Text(
                l10n.day_sheet_detailsRecordsTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Odometer KM Button
              _buildActionRow(
                context: context,
                icon: Icons.speed_rounded,
                iconColor: AppColors.primary,
                title: log.kmTotal != null && log.kmTotal! > 0
                    ? '${AppFormatters.formatUnit(log.kmTotal!, 'km', locale)} (${AppFormatters.formatNumber(log.kmStart ?? 0, locale)} - ${AppFormatters.formatNumber(log.kmEnd ?? 0, locale)})'
                    : l10n.day_sheet_enterKmTitle,
                subtitle: l10n.day_sheet_enterKmSubtitle,
                buttonText: log.kmTotal != null && log.kmTotal! > 0 ? l10n.common_edit : l10n.common_add,
                buttonColor: AppColors.primary,
                isEnabled: isPresent,
                onTap: isPresent
                    ? () {
                        Navigator.pop(context);
                        onOpenKm(log);
                      }
                    : null,
              ),
              const SizedBox(height: 8),

              // Extra Tip Button
              _buildActionRow(
                context: context,
                icon: Icons.volunteer_activism_rounded,
                iconColor: AppColors.primary,
                title: log.extraTipAmount != null && log.extraTipAmount! > 0
                    ? '${l10n.tip_sheet_title}: ${AppFormatters.formatCurrency(log.extraTipAmount!, locale)}${log.extraTipNote != null ? " (${log.extraTipNote})" : ""}'
                    : l10n.day_sheet_addTipTitle,
                subtitle: l10n.day_sheet_addTipSubtitle,
                buttonText: log.extraTipAmount != null && log.extraTipAmount! > 0 ? l10n.common_edit : l10n.common_add,
                buttonColor: AppColors.primary,
                isEnabled: true,
                onTap: () {
                  Navigator.pop(context);
                  onOpenTip(log);
                },
              ),

              // Extra Trip Income (Present days)
              if (isPresent && onOpenExtraTrip != null) ...[
                const SizedBox(height: 8),
                _buildActionRow(
                  context: context,
                  icon: Icons.add_circle_outline_rounded,
                  iconColor: AppColors.present,
                  title: log.extraTripIncome > 0
                      ? '${l10n.trip_dialog_title}: ${AppFormatters.formatCurrency(log.extraTripIncome, locale)}'
                      : l10n.day_sheet_extraTripTitle,
                  subtitle: l10n.day_sheet_extraTripSubtitle,
                  buttonText: log.extraTripIncome > 0 ? l10n.common_edit : l10n.common_add,
                  buttonColor: AppColors.present,
                  isEnabled: true,
                  onTap: () {
                    Navigator.pop(context);
                    onOpenExtraTrip!(log);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required BuildContext context,
    required Key key,
    required String label,
    required String subtext,
    required bool isActive,
    required Color activeColor,
    required Color activeBg,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isActive ? activeBg : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? activeColor : AppColors.border,
                width: isActive ? 1.8 : 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isActive ? activeColor : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? activeColor : AppColors.textMuted,
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
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color buttonColor,
    required bool isEnabled,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isEnabled ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isEnabled ? buttonColor.withValues(alpha: 0.1) : AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 20,
                    color: isEnabled ? buttonColor : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isEnabled ? buttonColor.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isEnabled ? buttonColor.withValues(alpha: 0.3) : AppColors.border,
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? buttonColor : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
