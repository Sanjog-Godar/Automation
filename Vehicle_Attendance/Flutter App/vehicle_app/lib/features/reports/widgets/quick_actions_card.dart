import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../../fuel_bills/controllers/fuel_bills_controller.dart';
import '../../fuel_bills/widgets/generate_fuel_bill_dialog.dart';
import '../services/pdf_report_service.dart';

/// Quick Actions card: two white tiles for Generate Fuel Bill and Download Report.
/// Styled as clean white cards (matching the Fuel Bill Records tile). Fully localized.
class QuickActionsCard extends ConsumerStatefulWidget {
  const QuickActionsCard({super.key});

  @override
  ConsumerState<QuickActionsCard> createState() => _QuickActionsCardState();
}

class _QuickActionsCardState extends ConsumerState<QuickActionsCard> {
  bool _isGeneratingPdf = false;

  Future<void> _handleDownloadPdf(AppLocalizations l10n) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final attendanceState = ref.read(attendanceControllerProvider);
      final fuelBills = ref.read(fuelBillsControllerProvider).bills;
      final locale = Localizations.localeOf(context);

      await PdfReportService.generateAndDownloadReport(
        bsYear: attendanceState.currentYear,
        bsMonthIndex: attendanceState.currentMonthIndex,
        fullMonthLogs: attendanceState.logs,
        fuelBills: fuelBills,
        locale: locale,
      );
      if (mounted) {
        ref.read(toastServiceProvider).showSuccess(
          l10n.toast_pdfGenerated,
          nepaliMessage: l10n.toast_pdfGenerated,
        );
      }
    } catch (e) {
      if (mounted) {
        ref.read(toastServiceProvider).showError(
          l10n.toast_pdfFailed(e.toString()),
          nepaliMessage: l10n.toast_pdfFailed(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Generate Fuel Bill tile
        _ActionTile(
          key: const Key('quick_action_generate_fuel_bill'),
          iconWidget: const Icon(
            Icons.local_gas_station_rounded,
            color: AppColors.replacement,
            size: 24,
          ),
          iconBgColor: AppColors.replacementBg,
          title: l10n.quick_actions_fuelBill_title,
          subtitle: l10n.quick_actions_fuelBill_subtitle,
          onTap: () => GenerateFuelBillDialog.show(context),
        ),
        const SizedBox(height: 10),

        // Download Report tile
        _ActionTile(
          key: const Key('quick_action_download_report'),
          iconWidget: _isGeneratingPdf
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
          iconBgColor: AppColors.primarySoft,
          title: l10n.quick_actions_downloadPdf_title,
          subtitle: l10n.quick_actions_downloadPdf_subtitle,
          isLoading: _isGeneratingPdf,
          onTap: _isGeneratingPdf ? null : () => _handleDownloadPdf(l10n),
        ),
      ],
    );
  }
}

/// A single white action tile matching the [FuelBillRecordsTile] style.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    super.key,
    required this.iconWidget,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLoading = false,
  });

  final Widget iconWidget;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Leading icon chip
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: iconWidget,
                ),
                const SizedBox(width: 14),

                // Title & subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isLoading
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
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

                // Trailing chevron
                Icon(
                  Icons.chevron_right_rounded,
                  color: isLoading
                      ? AppColors.textMuted.withValues(alpha: 0.4)
                      : AppColors.textMuted,
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
