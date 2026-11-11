import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/l10n/locale_provider.dart';
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
import '../widgets/monthly_running_summary_table.dart';
import '../widgets/monthly_summary_card.dart';

/// Redesigned, airy main attendance, fuel billing, and earnings dashboard screen.
/// Fully localized, supporting navigation drawer with instant language switching.
///
/// Content is split across a two-destination bottom navigation bar:
/// - Home: monthly summary (net income, attendance, performance) + fuel/report utilities.
/// - Calendar: the BS month attendance grid with navigation and day actions.
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  static const int _homeTab = 0;

  int _selectedTab = _homeTab;
  final ScrollController _scrollController = ScrollController();
  Locale? _lastLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.localeOf(context);
    if (_lastLocale != null && _lastLocale!.languageCode != currentLocale.languageCode) {
      _lastLocale = currentLocale;
      _refresh();
    } else {
      _lastLocale = currentLocale;
    }
  }

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
    // Each tab starts at its own top instead of inheriting the previous offset.
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  /// Reloads every API-backed section (attendance + fuel bills) for the month
  /// currently on screen. Used by pull-to-refresh and by language switches so
  /// the dashboard always reflects fresh server data.
  Future<void> _refresh() async {
    final state = ref.read(attendanceControllerProvider);
    await Future.wait([
      ref.read(attendanceControllerProvider.notifier).loadMonth(
            state.currentYear,
            state.currentMonthIndex,
          ),
      ref.read(fuelBillsControllerProvider.notifier).load(),
    ]);
  }

  /// Home tab: monthly summary hero metrics, attendance/performance sections,
  /// and the fuel bill + report utilities.
  Widget _buildHomeTab(AttendanceState attendanceState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Monthly Summary Card (Hero Metrics)
        MonthlySummaryCard(
          summary: attendanceState.summary,
          isLoading: attendanceState.isLoading,
        ),
        const SizedBox(height: 16),

        // Fuel Bill Records Button Tile (Tapping opens Modal Dialog)
        const FuelBillRecordsTile(),
        const SizedBox(height: 16),

        // Quick Actions Section (Generate Fuel Bill & Download Report)
        const QuickActionsCard(),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Calendar tab: the month grid with integrated navigation, today chip,
  /// and per-day actions.
  Widget _buildCalendarTab({
    required AttendanceState attendanceState,
    required AttendanceController controller,
    required int bsYear,
    required int bsMonthIndex,
    required AppLocalizations l10n,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        MonthlyRunningSummaryTable(
          bsYear: bsYear,
          bsMonthIndex: bsMonthIndex,
          logs: attendanceState.logs,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final attendanceState = ref.watch(attendanceControllerProvider);
    final controller = ref.read(attendanceControllerProvider.notifier);

    // Switching language must not leave stale/empty data on screen: refetch the
    // API into the new language immediately.
    ref.listen<Locale>(localeProvider, (previous, next) {
      if (previous?.languageCode == next.languageCode) return;
      _refresh();
    });

    final bsYear = attendanceState.currentYear;
    final bsMonthIndex = attendanceState.currentMonthIndex;

    final monthName = AppFormatters.bsMonthName(bsMonthIndex, locale);
    final yearStr = AppFormatters.formatYear(bsYear, locale);
    final rawSubtitle = NepaliCalendarHelper.getEnglishMonthSubtitle(bsYear, bsMonthIndex);
    final localizedSubtitle = AppFormatters.formatAdMonthSpan(rawSubtitle, locale);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        leadingWidth: 70,
        toolbarHeight: 66,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14, top: 11, bottom: 11),
          child: Builder(
            builder: (ctx) => InkWell(
              key: const Key('dashboard_drawer_button'),
              onTap: () => Scaffold.of(ctx).openDrawer(),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE7E9F4), width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D14173A),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 20),
              ),
            ),
          ),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppConstants.vehicleNumber,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Mukta',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 0.2,
                  color: AppColors.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '$monthName $yearStr · $localizedSubtitle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF6F7594),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14, top: 11, bottom: 11),
            child: InkWell(
              key: const Key('dashboard_sign_out_button'),
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
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
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE7E9F4), width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D14173A),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.logout_rounded, color: AppColors.textPrimary, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final double horizontalPadding = isWide ? 24 : 12;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
                child: _selectedTab == _homeTab
                    ? _buildHomeTab(attendanceState)
                    : _buildCalendarTab(
                        attendanceState: attendanceState,
                        controller: controller,
                        bsYear: bsYear,
                        bsMonthIndex: bsMonthIndex,
                        l10n: l10n,
                      ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _DashboardBottomNav(
          selectedIndex: _selectedTab,
          onSelect: _selectTab,
          homeLabel: l10n.dashboard_bottomNav_home,
          calendarLabel: l10n.dashboard_bottomNav_calendar,
        ),
      ),
    );
  }
}

/// Rounded two-destination navigation bar: Home (earnings dashboard) and
/// Calendar (attendance month grid).
class _DashboardBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String homeLabel;
  final String calendarLabel;

  const _DashboardBottomNav({
    required this.selectedIndex,
    required this.onSelect,
    required this.homeLabel,
    required this.calendarLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1414173A),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _BottomNavItem(
              key: const Key('bottom_nav_home'),
              icon: Icons.home_rounded,
              outlinedIcon: Icons.home_outlined,
              label: homeLabel,
              isSelected: selectedIndex == 0,
              onTap: () => onSelect(0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _BottomNavItem(
              key: const Key('bottom_nav_calendar'),
              icon: Icons.calendar_month_rounded,
              outlinedIcon: Icons.calendar_month_outlined,
              label: calendarLabel,
              isSelected: selectedIndex == 1,
              onTap: () => onSelect(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    super.key,
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isSelected ? icon : outlinedIcon, size: 20, color: color),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
