import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../models/monthly_summary.dart';

/// Redesigned monthly summary dashboard card replicating the exact HTML template
/// and sample screen (`media_1793960809906_662bf308.jpg`).
///
/// Layout:
/// 1. Hero gradient card with net income, warning pill when deductions exceed earnings,
///    glass container with earnings/deductions breakdown, and dual-tone ratio bar.
/// 2. "Attendance" 2-column card for Present and Replacement days.
/// 3. "Performance" 3-column card for Distance run, Extra trips, and Extra tips.
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

    final currencySymbol = AppFormatters.formatCurrency(0, locale).replaceAll(RegExp(r'[\d\s,.]'), '');
    final isNegative = summary.netIncome < 0;
    final absNet = summary.netIncome.abs();
    final netAmountStr = isNegative
        ? '−${AppFormatters.formatNumber(absNet, locale)}'
        : AppFormatters.formatNumber(summary.netIncome, locale);

    // Negative net income reads red, positive reads green; both are bright
    // enough to stay clearly legible on the navy hero gradient.
    final netAmountColor = isNegative
        ? AppColors.netIncomeNegativeOnHero
        : (summary.netIncome > 0 ? AppColors.netIncomePositiveOnHero : Colors.white);

    final hasEarnings = summary.grossIncome > 0;
    final hasDeductions = summary.totalDeductions > 0;
    final earningsFlex = math.max(1, summary.grossIncome);
    final deductionsFlex = math.max(1, summary.totalDeductions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // -------------------------------------------------------------
        // 1. HERO NET INCOME CARD
        // -------------------------------------------------------------
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.heroNavyStart,
                AppColors.heroNavyMid,
                AppColors.heroNavyEnd,
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x662B33B8),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                // Concentric circles watermark in top right
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ConcentricCirclesPainter(),
                  ),
                ),

                // Hero content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row (Net Income title + Warning Pill if deductions exceed earnings)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    l10n.summary_netIncome,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                                if (isLoading) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isNegative)
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.coral,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    l10n.summary_deductions_exceed,
                                    style: const TextStyle(
                                      fontFamily: 'Mukta',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.coralInk,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Large Net Income Amount
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$currencySymbol ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: netAmountColor.withValues(alpha: 0.85),
                              ),
                            ),
                            Text(
                              netAmountStr,
                              style: TextStyle(
                                fontFamily: 'Mukta',
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.0,
                                color: netAmountColor,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Formula subtitle
                      Text(
                        l10n.summary_netIncomeFormula,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Glass Container (Earnings vs Deductions Breakdown)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Earnings Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.summary_earnings,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.white.withValues(alpha: 0.75),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        AppFormatters.formatCurrency(summary.grossIncome, locale),
                                        style: const TextStyle(
                                          fontFamily: 'Mukta',
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Vertical Divider
                                Container(
                                  width: 1,
                                  height: 38,
                                  color: Colors.white.withValues(alpha: 0.2),
                                  margin: const EdgeInsets.symmetric(horizontal: 14),
                                ),

                                // Deductions Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.summary_deductions,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.white.withValues(alpha: 0.75),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        AppFormatters.formatCurrency(summary.totalDeductions, locale),
                                        style: const TextStyle(
                                          fontFamily: 'Mukta',
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.coral,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Ratio Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: SizedBox(
                                height: 6,
                                child: (hasEarnings || hasDeductions)
                                    ? Row(
                                        children: [
                                          Expanded(
                                            flex: earningsFlex,
                                            child: Container(color: AppColors.mintGreen),
                                          ),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            flex: deductionsFlex,
                                            child: Container(color: AppColors.coral),
                                          ),
                                        ],
                                      )
                                    : Container(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // -------------------------------------------------------------
        // 2. ATTENDANCE SECTION (2 Columns)
        // -------------------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
          child: Text(
            l10n.summary_sec_attendance,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6F7594),
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE7E9F4), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1414173A),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Present Days Tile
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 22,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              AppFormatters.formatNumber(summary.totalPresentDays, locale),
                              style: const TextStyle(
                                fontFamily: 'Mukta',
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF14173A),
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.summary_unit_days,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6F7594),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          l10n.summary_present_label,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6F7594),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Vertical Divider
                Container(width: 1, color: const Color(0xFFE7E9F4)),

                // Replacement Days Tile
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.swap_horiz_rounded,
                          size: 22,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              AppFormatters.formatNumber(summary.totalReplacementDays, locale),
                              style: const TextStyle(
                                fontFamily: 'Mukta',
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF14173A),
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.summary_unit_days,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6F7594),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          l10n.summary_replacement_label,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6F7594),
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

        // -------------------------------------------------------------
        // 3. PERFORMANCE SECTION (3 Columns)
        // -------------------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
          child: Text(
            l10n.summary_sec_performance,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6F7594),
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE7E9F4), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1414173A),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Total Distance Run Tile
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.speed_rounded,
                          size: 22,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        // Scales down rather than overflowing on narrow screens
                        // (e.g. 3-digit readings with the Nepali km unit at 360dp).
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                AppFormatters.formatNumber(summary.totalKm, locale),
                                style: const TextStyle(
                                  fontFamily: 'Mukta',
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF14173A),
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                l10n.common_unit_km,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6F7594),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          l10n.summary_distance_run,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6F7594),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Vertical Divider
                Container(width: 1, color: const Color(0xFFE7E9F4)),

                // Extra Trips Tile
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.alt_route_rounded,
                          size: 22,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppFormatters.formatNumber(summary.totalExtraIncome, locale),
                          style: const TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF14173A),
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          l10n.summary_extraTrips,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6F7594),
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
      ],
    );
  }
}

/// Custom painter rendering subtle concentric circles in the hero card top right.
class _ConcentricCirclesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width + 30, -30);
    for (double r = 22.0; r <= 240.0; r += 22.0) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
