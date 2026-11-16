import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_utils/nepali_utils.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../../core/utils/nepali_calendar_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../controllers/attendance_controller.dart';
import '../models/attendance_log.dart';

/// Modal dialog displaying mid-month company payments / tip receipts.
/// Allows drivers to review early payments and record new payouts received before salary.
/// Automatically deducts from the company payout in the generated PDF report.
class CompanyPaymentsDialog extends ConsumerWidget {
  const CompanyPaymentsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const CompanyPaymentsDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final isNepali = locale.languageCode == 'ne';
    final state = ref.watch(attendanceControllerProvider);
    final controller = ref.read(attendanceControllerProvider.notifier);

    final receivedLogs = state.logs
        .where((l) => l.advanceAmount > 0)
        .toList()
      ..sort((a, b) => b.logDate.compareTo(a.logDate)); // Newest first

    final totalReceived = receivedLogs.fold<int>(0, (sum, l) => sum + l.advanceAmount);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF16A34A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.company_payments_dialog_title,
                      style: const TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    splashRadius: 20,
                    tooltip: l10n.common_close,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Total Summary Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.company_payments_dialog_totalCard,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        Text(
                          AppFormatters.formatCurrency(totalReceived, locale),
                          style: const TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.company_payments_dialog_subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // "+ Add Received Payment" Action Button
              ElevatedButton.icon(
                key: const Key('add_company_payment_button'),
                onPressed: () => _showPaymentEntryDialog(
                  context: context,
                  controller: controller,
                  allLogs: state.logs,
                  editingLog: null,
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  l10n.company_payments_add_button,
                  style: const TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 16),

              // Records List Header
              Text(
                isNepali ? 'प्राप्त भुक्तानी सूची' : 'Payment History',
                style: const TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Scrollable List or Empty State
              Flexible(
                child: receivedLogs.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 40,
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.company_payments_empty,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: receivedLogs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, index) {
                          final log = receivedLogs[index];
                          final adDate = NepalClock.parseDate(log.logDate);
                          final nepaliDate = adDate.toNepaliDateTime();
                          final bsMonth = AppFormatters.bsMonthName(nepaliDate.month - 1, locale);
                          final bsDay = isNepali
                              ? AppFormatters.toDevanagariDigits('${nepaliDate.day}')
                              : '${nepaliDate.day}';
                          final bsYear = isNepali
                              ? AppFormatters.toDevanagariDigits('${nepaliDate.year}')
                              : '${nepaliDate.year}';
                          final bsFormatted = '$bsMonth $bsDay, $bsYear';

                          final noteText = (log.advanceNote != null && log.advanceNote!.trim().isNotEmpty)
                              ? log.advanceNote!.trim()
                              : (isNepali ? 'कम्पनीबाट प्राप्त भुक्तानी' : 'Company Payment');

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$bsFormatted (${log.logDate})',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        noteText,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppFormatters.formatCurrency(log.advanceAmount, locale),
                                  style: const TextStyle(
                                    fontFamily: 'Mukta',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                  splashRadius: 18,
                                  tooltip: l10n.common_edit,
                                  onPressed: () => _showPaymentEntryDialog(
                                    context: context,
                                    controller: controller,
                                    allLogs: state.logs,
                                    editingLog: log,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                                  splashRadius: 18,
                                  tooltip: isNepali ? 'मेटाउनुहोस्' : 'Delete',
                                  onPressed: () => _confirmDelete(context, controller, log, l10n, isNepali),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AttendanceController controller,
    AttendanceLog log,
    AppLocalizations l10n,
    bool isNepali,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isNepali ? 'भुक्तानी मेटाउने' : 'Delete Payment'),
        content: Text(l10n.company_payments_delete_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              controller.updateAdvancePayment(
                logDate: log.logDate,
                amount: 0,
                note: null,
              );
            },
            child: Text(isNepali ? 'मेटाउनुहोस्' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _showPaymentEntryDialog({
    required BuildContext context,
    required AttendanceController controller,
    required List<AttendanceLog> allLogs,
    required AttendanceLog? editingLog,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _PaymentEntryDialog(
        controller: controller,
        allLogs: allLogs,
        editingLog: editingLog,
      ),
    );
  }
}

/// Inner form dialog to add or edit a mid-month received payment entry.
class _PaymentEntryDialog extends StatefulWidget {
  final AttendanceController controller;
  final List<AttendanceLog> allLogs;
  final AttendanceLog? editingLog;

  const _PaymentEntryDialog({
    required this.controller,
    required this.allLogs,
    this.editingLog,
  });

  @override
  State<_PaymentEntryDialog> createState() => _PaymentEntryDialogState();
}

class _PaymentEntryDialogState extends State<_PaymentEntryDialog> {
  late String _selectedDate;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    if (widget.editingLog != null) {
      _selectedDate = widget.editingLog!.logDate;
      _amountController = TextEditingController(text: widget.editingLog!.advanceAmount.toString());
      _noteController = TextEditingController(text: widget.editingLog!.advanceNote ?? '');
    } else {
      // Default to today if in range, otherwise first day of logs
      final todayStr = NepalClock.todayDateString();
      final hasToday = widget.allLogs.any((l) => l.logDate == todayStr);
      _selectedDate = hasToday
          ? todayStr
          : (widget.allLogs.isNotEmpty ? widget.allLogs.first.logDate : todayStr);
      _amountController = TextEditingController();
      _noteController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) return;

    final note = _noteController.text.trim();
    widget.controller.updateAdvancePayment(
      logDate: _selectedDate,
      amount: amount,
      note: note.isNotEmpty ? note : null,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final isNepali = locale.languageCode == 'ne';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l10n.company_payments_entry_title,
        style: const TextStyle(
          fontFamily: 'Mukta',
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: AppColors.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selector
            Text(
              l10n.company_payments_entry_date,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedDate,
                  items: widget.allLogs.map((log) {
                    final adDate = NepalClock.parseDate(log.logDate);
                    final nepaliDate = adDate.toNepaliDateTime();
                    final bsMonth = AppFormatters.bsMonthName(nepaliDate.month - 1, locale);
                    final bsDay = isNepali
                        ? AppFormatters.toDevanagariDigits('${nepaliDate.day}')
                        : '${nepaliDate.day}';
                    final label = '$bsMonth $bsDay (${log.logDate})';
                    return DropdownMenuItem<String>(
                      value: log.logDate,
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedDate = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Amount Field
            Text(
              l10n.company_payments_entry_amount,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.company_payments_entry_amount_hint,
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  width: 48,
                  child: Text(
                    isNepali ? 'रु.' : 'Rs.',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // Note Field
            Text(
              l10n.company_payments_entry_note,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: l10n.company_payments_entry_note_hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _handleSave,
          child: Text(l10n.common_save),
        ),
      ],
    );
  }
}
