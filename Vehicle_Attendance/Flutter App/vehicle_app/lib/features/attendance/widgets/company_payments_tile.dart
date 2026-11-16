import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../controllers/attendance_controller.dart';
import 'company_payments_dialog.dart';

/// Full-width senior-friendly button tile on the dashboard Home tab.
/// Matches `FuelBillRecordsTile` styling with an emerald/green icon chip, high-contrast text,
/// and instant access to view and record mid-month company payments / tips received.
class CompanyPaymentsTile extends ConsumerWidget {
  const CompanyPaymentsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final attendanceState = ref.watch(attendanceControllerProvider);

    final totalReceived = attendanceState.logs.fold<int>(
      0,
      (sum, l) => sum + l.advanceAmount,
    );

    final subtitle = totalReceived > 0
        ? l10n.company_payments_tile_total(AppFormatters.formatCurrency(totalReceived, locale))
        : l10n.company_payments_tile_noPayments;

    return Container(
      key: const Key('company_payments_tile'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => CompanyPaymentsDialog.show(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Leading Emerald Icon Chip
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA), // Soft green
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFF16A34A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.company_payments_tile_title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        key: const Key('company_payments_tile_subtitle'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: totalReceived > 0 ? const Color(0xFF16A34A) : AppColors.textMuted,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Trailing Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

