import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../../core/utils/nepali_calendar_helper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../fuel_bills/controllers/fuel_bills_controller.dart';
import '../../fuel_bills/widgets/fuel_bill_records_card.dart';
import '../../reports/widgets/quick_actions_card.dart';
import '../controllers/attendance_controller.dart';
import '../models/attendance_log.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/daily_list_view.dart';
import '../widgets/extra_trip_dialog.dart';
import '../widgets/km_bottom_sheet.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/tip_bottom_sheet.dart';

enum AttendanceViewMode {
  list,
  grid,
}

enum AttendanceFilter {
  all,
  missingData,
  presentOnly,
}

/// Responsive, modern main attendance, fuel billing, and earnings dashboard screen.
/// Offers both adaptive 7-column Calendar Grid view and mobile-optimized Daily List view,
/// alongside full Fuel Bill Records and Quick Action PDF settlement downloads.
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  AttendanceViewMode _viewMode = AttendanceViewMode.list;
  AttendanceFilter _filter = AttendanceFilter.all;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final state = ref.read(attendanceControllerProvider);
      if (state.logs.isEmpty) {
        ref.read(attendanceControllerProvider.notifier).loadMonth(
              state.currentYear,
              state.currentMonthIndex,
            );
      }
      ref.read(fuelBillsControllerProvider.notifier).load();
    });
  }

  List<AttendanceLog> _getFilteredLogs(List<AttendanceLog> logs) {
    switch (_filter) {
      case AttendanceFilter.missingData:
        return logs.where((log) {
          final isPast = NepalClock.isPast(log.logDate);
          return isPast &&
              (log.isUnselected ||
                  (log.status == AttendanceStatus.present &&
                      (log.kmTotal == null || log.kmTotal! <= 0)));
        }).toList();
      case AttendanceFilter.presentOnly:
        return logs
            .where((log) => !log.isUnselected && log.status == AttendanceStatus.present)
            .toList();
      case AttendanceFilter.all:
        return logs;
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceControllerProvider);
    final controller = ref.read(attendanceControllerProvider.notifier);

    final bsYear = attendanceState.currentYear;
    final bsMonthIndex = attendanceState.currentMonthIndex;

    final monthNameDevanagari = NepaliCalendarHelper.nepaliMonths[bsMonthIndex];
    final yearDevanagari = NepaliCalendarHelper.toNepaliNumber(bsYear);
    final englishSubtitle = NepaliCalendarHelper.getEnglishMonthSubtitle(bsYear, bsMonthIndex);

    final filteredLogs = _getFilteredLogs(attendanceState.logs);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // soft slate-50
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_bus_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  AppConstants.vehicleNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            Text(
              '$monthNameDevanagari $yearDevanagari ($englishSubtitle)',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out of the vehicle attendance system?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(authControllerProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final double horizontalPadding = isWide ? 24 : 12;

            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  controller.loadMonth(bsYear, bsMonthIndex),
                  ref.read(fuelBillsControllerProvider.notifier).load(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Month Navigation Header Card (Sleek, Accessible with Previous / Next)
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Previous Month Button (Contains 'Previous' text)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                foregroundColor: const Color(0xFF334155),
                              ),
                              onPressed: attendanceState.isLoading
                                  ? null
                                  : () => controller.previousMonth(),
                              icon: const Icon(Icons.chevron_left_rounded, size: 18),
                              label: const Text('Previous', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),

                            // Month Name Display
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '$monthNameDevanagari $yearDevanagari',
                                    style: const TextStyle(
                                      fontFamily: 'Mukta',
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                      height: 1.1,
                                    ),
                                  ),
                                  Text(
                                    englishSubtitle,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Next Month Button (Contains 'Next' text)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                foregroundColor: const Color(0xFF334155),
                              ),
                              onPressed: attendanceState.isLoading
                                  ? null
                                  : () => controller.nextMonth(),
                              label: const Text('Next', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              icon: const Icon(Icons.chevron_right_rounded, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Monthly Summary Card
                    MonthlySummaryCard(
                      summary: attendanceState.summary,
                      isLoading: attendanceState.isLoading,
                    ),
                    const SizedBox(height: 10),

                    // Controls Row: View Switcher (List vs Calendar) & Jump to Today
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // View Switcher (List vs Grid)
                        SegmentedButton<AttendanceViewMode>(
                          segments: const [
                            ButtonSegment(
                              value: AttendanceViewMode.list,
                              icon: Icon(Icons.view_agenda_rounded, size: 15),
                              label: Text('List', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            ButtonSegment(
                              value: AttendanceViewMode.grid,
                              icon: Icon(Icons.grid_view_rounded, size: 15),
                              label: Text('Grid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                          selected: {_viewMode},
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _viewMode = newSelection.first;
                            });
                          },
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            selectedBackgroundColor: AppColors.primary,
                            selectedForegroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),

                        // Jump to Today button
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.today_rounded, size: 16),
                          label: const Text('Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            final current = NepaliCalendarHelper.getCurrentNepaliYearMonth();
                            if (current.year != bsYear || current.monthIndex != bsMonthIndex) {
                              controller.loadMonth(current.year, current.monthIndex);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Filter Chips Row (All, Missing Data, Present)
                    if (_viewMode == AttendanceViewMode.list) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          FilterChip(
                            selected: _filter == AttendanceFilter.all,
                            label: Text('All (${attendanceState.logs.length})', style: const TextStyle(fontSize: 11)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(
                              color: _filter == AttendanceFilter.all ? AppColors.primary : const Color(0xFFCBD5E1),
                            ),
                            onSelected: (_) => setState(() => _filter = AttendanceFilter.all),
                          ),
                          FilterChip(
                            selected: _filter == AttendanceFilter.missingData,
                            label: const Text('⚠️ Needs Attention', style: TextStyle(fontSize: 11)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            selectedColor: const Color(0xFFFEE2E2),
                            checkmarkColor: const Color(0xFFDC2626),
                            side: BorderSide(
                              color: _filter == AttendanceFilter.missingData ? const Color(0xFFF87171) : const Color(0xFFCBD5E1),
                            ),
                            labelStyle: TextStyle(
                              color: _filter == AttendanceFilter.missingData
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) => setState(() => _filter = AttendanceFilter.missingData),
                          ),
                          FilterChip(
                            selected: _filter == AttendanceFilter.presentOnly,
                            label: const Text('Present Only', style: TextStyle(fontSize: 11)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(
                              color: _filter == AttendanceFilter.presentOnly ? AppColors.present : const Color(0xFFCBD5E1),
                            ),
                            onSelected: (_) => setState(() => _filter = AttendanceFilter.presentOnly),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Main View Content: Daily List View OR Responsive Calendar Grid View
                    if (_viewMode == AttendanceViewMode.list)
                      DailyListView(
                        bsYear: bsYear,
                        bsMonthIndex: bsMonthIndex,
                        logs: filteredLogs,
                        savingDates: attendanceState.savingDates,
                        onStatusChange: (logDate, status) {
                          controller.changeStatus(logDate, status);
                        },
                        onOpenTip: (log) {
                          TipBottomSheet.show(
                            context: context,
                            log: log,
                            dateTitle: log.logDate,
                            onSave: (amount, note) =>
                                controller.updateTip(log.logDate, amount, note),
                          );
                        },
                        onOpenKm: (log) {
                          KmBottomSheet.show(
                            context: context,
                            log: log,
                            dateTitle: log.logDate,
                            onSave: (startKm, endKm) =>
                                controller.updateKm(log.logDate, startKm, endKm),
                          );
                        },
                        onOpenExtraTrip: (log) {
                          ExtraTripDialog.show(
                            context: context,
                            log: log,
                            dateTitle: log.logDate,
                            onSave: (amount) =>
                                controller.updateExtraTrip(log.logDate, amount),
                          );
                        },
                      )
                    else
                      CalendarGrid(
                        bsYear: bsYear,
                        bsMonthIndex: bsMonthIndex,
                        logs: attendanceState.logs,
                        savingDates: attendanceState.savingDates,
                        onStatusChange: (logDate, status) {
                          controller.changeStatus(logDate, status);
                        },
                        onOpenTip: (log) {
                          TipBottomSheet.show(
                            context: context,
                            log: log,
                            dateTitle: log.logDate,
                            onSave: (amount, note) =>
                                controller.updateTip(log.logDate, amount, note),
                          );
                        },
                        onOpenKm: (log) {
                          KmBottomSheet.show(
                            context: context,
                            log: log,
                            dateTitle: log.logDate,
                            onSave: (startKm, endKm) =>
                                controller.updateKm(log.logDate, startKm, endKm),
                          );
                        },
                        onOpenExtraTrip: (log) {
                          ExtraTripDialog.show(
                            context: context,
                            log: log,
                            dateTitle: log.logDate,
                            onSave: (amount) =>
                                controller.updateExtraTrip(log.logDate, amount),
                          );
                        },
                      ),
                    const SizedBox(height: 14),

                    // Fuel Bill Records Section (Matches Screenshot)
                    const FuelBillRecordsCard(),
                    const SizedBox(height: 14),

                    // Quick Actions Section (Generate Fuel Bill & Download Report)
                    const QuickActionsCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
