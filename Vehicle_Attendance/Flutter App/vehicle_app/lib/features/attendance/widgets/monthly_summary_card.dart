import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../models/monthly_summary.dart';

/// Highly responsive, modern dashboard card displaying attendance summary metrics.
/// Adapts gracefully from compact mobile viewports to wide tablet/desktop viewports.
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
    final currencyFormatter = NumberFormat('#,##,###', 'en_IN');

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Monthly Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Adaptive Metric Tiles
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
                  childAspectRatio: isWide ? 2.4 : 2.1,
                  children: [
                    _buildMetricTile(
                      label: 'Present Days',
                      value: summary.totalPresentDays.toString(),
                      icon: Icons.check_circle_outline,
                      iconColor: AppColors.present,
                      bgColor: const Color(0xFFF0FDF4), // green-50
                      borderColor: const Color(0xFFDCFCE7), // green-100
                    ),
                    _buildMetricTile(
                      label: 'Extra Tips (Rs.)',
                      value: currencyFormatter.format(summary.totalExtraTips),
                      icon: Icons.volunteer_activism_outlined,
                      iconColor: AppColors.primary,
                      bgColor: const Color(0xFFEFF6FF), // blue-50
                      borderColor: const Color(0xFFDBEAFE), // blue-100
                    ),
                    _buildMetricTile(
                      label: 'Replacement Days',
                      value: summary.totalReplacementDays.toString(),
                      icon: Icons.person_off_outlined,
                      iconColor: AppColors.holiday,
                      bgColor: const Color(0xFFFEF2F2), // red-50
                      borderColor: const Color(0xFFFEE2E2), // red-100
                      valueColor: AppColors.holiday,
                    ),
                    _buildMetricTile(
                      label: 'Total KM Run',
                      value: '${currencyFormatter.format(summary.totalKm)} km',
                      icon: Icons.speed_outlined,
                      iconColor: const Color(0xFF9333EA),
                      bgColor: const Color(0xFFFAF5FF), // purple-50
                      borderColor: const Color(0xFFF3E8FF), // purple-100
                      valueColor: const Color(0xFF7E22CE),
                    ),
                    _buildMetricTile(
                      label: 'Extra Trips (Rs.)',
                      value: currencyFormatter.format(summary.totalExtraIncome),
                      icon: Icons.trending_up,
                      iconColor: const Color(0xFF0D9488),
                      bgColor: const Color(0xFFF0FDFA), // teal-50
                      borderColor: const Color(0xFFCCFBF1), // teal-100
                    ),
                    _buildMetricTile(
                      label: 'Deductions (Rs.)',
                      value: '-${currencyFormatter.format(summary.totalDeductions)}',
                      icon: Icons.trending_down,
                      iconColor: AppColors.holiday,
                      bgColor: const Color(0xFFFEF2F2), // red-50
                      borderColor: const Color(0xFFFEE2E2), // red-100
                      valueColor: AppColors.holiday,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),

            // Prominent Net Income Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF15803D), // green-700
                    Color(0xFF16A34A), // green-600
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Income (Rs.)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '(Earnings - Deductions)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Rs. ${currencyFormatter.format(summary.netIncome)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    Color valueColor = const Color(0xFF111827),
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
