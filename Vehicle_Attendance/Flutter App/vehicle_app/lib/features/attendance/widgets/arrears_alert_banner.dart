import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/settlements_controller.dart';

/// Notification banner displayed at the top of the Home dashboard
/// whenever the previous month has an unpaid salary balance/arrears from the company.
class ArrearsAlertBanner extends ConsumerWidget {
  const ArrearsAlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final settlementsState = ref.watch(settlementsControllerProvider);
    final attendanceState = ref.watch(attendanceControllerProvider);

    if (!settlementsState.hasPreviousMonthDue) {
      return const SizedBox.shrink();
    }

    final prevDue = settlementsState.previousMonthDue;
    final prevMonthIndex = attendanceState.currentMonthIndex == 0
        ? 11
        : attendanceState.currentMonthIndex - 1;
    final prevMonthName = AppFormatters.bsMonthName(prevMonthIndex, locale);
    final prevYear = attendanceState.currentMonthIndex == 0
        ? attendanceState.currentYear - 1
        : attendanceState.currentYear;
    final prevYearStr = AppFormatters.formatYear(prevYear, locale);
    final prevMonthYear = '$prevMonthName $prevYearStr';

    final dueAmountFormatted = AppFormatters.formatCurrency(prevDue, locale);

    return Container(
      key: const Key('arrears_alert_banner'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // Light soft red/rose
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0DC53030),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFDC2626),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.settlement_arrears_banner_title,
                      style: const TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dueAmountFormatted,
                        style: const TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.settlement_arrears_banner_desc(dueAmountFormatted, prevMonthYear),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF7F1D1D),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

