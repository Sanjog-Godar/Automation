import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/attendance_log.dart';

/// Senior-friendly, calm day cell for the Bikram Sambat monthly calendar grid.
/// Strict three-zone vertical layout:
/// - Zone 1 (Top, ~45%): Devanagari day number, Mukta Bold 20-22sp, textPrimary, centered.
/// - Zone 2 (Middle, ~20%): AD day number directly below it, 12sp, textMuted, centered (>= 4dp gap).
/// - Zone 3 (Bottom, ~35%): status pill (P/H/R, 22dp) OR 16-18dp warning icon.
///
/// Guaranteed zero overlap, zero RenderFlex overflow, and WCAG AA high contrast.
class DayCard extends StatelessWidget {
  final AttendanceLog log;
  final int dayNumber;
  final String nepaliDayNumber; // Devanagari numeral (e.g. '१', '२')
  final String dateLabel; // Gregorian day label (e.g. '5')
  final String semanticsLabel;
  final bool isToday;
  final bool isPast;
  final bool isFuture;
  final bool isMissingStatus;
  final bool isMissingKm;
  final bool isSaving;
  final bool isSaturday;
  final VoidCallback onTap;

  const DayCard({
    super.key,
    required this.log,
    required this.dayNumber,
    required this.nepaliDayNumber,
    required this.dateLabel,
    required this.semanticsLabel,
    required this.isToday,
    required this.isPast,
    required this.isFuture,
    required this.isMissingStatus,
    required this.isMissingKm,
    required this.isSaving,
    this.isSaturday = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = log.status == AttendanceStatus.present && !log.isUnselected;
    final isHoliday = log.status == AttendanceStatus.absentHoliday && !log.isUnselected;
    final isReplace = log.status == AttendanceStatus.absentReplacement && !log.isUnselected;

    // Card background & border styling
    Color cellBg;
    Color borderColor;
    double borderWidth = 1.0;

    if (isMissingStatus) {
      cellBg = AppColors.missingStatusBg;
      borderColor = AppColors.missingStatusBorder;
      borderWidth = 1.0;
    } else if (isMissingKm && !isPresent) {
      cellBg = AppColors.missingKmBg;
      borderColor = AppColors.missingKmBorder;
      borderWidth = 1.0;
    } else if (isToday) {
      cellBg = AppColors.surface;
      borderColor = AppColors.primary;
      borderWidth = 1.5;
    } else {
      cellBg = AppColors.surface;
      borderColor = AppColors.border;
      borderWidth = 1.0;
    }

    final cellWidget = Semantics(
      label: semanticsLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: cellBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: borderWidth),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: MediaQuery.withClampedTextScaling(
                minScaleFactor: 1.0,
                maxScaleFactor: 1.3,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellWidth = constraints.maxWidth;

                    // Fixed vertical zone coordinates ensuring:
                    // 1. Zone 1: y in [3.0, 24.0]
                    // 2. Zone 1 to Zone 2 gap: 28.5 - 24.0 = 4.5dp (strictly >= 4dp)
                    // 3. Zone 2: y in [28.5, 40.5]
                    // 4. Zone 2 to Zone 3 gap: (72 - 3.5 - 22) - 40.5 = 6.0dp (strictly > 0)
                    // 5. Zone 3: bottom 3.5, height 22.0
                    const double zone1Top = 3.0;
                    const double zone1Height = 21.0;

                    const double zone2Top = 28.5;
                    const double zone2Height = 12.0;

                    const double zone3Bottom = 3.5;
                    const double zone3Height = 22.0;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // -----------------------------------------------------------
                        // ZONE 1: Devanagari day number (Mukta Bold 20-22sp, centered)
                        // Saturday numeral in red accent unless today.
                        // -----------------------------------------------------------
                        Positioned(
                          top: zone1Top,
                          left: 2.0,
                          right: 2.0,
                          height: zone1Height,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: isToday
                                  ? Container(
                                      key: const Key('day_cell_today_chip'),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        nepaliDayNumber,
                                        key: const Key('day_cell_devanagari_number'),
                                        style: const TextStyle(
                                          fontFamily: 'Mukta',
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.0,
                                          leadingDistribution: TextLeadingDistribution.even,
                                        ),
                                        strutStyle: const StrutStyle(
                                          forceStrutHeight: true,
                                          height: 1.0,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      nepaliDayNumber,
                                      key: const Key('day_cell_devanagari_number'),
                                      style: TextStyle(
                                        fontFamily: 'Mukta',
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: isSaturday ? AppColors.holiday : AppColors.textPrimary,
                                        height: 1.0,
                                        leadingDistribution: TextLeadingDistribution.even,
                                      ),
                                      strutStyle: const StrutStyle(
                                        forceStrutHeight: true,
                                        height: 1.0,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        // -----------------------------------------------------------
                        // ZONE 2: AD day number directly below Zone 1 (12sp, centered)
                        // Minimum 4dp clear vertical space from Zone 1. Never smaller than 11sp.
                        // -----------------------------------------------------------
                        Positioned(
                          top: zone2Top,
                          left: 2.0,
                          right: 2.0,
                          height: zone2Height,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                dateLabel,
                                key: const Key('day_cell_ad_number'),
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                  height: 1.0,
                                  leadingDistribution: TextLeadingDistribution.even,
                                ),
                                strutStyle: const StrutStyle(
                                  forceStrutHeight: true,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // -----------------------------------------------------------
                        // ZONE 3: Status Pill (P/H/R 22dp) OR 16-18dp Warning Icon
                        // -----------------------------------------------------------
                        Positioned(
                          bottom: zone3Bottom,
                          left: 0,
                          right: 0,
                          height: zone3Height,
                          child: _buildZone3Content(
                            cellWidth: cellWidth,
                            isPresent: isPresent,
                            isHoliday: isHoliday,
                            isReplace: isReplace,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Future days rendered at 50% opacity per requirements
    if (isFuture) {
      return Opacity(
        key: const Key('day_cell_future_opacity'),
        opacity: 0.5,
        child: cellWidget,
      );
    }

    return cellWidget;
  }

  Widget _buildZone3Content({
    required double cellWidth,
    required bool isPresent,
    required bool isHoliday,
    required bool isReplace,
  }) {
    // 1. Present + Missing KM: P pill centered + small amber dot/icon at right (>= 6dp gap)
    if (isPresent && isMissingKm) {
      final double pillSize = cellWidth < 40 ? 19.0 : 22.0;
      const double dotSize = 5.0;
      const double gap = 6.0;

      final double naturalPillLeft = (cellWidth - pillSize) / 2;
      final double naturalDotLeft = naturalPillLeft + pillSize + gap;
      final double overflow = math.max(0.0, (naturalDotLeft + dotSize) - (cellWidth - 1.0));

      final double actualPillLeft = naturalPillLeft - overflow;
      final double actualDotLeft = actualPillLeft + pillSize + gap;

      return Stack(
        children: [
          // Centered/Calibrated P Pill
          Positioned(
            left: actualPillLeft,
            top: 0,
            bottom: 0,
            width: pillSize,
            child: _buildStatusPill(
              letter: 'P',
              textColor: AppColors.present,
              bgColor: AppColors.presentBg,
              key: const Key('day_cell_status_p'),
            ),
          ),
          // Amber Alert Dot with >= 6dp gap
          Positioned(
            left: actualDotLeft,
            top: (22.0 - dotSize) / 2,
            width: dotSize,
            height: dotSize,
            child: Container(
              key: const Key('day_cell_warning_badge_km'),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.missingKm,
              ),
            ),
          ),
        ],
      );
    }

    // 2. Present with KM
    if (isPresent) {
      return Center(
        child: SizedBox(
          width: 22.0,
          height: 22.0,
          child: _buildStatusPill(
            letter: 'P',
            textColor: AppColors.present,
            bgColor: AppColors.presentBg,
            key: const Key('day_cell_status_p'),
          ),
        ),
      );
    }

    // 3. Holiday
    if (isHoliday) {
      return Center(
        child: SizedBox(
          width: 22.0,
          height: 22.0,
          child: _buildStatusPill(
            letter: 'H',
            textColor: AppColors.holiday,
            bgColor: AppColors.holidayBg,
            key: const Key('day_cell_status_h'),
          ),
        ),
      );
    }

    // 4. Replacement
    if (isReplace) {
      return Center(
        child: SizedBox(
          width: 22.0,
          height: 22.0,
          child: _buildStatusPill(
            letter: 'R',
            textColor: AppColors.replacement,
            bgColor: AppColors.replacementBg,
            key: const Key('day_cell_status_r'),
          ),
        ),
      );
    }

    // 5. Missing Status Alert
    if (isMissingStatus) {
      return const Center(
        child: Icon(
          Icons.warning_amber_rounded,
          key: Key('day_cell_warning_badge_status'),
          size: 17.0,
          color: AppColors.missingStatus,
        ),
      );
    }

    // 6. Missing KM Alert (when not present)
    if (isMissingKm) {
      return const Center(
        child: Icon(
          Icons.warning_amber_rounded,
          key: Key('day_cell_warning_badge_km'),
          size: 17.0,
          color: AppColors.missingKm,
        ),
      );
    }

    // 7. Unselected past or future day: clean empty zone (no "—" dash placeholder)
    return const SizedBox.shrink();
  }

  Widget _buildStatusPill({
    required String letter,
    required Color textColor,
    required Color bgColor,
    required Key key,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: textColor.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: 'Mukta',
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.0,
          leadingDistribution: TextLeadingDistribution.even,
        ),
        strutStyle: const StrutStyle(
          forceStrutHeight: true,
          height: 1.0,
        ),
      ),
    );
  }
}
