import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../controllers/fuel_bills_controller.dart';
import 'fuel_bill_records_dialog.dart';

/// Full-width senior-friendly button card on the dashboard scroll.
/// White surface with a soft amber icon chip, high-contrast text, and 48dp+ tap area.
/// Fully localized with strict single-language rendering.
class FuelBillRecordsTile extends ConsumerWidget {
  const FuelBillRecordsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final fuelBillsState = ref.watch(fuelBillsControllerProvider);

    final bills = fuelBillsState.bills;
    final lastBillDate = fuelBillsState.lastBillDate ??
        (bills.isNotEmpty ? bills.first.endDate : null);

    final displayDate = lastBillDate != null
        ? (locale.languageCode == 'ne'
            ? AppFormatters.toDevanagariDigits(lastBillDate)
            : lastBillDate)
        : '';

    final subtitle = (lastBillDate != null && lastBillDate.isNotEmpty)
        ? l10n.fuel_records_tile_lastEnded(displayDate)
        : l10n.fuel_records_tile_noBills;

    return Container(
      key: const Key('fuel_bill_records_tile'),
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
          onTap: () => FuelBillRecordsDialog.show(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Leading Soft Amber Icon Chip
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.missingKmBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.local_gas_station_rounded,
                    color: AppColors.replacement,
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
                        l10n.fuel_records_tile_title,
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
                        key: const Key('fuel_bill_tile_subtitle'),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Trailing Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
