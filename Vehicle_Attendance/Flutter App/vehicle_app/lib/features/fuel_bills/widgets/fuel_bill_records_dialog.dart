import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../../l10n/app_localizations.dart';
import '../controllers/fuel_bills_controller.dart';
import '../models/fuel_bill.dart';
import 'generate_fuel_bill_dialog.dart';

/// Modal dialog displaying historical fuel bill records and providing
/// an interactive trigger for updating the cutoff date and generating new bills.
/// Fully localized with strict single-language rendering.
class FuelBillRecordsDialog extends ConsumerStatefulWidget {
  const FuelBillRecordsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const FuelBillRecordsDialog(),
    );
  }

  @override
  ConsumerState<FuelBillRecordsDialog> createState() =>
      _FuelBillRecordsDialogState();
}

class _FuelBillRecordsDialogState
    extends ConsumerState<FuelBillRecordsDialog> {
  bool _isEditingDate = false;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(String currentDateStr) async {
    DateTime initial = DateTime.now();
    try {
      initial = NepalClock.parseDate(currentDateStr);
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = NepalClock.formatDate(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final fuelBillsState = ref.watch(fuelBillsControllerProvider);
    final controller = ref.read(fuelBillsControllerProvider.notifier);

    final bills = fuelBillsState.bills;
    final lastBillDate = fuelBillsState.lastBillDate ??
        (bills.isNotEmpty ? bills.first.endDate : '2026-01-15');

    if (!_isEditingDate) {
      _dateController.text = lastBillDate;
    }

    // Format date as MM/DD/YYYY for clean display
    String displayDate = lastBillDate;
    try {
      final dt = NepalClock.parseDate(lastBillDate);
      final mm = dt.month.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      final yyyy = dt.year.toString();
      displayDate = '$mm/$dd/$yyyy';
    } catch (_) {}

    final localizedDisplayDate = locale.languageCode == 'ne'
        ? AppFormatters.toDevanagariDigits(displayDate)
        : displayDate;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: screenHeight * 0.85,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Title Row ──────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.missingKmBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_gas_station_rounded,
                          color: AppColors.replacement,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.fuel_records_dialog_title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('fuel_bill_dialog_close'),
                        icon: const Icon(Icons.close_rounded, size: 24),
                        color: AppColors.textMuted,
                        onPressed: () => Navigator.pop(context),
                        tooltip: l10n.common_close,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Scrollable Body ────────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Block 1: Last Fuel Bill End Date
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.replacementBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('🗓️',
                                        style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l10n.fuel_records_dialog_lastEndedTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.fuel_records_dialog_lastEndedHint,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                if (!_isEditingDate) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: AppColors.border,
                                            ),
                                          ),
                                          child: Text(
                                            localizedDisplayDate,
                                            key: const Key(
                                                'fuel_bill_dialog_display_date'),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        key: const Key(
                                            'fuel_bill_dialog_edit_date_btn'),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: AppColors.surface,
                                          foregroundColor:
                                              AppColors.replacement,
                                          side: const BorderSide(
                                            color: AppColors.border,
                                            width: 1.2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 8),
                                        ),
                                        icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 14),
                                        label: Text(
                                          l10n.fuel_records_dialog_editDateButton,
                                          style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: fuelBillsState.isSaving
                                            ? null
                                            : () => setState(
                                                () => _isEditingDate = true),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () =>
                                              _pickDate(lastBillDate),
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10),
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color:
                                                      AppColors.replacement),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _dateController.text,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: AppColors
                                                          .textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                const Icon(
                                                    Icons
                                                        .calendar_month_rounded,
                                                    size: 18,
                                                    color:
                                                        AppColors.replacement),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        key: const Key(
                                            'fuel_bill_dialog_save_date_btn'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.replacement,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          visualDensity:
                                              VisualDensity.compact,
                                        ),
                                        onPressed: fuelBillsState.isSaving
                                            ? null
                                            : () async {
                                                await controller
                                                    .updateLastBillDate(
                                                        _dateController.text);
                                                if (mounted) {
                                                  setState(() =>
                                                      _isEditingDate = false);
                                                }
                                              },
                                        child: Text(l10n.common_save,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 6),
                                      TextButton(
                                        key: const Key(
                                            'fuel_bill_dialog_cancel_date_btn'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.textMuted,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 8),
                                          visualDensity:
                                              VisualDensity.compact,
                                        ),
                                        onPressed: () => setState(
                                            () => _isEditingDate = false),
                                        child: Text(l10n.common_cancel,
                                            style: const TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Block 2: Generate Fuel Bill Button
                          ElevatedButton.icon(
                            key: const Key('dialog_generate_fuel_bill_button'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.replacement,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 20),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                l10n.fuel_records_dialog_generateBillButton,
                                style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            onPressed: () =>
                                GenerateFuelBillDialog.show(context),
                          ),
                          const SizedBox(height: 16),

                          // Block 3: Bill History
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.fuel_records_dialog_historyTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (bills.isNotEmpty)
                                Text(
                                  l10n.fuel_records_dialog_recordsCount(bills.length),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (fuelBillsState.isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            )
                          else if (bills.isEmpty)
                            Container(
                              key: const Key('fuel_bills_empty_state'),
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.receipt_long_rounded,
                                    size: 32,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.fuel_records_dialog_emptyState,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            // Responsive card list
                            Column(
                              children: bills.asMap().entries.map((entry) {
                                final i = entry.key;
                                final bill = entry.value;
                                return _BillRecordCard(
                                  bill: bill,
                                  locale: locale,
                                  l10n: l10n,
                                  isLast: i == bills.length - 1,
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bill record card ──────────────────────────────────────────────────────────

/// A fully responsive card for one fuel bill record.
/// Shows period on one line, then KM / Expected L / Actual L as a chip row.
class _BillRecordCard extends StatelessWidget {
  const _BillRecordCard({
    required this.bill,
    required this.locale,
    required this.l10n,
    required this.isLast,
  });

  final FuelBill bill;
  final Locale locale;
  final AppLocalizations l10n;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final startFormatted = locale.languageCode == 'ne'
        ? AppFormatters.toDevanagariDigits(bill.startDate)
        : bill.startDate;
    final endFormatted = locale.languageCode == 'ne'
        ? AppFormatters.toDevanagariDigits(bill.endDate)
        : bill.endDate;

    final kmFormatted = AppFormatters.formatUnit(bill.totalKm, 'km', locale);
    final expectedFormatted = AppFormatters.formatUnit(bill.expectedLiters, 'L', locale);
    final actualFormatted = bill.actualLiters != null
        ? AppFormatters.formatUnit(bill.actualLiters!, 'L', locale)
        : '—';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: AppColors.divider),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period label (Uses standard arrow for test parity)
          Text(
            '$startFormatted → $endFormatted',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Stat chips row
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _StatChip(
                label: l10n.fuel_records_col_totalKm,
                value: kmFormatted,
                valueColor: AppColors.primary,
              ),
              _StatChip(
                label: l10n.fuel_records_col_expectedLiters,
                value: expectedFormatted,
                valueColor: AppColors.primary,
              ),
              _StatChip(
                label: l10n.fuel_records_col_actualLiters,
                value: actualFormatted,
                valueColor: bill.actualLiters != null
                    ? AppColors.present
                    : AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
