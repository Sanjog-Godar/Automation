import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../../l10n/app_localizations.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../controllers/fuel_bills_controller.dart';

/// Modal dialog for generating a new vehicle fuel bill.
/// Fully localized with reactive updates and zero language mixing.
class GenerateFuelBillDialog extends ConsumerStatefulWidget {
  const GenerateFuelBillDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: GenerateFuelBillDialog(),
      ),
    );
  }

  @override
  ConsumerState<GenerateFuelBillDialog> createState() =>
      _GenerateFuelBillDialogState();
}

class _GenerateFuelBillDialogState
    extends ConsumerState<GenerateFuelBillDialog> {
  late String _lastBillDate; // YYYY-MM-DD
  late String _startDate; // YYYY-MM-DD
  late String _endDate; // YYYY-MM-DD
  final TextEditingController _actualLitersController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final fuelBillsState = ref.read(fuelBillsControllerProvider);
    _lastBillDate = fuelBillsState.lastBillDate ??
        (fuelBillsState.bills.isNotEmpty
            ? fuelBillsState.bills.first.endDate
            : AppConstants.defaultLastFuelBillDate);
    _startDate = _computeNextDay(_lastBillDate);
    _endDate = NepalClock.todayDateString();
  }

  @override
  void dispose() {
    _actualLitersController.dispose();
    super.dispose();
  }

  String _computeNextDay(String yyyyMmDd) {
    try {
      final dt = NepalClock.parseDate(yyyyMmDd);
      return NepalClock.formatDate(dt.add(const Duration(days: 1)));
    } catch (_) {
      return yyyyMmDd;
    }
  }

  ({int totalKm, double expectedLiters}) _calcFromLogs(List<dynamic> logs) {
    final start = DateTime.tryParse(_startDate);
    final end = DateTime.tryParse(_endDate);
    int km = 0;
    if (start != null && end != null) {
      for (final log in logs) {
        if (log.isUnselected || log.kmTotal == null || log.kmTotal <= 0) {
          continue;
        }
        try {
          final dt = DateTime.parse(log.logDate as String);
          if (!dt.isBefore(start) && !dt.isAfter(end)) {
            km += log.kmTotal as int;
          }
        } catch (_) {}
      }
    }
    final expected =
        double.parse((km / AppConstants.fuelMileageKmPerLiter).toStringAsFixed(2));
    return (totalKm: km, expectedLiters: expected);
  }

  String _formatDisplayDate(String yyyyMmDd, Locale locale) {
    String formatted = yyyyMmDd;
    try {
      final p = yyyyMmDd.split('-');
      if (p.length == 3) formatted = '${p[1]}/${p[2]}/${p[0]}';
    } catch (_) {}
    return locale.languageCode == 'ne'
        ? AppFormatters.toDevanagariDigits(formatted)
        : formatted;
  }

  String _formatPeriod(String s, String e, Locale locale) {
    try {
      final sd = NepalClock.parseDate(s);
      final ed = NepalClock.parseDate(e);
      final raw = '${sd.month}/${sd.day}/${sd.year} - ${ed.month}/${ed.day}/${ed.year}';
      return locale.languageCode == 'ne'
          ? AppFormatters.toDevanagariDigits(raw)
          : raw;
    } catch (_) {
      final raw = '$s - $e';
      return locale.languageCode == 'ne'
          ? AppFormatters.toDevanagariDigits(raw)
          : raw;
    }
  }

  Future<void> _pickEndDate() async {
    final cur = NepalClock.parseDate(_endDate);
    final first = NepalClock.parseDate(_startDate);
    final last = NepalClock.today().add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: cur.isBefore(first) ? first : cur,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null && mounted) {
      setState(() => _endDate = NepalClock.formatDate(picked));
    }
  }

  Future<void> _pickLastBillDate() async {
    final cur = NepalClock.parseDate(_lastBillDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: cur,
      firstDate: DateTime(2020),
      lastDate: NepalClock.today(),
    );
    if (picked != null) {
      final formatted = NepalClock.formatDate(picked);
      final success = await ref
          .read(fuelBillsControllerProvider.notifier)
          .updateLastBillDate(formatted);
      if (success && mounted) {
        setState(() {
          _lastBillDate = formatted;
          _startDate = _computeNextDay(formatted);
        });
      }
    }
  }

  Future<void> _handleSave(int totalKm, double expectedLiters) async {
    setState(() => _isSaving = true);
    final actualLiters =
        double.tryParse(_actualLitersController.text.trim());
    final success = await ref
        .read(fuelBillsControllerProvider.notifier)
        .createFuelBill(
          startDate: _startDate,
          endDate: _endDate,
          totalKm: totalKm,
          expectedLiters: expectedLiters,
          actualLiters: actualLiters,
        );
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final attendanceState = ref.watch(attendanceControllerProvider);

    final calc = _calcFromLogs(attendanceState.logs);
    final totalKm = calc.totalKm;
    final expectedLiters = calc.expectedLiters;

    final kmLabel = AppFormatters.formatUnit(totalKm, 'km', locale);
    final expectedLitersFormatted = AppFormatters.formatNumber(
      expectedLiters,
      locale,
      maxFractionDigits: expectedLiters.truncateToDouble() == expectedLiters ? 0 : 2,
    );

    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title row ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('⛽', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      l10n.generate_fuel_dialog_title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.pop(context),
                  tooltip: l10n.common_close,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 1. Last Bill Ended On ─────────────────────────────────────
            _SectionLabel(label: l10n.generate_fuel_dialog_lastEnded),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: _ReadonlyDateBox(
                      text: _formatDisplayDate(_lastBillDate, locale)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    side: const BorderSide(color: Color(0xFF93C5FD)),
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 13),
                  label: Text(l10n.common_edit,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  onPressed: _pickLastBillDate,
                ),
              ],
            ),
            const SizedBox(height: 3),
            _HintText(l10n.generate_fuel_dialog_lastEndedHint),
            const SizedBox(height: 12),

            // ── 2. Bill Start Date (From) ─────────────────────────────────
            _SectionLabel(label: l10n.generate_fuel_dialog_startDate),
            const SizedBox(height: 5),
            _ReadonlyDateBox(text: _formatDisplayDate(_startDate, locale)),
            const SizedBox(height: 3),
            _HintText(l10n.generate_fuel_dialog_startDateHint),
            const SizedBox(height: 12),

            // ── 3. Bill End Date (To) ─────────────────────────────────────
            _SectionLabel(label: l10n.generate_fuel_dialog_endDate),
            const SizedBox(height: 5),
            InkWell(
              onTap: _pickEndDate,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDisplayDate(_endDate, locale),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: Color(0xFF6B7280)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── 4. Calculation Card ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFED7AA), width: 1.5),
              ),
              child: attendanceState.isLoading
                  ? _CalcLoading(label: l10n.generate_fuel_dialog_calculating)
                  : _CalcResult(
                      periodTitle: l10n.generate_fuel_dialog_periodLabel,
                      periodValue: _formatPeriod(_startDate, _endDate, locale),
                      totalKmTitle: l10n.generate_fuel_dialog_totalKmLabel,
                      totalKmValue: kmLabel,
                      expectedFuelTitle: l10n.generate_fuel_dialog_expectedFuelLabel,
                      litersValue: l10n.generate_fuel_dialog_litersDisplay(expectedLitersFormatted),
                    ),
            ),
            const SizedBox(height: 16),

            // ── 5. Actual Fuel Given (Optional) ───────────────────────────
            _SectionLabel(label: l10n.generate_fuel_dialog_actualLitersLabel),
            const SizedBox(height: 5),
            TextField(
              controller: _actualLitersController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
              decoration: InputDecoration(
                hintText: l10n.generate_fuel_dialog_actualLitersHint,
                hintStyle:
                    const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: Color(0xFFEA580C), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 3),
            _HintText(l10n.generate_fuel_dialog_actualLitersHelper),
            const SizedBox(height: 20),

            // ── Action Buttons ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed:
                      _isSaving ? null : () => Navigator.pop(context),
                  child: Text(l10n.common_cancel,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC2410C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: (_isSaving || attendanceState.isLoading)
                      ? null
                      : () => _handleSave(totalKm, expectedLiters),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('💾',
                          style: TextStyle(fontSize: 14)),
                  label: Text(
                    _isSaving
                        ? l10n.generate_fuel_dialog_savingButton
                        : l10n.generate_fuel_dialog_saveButton,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private helper widgets ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF374151),
        ),
      );
}

class _HintText extends StatelessWidget {
  const _HintText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
      );
}

class _ReadonlyDateBox extends StatelessWidget {
  const _ReadonlyDateBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}

class _CalcLoading extends StatelessWidget {
  const _CalcLoading({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFEA580C),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            ),
          ],
        ),
      );
}

class _CalcResult extends StatelessWidget {
  const _CalcResult({
    required this.periodTitle,
    required this.periodValue,
    required this.totalKmTitle,
    required this.totalKmValue,
    required this.expectedFuelTitle,
    required this.litersValue,
  });

  final String periodTitle;
  final String periodValue;
  final String totalKmTitle;
  final String totalKmValue;
  final String expectedFuelTitle;
  final String litersValue;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      periodTitle,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF4B5563)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      periodValue,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    totalKmTitle,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalKmValue,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9333EA),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            expectedFuelTitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 2),
          Text(
            litersValue,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEA580C),
            ),
          ),
        ],
      );
}
