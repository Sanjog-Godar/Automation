import 'package:flutter/material.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../models/monthly_summary.dart';

/// Senior-friendly, calm dashboard card displaying monthly attendance metrics.
/// Clean light-only surfaces, high-contrast typography, large numbers (22-24sp+),
/// and thin tinted left accents with zero neon gradients. Fully localized.
class MonthlySummaryCard extends StatelessWidget {
  final MonthlySummary summary;
  final bool isLoading;

  const MonthlySummaryCard({
    super.key,
    required this.summary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    l10n.summary_card_title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Adaptive Metric Tiles (White cards with thin tinted left accent)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final columnCount = isWide ? 3 : 2;

              return GridView.count(
                crossAxisCount: columnCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: isWide ? 2.5 : 1.85,
                children: [
                  _buildMetricTile(
                    label: l10n.summary_presentDays,
                    value: AppFormatters.formatNumber(summary.totalPresentDays, locale),
                    icon: Icons.check_circle_rounded,
                    accentColor: AppColors.present,
                    iconBgColor: AppColors.presentBg,
                  ),
                  _buildMetricTile(
                    label: l10n.summary_extraTips,
                    value: AppFormatters.formatNumber(summary.totalExtraTips, locale),
                    icon: Icons.volunteer_activism_rounded,
                    accentColor: AppColors.primary,
                    iconBgColor: AppColors.primarySoft,
                  ),
                  _buildMetricTile(
                    label: l10n.summary_replacementDays,
                    value: AppFormatters.formatNumber(summary.totalReplacementDays, locale),
                    icon: Icons.person_off_rounded,
                    accentColor: AppColors.replacement,
                    iconBgColor: AppColors.replacementBg,
                  ),
                  _buildMetricTile(
                    label: l10n.summary_totalKm,
                    value: AppFormatters.formatUnit(summary.totalKm, 'km', locale),
                    icon: Icons.speed_rounded,
                    accentColor: AppColors.primary,
                    iconBgColor: AppColors.primarySoft,
                  ),
                  _buildMetricTile(
                    label: l10n.summary_extraTrips,
                    value: AppFormatters.formatNumber(summary.totalExtraIncome, locale),
                    icon: Icons.trending_up_rounded,
                    accentColor: AppColors.present,
                    iconBgColor: AppColors.presentBg,
                  ),
                  _buildMetricTile(
                    label: l10n.summary_deductions,
                    value: '-${AppFormatters.formatNumber(summary.totalDeductions, locale)}',
                    icon: Icons.trending_down_rounded,
                    accentColor: AppColors.holiday,
                    iconBgColor: AppColors.holidayBg,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Prominent Net Income Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.summary_netIncome,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppFormatters.formatCurrency(summary.netIncome, locale),
                          style: TextStyle(
                            color: summary.netIncome >= 0
                                ? AppColors.incomePositive
                                : AppColors.incomeNegative,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.summary_netIncomeFormula,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
    required Color iconBgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 4dp Tinted Left Accent Strip
              Container(width: 4, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      // Tinted Soft Icon Chip
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, color: accentColor, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
