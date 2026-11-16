import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../controllers/settlements_controller.dart';
import 'salary_settlement_dialog.dart';

/// Full-width senior-friendly button tile on the dashboard Home tab.
/// Matches `FuelBillRecordsTile` and `CompanyPaymentsTile` styling.
/// Displays bank salary settlement status and gives instant access to record final payout.
class SalarySettlementTile extends ConsumerWidget {
  const SalarySettlementTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final settlementsState = ref.watch(settlementsControllerProvider);
    final currentSettlement = settlementsState.currentSettlement;

    final hasRecord = currentSettlement != null && currentSettlement.bankReceivedAmount > 0;
    final isFullyPaid = hasRecord && currentSettlement.isFullySettled;
    final isPartial = hasRecord && currentSettlement.isPartiallySettled;

    String subtitle;
    Color subtitleColor;

    if (isFullyPaid) {
      subtitle = l10n.settlement_tile_fullySettled(
        AppFormatters.formatCurrency(currentSettlement.bankReceivedAmount, locale),
      );
      subtitleColor = const Color(0xFF16A34A); // green
    } else if (isPartial) {
      subtitle = l10n.settlement_tile_pending(
        AppFormatters.formatCurrency(currentSettlement.pendingAmount, locale),
      );
      subtitleColor = const Color(0xFFDC2626); // red
    } else {
      subtitle = l10n.settlement_tile_notRecorded;
      subtitleColor = AppColors.textMuted;
    }

    return Container(
      key: const Key('salary_settlement_tile'),
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
          onTap: () => SalarySettlementDialog.show(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Leading Soft Blue Icon Chip
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF), // soft blue
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: Color(0xFF2563EB),
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
                        l10n.settlement_tile_title,
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
                        key: const Key('salary_settlement_tile_subtitle'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
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

