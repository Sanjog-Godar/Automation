import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nepali_calendar_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../fuel_bills/controllers/fuel_bills_controller.dart';
import '../../fuel_bills/widgets/fuel_bill_records_tile.dart';
import '../../reports/widgets/quick_actions_card.dart';
import '../controllers/attendance_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/extra_trip_dialog.dart';
import '../widgets/km_bottom_sheet.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/tip_bottom_sheet.dart';

/// Redesigned, airy main attendance, fuel billing, and earnings dashboard screen.
/// Fully localized, supporting navigation drawer with instant language switching.
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final attendanceState = ref.watch(attendanceControllerProvider);
    final controller = ref.read(attendanceControllerProvider.notifier);

    final bsYear = attendanceState.currentYear;
    final bsMonthIndex = attendanceState.currentMonthIndex;

    final monthName = AppFormatters.bsMonthName(bsMonthIndex, locale);
    final yearStr = AppFormatters.formatNumber(bsYear, locale);
    final rawSubtitle = NepaliCalendarHelper.getEnglishMonthSubtitle(bsYear, bsMonthIndex);
    final localizedSubtitle = AppFormatters.formatAdMonthSpan(rawSubtitle, locale);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            key: const Key('dashboard_drawer_button'),
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
            tooltip: l10n.dashboard_drawer_title,
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_bus_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    AppConstants.vehicleNumber,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '$monthName $yearStr ($localizedSubtitle)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            key: const Key('dashboard_sign_out_button'),
            tooltip: l10n.dashboard_drawer_nav_signOut,
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(l10n.dashboard_signOut_dialogTitle),
                  content: Text(l10n.dashboard_signOut_dialogMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.common_cancel),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.dashboard_signOut_dialogTitle),
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
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Monthly Summary Card (Hero Metrics)
                    MonthlySummaryCard(
                      summary: attendanceState.summary,
                      isLoading: attendanceState.isLoading,
                    ),
                    const SizedBox(height: 14),

                    // Calendar Grid (Single-source view, integrated navigation & today chip)
                    CalendarGrid(
                      bsYear: bsYear,
                      bsMonthIndex: bsMonthIndex,
                      logs: attendanceState.logs,
                      savingDates: attendanceState.savingDates,
                      onPreviousMonth: attendanceState.isLoading ? () {} : () => controller.previousMonth(),
                      onNextMonth: attendanceState.isLoading ? () {} : () => controller.nextMonth(),
                      onToday: () {
                        final current = NepaliCalendarHelper.getCurrentNepaliYearMonth();
                        if (current.year != bsYear || current.monthIndex != bsMonthIndex) {
                          controller.loadMonth(current.year, current.monthIndex);
                        }
                      },
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
                      onFutureDateTap: (logDate) {
                        ref.read(toastServiceProvider).showError(
                          l10n.toast_futureDateError,
                          nepaliMessage: l10n.toast_futureDateError,
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fuel Bill Records Button Tile (Tapping opens Modal Dialog)
                    const FuelBillRecordsTile(),
                    const SizedBox(height: 16),

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
