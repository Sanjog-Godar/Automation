import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_utils/nepali_utils.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../../core/utils/nepali_calendar_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/settlements_controller.dart';
import '../models/monthly_settlement.dart';
import 'extra_trip_dialog.dart';

/// Modal dialog allowing the driver to record the actual salary deposited by the company into their bank.
/// Includes bilingual BS/AD calendar switcher, live deficit calculation, and arrears carry-forward.
class SalarySettlementDialog extends ConsumerStatefulWidget {
  const SalarySettlementDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const SalarySettlementDialog(),
    );
  }

  @override
  ConsumerState<SalarySettlementDialog> createState() => _SalarySettlementDialogState();
}

class _SalarySettlementDialogState extends ConsumerState<SalarySettlementDialog> {
  late final TextEditingController _actualController;
  late final TextEditingController _noteController;

  late DateTime _selectedAD;
  late NepaliDateTime _selectedBS;
  bool _isNepaliCalendar = true;

  @override
  void initState() {
    super.initState();
    final currentSettlement = ref.read(settlementsControllerProvider).currentSettlement;
    _actualController = TextEditingController(
      text: (currentSettlement != null && currentSettlement.bankReceivedAmount > 0)
          ? currentSettlement.bankReceivedAmount.toString()
          : '',
    );
    _noteController = TextEditingController(
      text: currentSettlement?.note ?? '',
    );

    final initialDateStr = currentSettlement?.paymentDate ?? NepalClock.todayDateString();
    try {
      _selectedAD = NepalClock.parseDate(initialDateStr);
    } catch (_) {
      _selectedAD = NepalClock.today();
    }
    _selectedBS = _selectedAD.toNepaliDateTime();
  }

  @override
  void dispose() {
    _actualController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Calculates expected receivable from the company for this month (post-TDS & early payments).
  int _calculateExpectedReceivable(AttendanceState state) {
    final summary = state.summary;
    final presentIncome = summary.totalPresentDays * AppConstants.dailyWage;
    final totalEarning = presentIncome - summary.totalDeductions;
    final tds = (totalEarning * AppConstants.tdsRate).round();

    int upayeTips = 0;
    int advanceReceived = 0;
    for (final log in state.logs) {
      if (log.isUnselected) continue;
      if (log.effectiveTipAmount > 0) {
        final parsed = ExtraTripDialog.parseUpayeNote(log.extraTipNote);
        if (parsed.isUpaye) {
          upayeTips += log.effectiveTipAmount;
        }
      }
      advanceReceived += log.advanceAmount;
    }

    final totalBeforeTds = totalEarning + upayeTips;
    final netAfterTds = totalBeforeTds - tds;
    return (netAfterTds - advanceReceived).clamp(0, 99999999);
  }

  Future<void> _pickEnglishDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedAD,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedAD = picked;
        _selectedBS = picked.toNepaliDateTime();
      });
    }
  }

  Future<void> _pickNepaliDate(BuildContext context, bool isNepaliAppLang) async {
    int tempYear = _selectedBS.year;
    int tempMonth = _selectedBS.month; // 1-12
    int tempDay = _selectedBS.day;

    final result = await showDialog<NepaliDateTime>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            final maxDays = NepaliCalendarHelper.getDaysInMonth(tempYear, tempMonth - 1);
            if (tempDay > maxDays) tempDay = maxDays;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isNepaliAppLang ? 'नेपाली मिति छान्नुहोस्' : 'Select Nepali Date',
                style: const TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Year Selector
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isNepaliAppLang ? 'साल (Year)' : 'Year',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  isExpanded: true,
                                  value: tempYear,
                                  items: [2080, 2081, 2082, 2083, 2084, 2085].map((y) {
                                    return DropdownMenuItem<int>(
                                      value: y,
                                      child: Text(
                                        isNepaliAppLang ? AppFormatters.toDevanagariDigits('$y') : '$y',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setPickerState(() => tempYear = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Month Selector
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isNepaliAppLang ? 'महिना (Month)' : 'Month',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  isExpanded: true,
                                  value: tempMonth,
                                  items: List.generate(12, (i) {
                                    final mIdx = i + 1;
                                    final name = isNepaliAppLang
                                        ? NepaliCalendarHelper.nepaliMonths[i]
                                        : NepaliCalendarHelper.nepaliMonthsEnglish[i];
                                    return DropdownMenuItem<int>(
                                      value: mIdx,
                                      child: Text(
                                        name,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setPickerState(() => tempMonth = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Day Selector
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isNepaliAppLang ? 'गते (Day)' : 'Day',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  isExpanded: true,
                                  value: tempDay,
                                  items: List.generate(maxDays, (i) {
                                    final dayNum = i + 1;
                                    return DropdownMenuItem<int>(
                                      value: dayNum,
                                      child: Text(
                                        isNepaliAppLang
                                            ? AppFormatters.toDevanagariDigits('$dayNum')
                                            : '$dayNum',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setPickerState(() => tempDay = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: Text(isNepaliAppLang ? 'रद्द गर्नुहोस्' : 'Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final picked = NepaliDateTime(tempYear, tempMonth, tempDay);
                    Navigator.pop(ctx, picked);
                  },
                  child: Text(isNepaliAppLang ? 'छान्नुहोस्' : 'Select'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final adEquivalent = NepaliCalendarHelper.toGregorian(
        result.year,
        result.month - 1,
        result.day,
      );
      setState(() {
        _selectedBS = result;
        _selectedAD = adEquivalent;
      });
    }
  }

  void _handleSave(int expectedAmount) {
    final actual = int.tryParse(_actualController.text.trim()) ?? 0;
    if (actual <= 0) return;

    final attendanceState = ref.read(attendanceControllerProvider);
    final dateStr = NepaliCalendarHelper.formatDate(_selectedAD);

    ref.read(settlementsControllerProvider.notifier).saveSettlement(
      bsYear: attendanceState.currentYear,
      bsMonthIndex: attendanceState.currentMonthIndex,
      expectedAmount: expectedAmount,
      bankReceivedAmount: actual,
      paymentDate: dateStr,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final isNepaliAppLang = locale.languageCode == 'ne';
    final attendanceState = ref.watch(attendanceControllerProvider);
    final settlementsState = ref.watch(settlementsControllerProvider);
    final previousMonthDue = settlementsState.previousMonthDue;
    final thisMonthNet = _calculateExpectedReceivable(attendanceState);
    final expectedAmount = thisMonthNet + previousMonthDue;
    final actualText = _actualController.text.trim();
    final actualAmount = int.tryParse(actualText) ?? 0;
    final difference = (expectedAmount - actualAmount).clamp(0, 99999999);
    final isFullyPaid = actualAmount >= expectedAmount && actualAmount > 0;
    final isPartial = actualAmount > 0 && actualAmount < expectedAmount;

    // Formatted date representations
    final nepaliMonth = NepaliCalendarHelper.nepaliMonths[_selectedBS.month - 1];
    final nepaliMonthEn = NepaliCalendarHelper.nepaliMonthsEnglish[_selectedBS.month - 1];
    final bsDayDigits = AppFormatters.toDevanagariDigits('${_selectedBS.day}');
    final bsYearDigits = AppFormatters.toDevanagariDigits('${_selectedBS.year}');
    final bsFormattedDevanagari = '$nepaliMonth $bsDayDigits, $bsYearDigits';
    final bsFormattedEnglish = '$nepaliMonthEn ${_selectedBS.day}, ${_selectedBS.year}';

    const adMonthNamesShort = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final adMonthStr = adMonthNamesShort[_selectedAD.month - 1];
    final adDateISO = NepaliCalendarHelper.formatDate(_selectedAD);
    final adFormatted = '$adDateISO ($adMonthStr ${_selectedAD.day})';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
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
                        color: const Color(0xFFEFF6FF), // soft blue
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.settlement_dialog_title,
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

                // Expected Net Receivable Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              l10n.settlement_expected_label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          Text(
                            AppFormatters.formatCurrency(expectedAmount, locale),
                            style: const TextStyle(
                              fontFamily: 'Mukta',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                      if (previousMonthDue > 0) ...[
                        const SizedBox(height: 6),
                        const Divider(height: 1, thickness: 0.5, color: AppColors.border),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isNepaliAppLang ? 'यस महिनाको खुद:' : 'This month net:',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                            Text(
                              AppFormatters.formatCurrency(thisMonthNet, locale),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isNepaliAppLang ? 'गत महिनाको बाँकी बक्यौता:' : 'Previous month unpaid due:',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFFD97706)),
                            ),
                            Text(
                              '+ ${AppFormatters.formatCurrency(previousMonthDue, locale)}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Actual Received Input Field
                Text(
                  l10n.settlement_actual_label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('settlement_actual_amount_field'),
                  controller: _actualController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      width: 48,
                      child: Text(
                        isNepaliAppLang ? 'रु.' : 'Rs.',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    hintText: 'e.g. 20000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Deposit Date Section Header with Calendar Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.settlement_date_label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // BS / AD Calendar Toggle
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            key: const Key('toggle_calendar_bs'),
                            onTap: () => setState(() => _isNepaliCalendar = true),
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _isNepaliCalendar ? AppColors.primary : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                              ),
                              child: Text(
                                l10n.settlement_calendar_bs,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: _isNepaliCalendar ? Colors.white : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            key: const Key('toggle_calendar_ad'),
                            onTap: () => setState(() => _isNepaliCalendar = false),
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: !_isNepaliCalendar ? AppColors.primary : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                              ),
                              child: Text(
                                l10n.settlement_calendar_ad,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: !_isNepaliCalendar ? Colors.white : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Interactive Tappable Date Card (Synchronized BS & AD)
                InkWell(
                  key: const Key('settlement_date_picker_tile'),
                  onTap: () {
                    if (_isNepaliCalendar) {
                      _pickNepaliDate(context, isNepaliAppLang);
                    } else {
                      _pickEnglishDate(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isNepaliCalendar
                                    ? (isNepaliAppLang ? bsFormattedDevanagari : bsFormattedEnglish)
                                    : adFormatted,
                                style: const TextStyle(
                                  fontFamily: 'Mukta',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isNepaliCalendar
                                    ? 'English (AD): $adDateISO'
                                    : 'Nepali (BS): ${isNepaliAppLang ? bsFormattedDevanagari : bsFormattedEnglish}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            if (_isNepaliCalendar) {
                              _pickNepaliDate(context, isNepaliAppLang);
                            } else {
                              _pickEnglishDate(context);
                            }
                          },
                          child: Text(
                            l10n.settlement_pick_date,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Remarks / Note Field
                Text(
                  isNepaliAppLang ? 'कैफियत / विवरण (ऐच्छिक)' : 'Remarks / Note (Optional)',
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
                    hintText: isNepaliAppLang
                        ? 'जस्तै: बैंक ट्रान्सफर मार्फत प्राप्त'
                        : 'e.g. Bank transfer deposit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Live Calculation Feedback Box
                if (actualAmount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isFullyPaid
                          ? const Color(0xFFE6F4EA)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isFullyPaid
                            ? const Color(0xFFA6E9B5)
                            : const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isFullyPaid
                              ? Icons.check_circle_outline_rounded
                              : Icons.info_outline_rounded,
                          color: isFullyPaid
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isFullyPaid
                                    ? l10n.settlement_fully_paid_badge
                                    : '${l10n.settlement_diff_label}: ${AppFormatters.formatCurrency(difference, locale)}',
                                style: TextStyle(
                                  fontFamily: 'Mukta',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: isFullyPaid
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Action Buttons
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(90, 48),
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: AppColors.border, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        l10n.common_cancel,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    ElevatedButton.icon(
                      key: const Key('save_salary_settlement_button'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 48),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _handleSave(expectedAmount),
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: Text(
                        l10n.common_save,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
