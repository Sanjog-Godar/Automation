import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../fuel_bills/widgets/fuel_bill_records_dialog.dart';
import '../../reports/services/pdf_report_service.dart';
import '../controllers/attendance_controller.dart';
import '../../fuel_bills/controllers/fuel_bills_controller.dart';

/// Navigation drawer presenting application identity, language switching,
/// navigation links, and safe logout with confirmation.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final activeLocale = ref.watch(localeProvider);
    final authState = ref.watch(authControllerProvider);
    final email = authState.user?.email ?? 'driver@vehicle.local';

    return Drawer(
      width: 304,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Drawer Header ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppConstants.vehicleNumber,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.dashboard_drawer_title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── 2. Scrollable Navigation & Language Content ───────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section: Language / भाषा (The single allowed bilingual label)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        l10n.common_language_selector_label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // English Language Tile
                    _LanguageTile(
                      key: const Key('drawer_language_en'),
                      label: l10n.common_english,
                      sublabel: 'English',
                      isSelected: activeLocale.languageCode == 'en',
                      onTap: () async {
                        await ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('en'));
                        await Future.delayed(const Duration(milliseconds: 180));
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 6),

                    // Nepali Language Tile
                    _LanguageTile(
                      key: const Key('drawer_language_ne'),
                      label: l10n.common_nepali,
                      sublabel: 'नेपाली',
                      isSelected: activeLocale.languageCode == 'ne',
                      onTap: () async {
                        await ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('ne'));
                        await Future.delayed(const Duration(milliseconds: 180));
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 18),

                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 14),

                    // Navigation Items
                    _DrawerNavItem(
                      key: const Key('drawer_nav_dashboard'),
                      icon: Icons.dashboard_rounded,
                      title: l10n.dashboard_drawer_nav_dashboard,
                      isSelected: true,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 4),

                    _DrawerNavItem(
                      key: const Key('drawer_nav_fuel_bills'),
                      icon: Icons.local_gas_station_rounded,
                      title: l10n.dashboard_drawer_nav_fuelBills,
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        FuelBillRecordsDialog.show(context);
                      },
                    ),
                    const SizedBox(height: 4),

                    _DrawerNavItem(
                      key: const Key('drawer_nav_download_report'),
                      icon: Icons.picture_as_pdf_rounded,
                      title: l10n.dashboard_drawer_nav_downloadReport,
                      isSelected: false,
                      onTap: () async {
                        final locale = ref.read(localeProvider);
                        Navigator.pop(context);
                        final attendanceState = ref.read(attendanceControllerProvider);
                        final fuelBills = ref.read(fuelBillsControllerProvider).bills;
                        await PdfReportService.generateAndDownloadReport(
                          bsYear: attendanceState.currentYear,
                          bsMonthIndex: attendanceState.currentMonthIndex,
                          fullMonthLogs: attendanceState.logs,
                          fuelBills: fuelBills,
                          locale: locale,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── 3. Drawer Footer: Sign Out & App Version ─────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton.icon(
                    key: const Key('drawer_sign_out_button'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: Text(
                      l10n.dashboard_drawer_nav_signOut,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
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
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'v1.0.0 • Mukta Font',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
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
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    super.key,
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              )
            else
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.background : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
