import 'package:flutter/material.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../../core/utils/nepali_calendar_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../models/attendance_log.dart';
import 'extra_trip_dialog.dart';

/// Card listing recorded extra tips for the currently selected month.
/// Appears directly below the Monthly Running Summary table when tip records exist.
/// Fully localized in Nepali and English with identical information hierarchy to the website.
class TipsRecordCard extends StatelessWidget {
  final List<AttendanceLog> logs;
  final void Function(AttendanceLog log)? onEditTip;

  const TipsRecordCard({
    super.key,
    required this.logs,
    this.onEditTip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final isNepali = locale.languageCode == 'ne';

    // Filter logs that belong to the active month and have recorded tips
    final tipLogs = logs
        .where((log) => !log.isUnselected && log.effectiveTipAmount > 0)
        .toList()
      ..sort((a, b) => a.logDate.compareTo(b.logDate));

    // Only display if tip records exist for the month
    if (tipLogs.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalTips = tipLogs.fold<int>(
      0,
      (sum, item) => sum + item.effectiveTipAmount,
    );

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
                        Icons.payments_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.tips_record_title,
                        style: const TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.presentBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.presentBorder.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        AppFormatters.formatCurrency(totalTips, locale),
                        style: const TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.present,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.border),

              // Tip Items List
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    for (int i = 0; i < tipLogs.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _buildTipItem(
                        context: context,
                        log: tipLogs[i],
                        locale: locale,
                        isNepali: isNepali,
                        l10n: l10n,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem({
    required BuildContext context,
    required AttendanceLog log,
    required Locale locale,
    required bool isNepali,
    required AppLocalizations l10n,
  }) {
    // Format Nepali date (e.g. कार्तिक २४, २०८३ / Kartik 24, 2083)
    final adDate = NepalClock.parseDate(log.logDate);
    final nepaliDt = NepaliCalendarHelper.fromGregorian(adDate);
    final monthName = AppFormatters.bsMonthName(nepaliDt.month - 1, locale);
    final dayStr = isNepali ? NepaliCalendarHelper.toNepaliNumber(nepaliDt.day) : '${nepaliDt.day}';
    final yearStr = isNepali ? NepaliCalendarHelper.toNepaliNumber(nepaliDt.year) : '${nepaliDt.year}';
    final nepaliDateFormatted = '$monthName $dayStr, $yearStr';

    final parsed = ExtraTripDialog.parseUpayeNote(log.extraTipNote);
    final isUpaye = parsed.isUpaye;
    final cleanNote = parsed.cleanNote;
    final hasNote = cleanNote.isNotEmpty;
    final noteText = hasNote ? cleanNote : (isUpaye ? '' : l10n.tips_record_noNote);

    return Material(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEditTip != null ? () => onEditTip!(log) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date row: Nepali date on top + Gregorian date in parenthesis
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          nepaliDateFormatted,
                          style: const TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '(${log.logDate})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (isUpaye)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              isNepali ? 'उपाय' : 'Upaye',
                              style: const TextStyle(
                                fontFamily: 'Mukta',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (noteText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        noteText,
                        style: TextStyle(
                          fontSize: 13,
                          color: hasNote ? AppColors.textPrimary : AppColors.textMuted,
                          fontStyle: hasNote ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Tip Amount
              Text(
                AppFormatters.formatCurrency(log.effectiveTipAmount, locale),
                style: const TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.present,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

