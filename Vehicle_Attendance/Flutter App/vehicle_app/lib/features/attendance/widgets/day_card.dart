import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/attendance_log.dart';

/// Clean, airy calendar day card matching `Kartik 2083 calendar.html`.
///
/// Features:
/// - Rounded surfaces (`borderRadius: 14px`)
/// - Soft pastel tints (`#fdeeeb` alert, `#e3f5ec` present, `#fdecec` holiday, `#fff0e5` replace)
/// - Transparent borders & backgrounds on free/future days
/// - Vibrant solid accent card (`#3B44D1`) for Today with white numbers and soft glow shadow
/// - BS numeral centered with AD numeral directly below it
/// - Bottom indicator: 16dp warning triangle icon OR 16dp status badge (P/H/R)
/// - Strict three-zone layout ensuring zero overlap and WCAG AA contrast
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

    // Card background & border styling matching Kartik 2083 calendar.html
    Color cellBg;
    Color borderColor;
    List<BoxShadow> boxShadow = const [];

    if (isToday) {
      cellBg = AppColors.primary;
      borderColor = AppColors.primary;
      boxShadow = const [
        BoxShadow(
          color: Color(0x4D3B44D1),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ];
    } else if (isMissingStatus) {
      cellBg = AppColors.alertSoft;     // #fdeeeb
      borderColor = AppColors.alertBorder; // #f2c4bc
    } else if (isPresent) {
      cellBg = AppColors.eventSoft;     // #e3f5ec
      borderColor = AppColors.eventBorder; // #a9dcc3
    } else if (isHoliday) {
      cellBg = AppColors.holidayBg;
      borderColor = AppColors.holidayBorder;
    } else if (isReplace) {
      cellBg = AppColors.replacementBg;
      borderColor = AppColors.replacementBorder;
    } else if (isMissingKm) {
      cellBg = AppColors.missingKmBg;
      borderColor = AppColors.missingKmBorder;
    } else {
      // Normal free / future day: clean transparent background and border
      cellBg = Colors.transparent;
      borderColor = Colors.transparent;
    }

    final hasBottomIndicator = isMissingStatus || isMissingKm || isPresent || isHoliday || isReplace;

    final cellWidget = Semantics(
      label: semanticsLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            key: isToday ? const Key('day_cell_today_chip') : null,
            decoration: BoxDecoration(
              color: cellBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: boxShadow,
            ),
            child: MediaQuery.withClampedTextScaling(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.3,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellWidth = constraints.maxWidth;
                  final cellHeight = constraints.maxHeight;

                  // Vertical zone coordinates matching non-overlap assertions:
                  // Zone 1 (BS number): y in [4.0, 26.0], height: 22.0
                  // Zone 1 to Zone 2 gap: 30.0 - 26.0 = 4.0dp (strictly >= 4dp)
                  // Zone 2 (AD number): y in [30.0, 43.0], height: 13.0
                  // Zone 3 (Bottom indicator): bottom: 5.5, height: 17.0
                  const double zone1Top = 4.0;
                  const double zone1Height = 22.0;

                  const double zone2Top = 30.0;
                  const double zone2Height = 13.0;

                  const double zone3Bottom = 5.5;
                  const double zone3Height = 17.0;

                  // BS Number styling
                  final Color bsColor;
                  if (isToday) {
                    bsColor = Colors.white;
                  } else if (isSaturday) {
                    bsColor = AppColors.alert;
                  } else {
                    bsColor = AppColors.textPrimary;
                  }

                  // AD Number styling
                  final Color adColor;
                  if (isToday) {
                    adColor = Colors.white.withValues(alpha: 0.9);
                  } else if (isSaturday) {
                    adColor = AppColors.alert;
                  } else {
                    adColor = AppColors.textMuted;
                  }

                  // If no bottom indicator, center BS and AD together
                  final double actualZone1Top;
                  final double actualZone2Top;
                  if (hasBottomIndicator) {
                    actualZone1Top = zone1Top;
                    actualZone2Top = zone2Top;
                  } else {
                    // Centered vertically when no bottom badge
                    final contentHeight = zone1Height + 4.0 + zone2Height;
                    actualZone1Top = math.max(zone1Top, (cellHeight - contentHeight) / 2);
                    actualZone2Top = actualZone1Top + zone1Height + 4.0;
                  }

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // -----------------------------------------------------------
                      // ZONE 1: BS Day Number (Mukta Bold 19-22sp, centered)
                      // Saturday numeral in red accent unless today.
                      // -----------------------------------------------------------
                      Positioned(
                        top: actualZone1Top,
                        left: 2.0,
                        right: 2.0,
                        height: zone1Height,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              nepaliDayNumber,
                              key: const Key('day_cell_devanagari_number'),
                              style: TextStyle(
                                fontFamily: 'Mukta',
                                fontSize: isToday ? 21.0 : 19.0,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                                color: bsColor,
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
                      // ZONE 2: AD Day Number directly below Zone 1 (11sp, centered)
                      // Strictly >= 4dp clear vertical gap from Zone 1.
                      // -----------------------------------------------------------
                      Positioned(
                        top: actualZone2Top,
                        left: 2.0,
                        right: 2.0,
                        height: zone2Height,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              dateLabel,
                              key: const Key('day_cell_ad_number'),
                              style: TextStyle(
                                fontSize: isToday ? 11.0 : 10.5,
                                fontWeight: FontWeight.w500,
                                color: adColor,
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
                      // ZONE 3: Status Badge (P/H/R) OR Warning Triangle Icon
                      // -----------------------------------------------------------
                      if (hasBottomIndicator)
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
    );

    // Future days rendered at 50% opacity
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
    // 1. Present + Missing KM: P badge with amber warning dot at right
    if (isPresent && isMissingKm) {
      final double badgeWidth = cellWidth < 40 ? 18.0 : 22.0;
      const double dotSize = 5.0;
      const double gap = 6.0;

      final double naturalLeft = (cellWidth - badgeWidth) / 2;
      final double naturalDotLeft = naturalLeft + badgeWidth + gap;
      final double overflow = math.max(0.0, (naturalDotLeft + dotSize) - (cellWidth - 1.0));

      final double actualLeft = naturalLeft - overflow;
      final double actualDotLeft = actualLeft + badgeWidth + gap;

      return Stack(
        children: [
          Positioned(
            left: actualLeft,
            top: 0,
            bottom: 0,
            width: badgeWidth,
            child: _buildBadge(
              letter: 'P',
              bgColor: isToday ? Colors.white : AppColors.event,
              textColor: isToday ? AppColors.event : Colors.white,
              key: const Key('day_cell_status_p'),
            ),
          ),
          Positioned(
            left: actualDotLeft,
            top: (17.0 - dotSize) / 2,
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
        child: _buildBadge(
          letter: 'P',
          bgColor: isToday ? Colors.white : AppColors.event,
          textColor: isToday ? AppColors.event : Colors.white,
          key: const Key('day_cell_status_p'),
        ),
      );
    }

    // 3. Holiday
    if (isHoliday) {
      return Center(
        child: _buildBadge(
          letter: 'H',
          bgColor: isToday ? Colors.white : AppColors.holiday,
          textColor: isToday ? AppColors.holiday : Colors.white,
          key: const Key('day_cell_status_h'),
        ),
      );
    }

    // 4. Replacement
    if (isReplace) {
      return Center(
        child: _buildBadge(
          letter: 'R',
          bgColor: isToday ? Colors.white : AppColors.replacement,
          textColor: isToday ? AppColors.replacement : Colors.white,
          key: const Key('day_cell_status_r'),
        ),
      );
    }

    // 5. Missing Status Alert (outline triangle with exclamation)
    if (isMissingStatus) {
      return Center(
        child: Icon(
          Icons.warning_amber_rounded,
          key: const Key('day_cell_warning_badge_status'),
          size: 16.0,
          color: isToday ? Colors.white : AppColors.alert,
        ),
      );
    }

    // 6. Missing KM Alert (when not present)
    if (isMissingKm) {
      return Center(
        child: Icon(
          Icons.warning_amber_rounded,
          key: const Key('day_cell_warning_badge_km'),
          size: 16.0,
          color: isToday ? Colors.white : AppColors.missingKm,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBadge({
    required String letter,
    required Color bgColor,
    required Color textColor,
    required Key key,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: 'Mukta',
          fontSize: 10.5,
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
