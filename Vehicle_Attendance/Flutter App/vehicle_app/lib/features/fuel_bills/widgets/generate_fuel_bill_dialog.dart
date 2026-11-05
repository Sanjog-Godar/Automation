import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../controllers/fuel_bills_controller.dart';

/// Modal dialog for generating a new vehicle fuel bill.
/// Replicates the exact visual appearance, calculations, and behavior of Next.js `MonthlyAttendanceClient.tsx`.
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
  ConsumerState<GenerateFuelBillDialog> createState() => _GenerateFuelBillDialogState();
}

class _GenerateFuelBillDialogState extends ConsumerState<GenerateFuelBillDialog> {
  late String _lastBillDate; // YYYY-MM-DD
  late String _startDate; // YYYY-MM-DD
  late String _endDate; // YYYY-MM-DD
  final TextEditingController _actualLitersController = TextEditingController();

  int _totalKm = 0;
  double _expectedLiters = 0.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final fuelBillsState = ref.read(fuelBillsControllerProvider);
    _lastBillDate = fuelBillsState.lastBillDate ??
        (fuelBillsState.bills.isNotEmpty
            ? fuelBillsState.bills.first.endDate
            : '2026-01-15');

    _startDate = _computeNextDay(_lastBillDate);
    _endDate = NepalClock.todayDateString();

    // Calculate synchronously from in-memory logs (0ms, matches Next.js web app 1:1)
    _calculateKmFromCurrentLogs();
  }

  @override
  void dispose() {
    _actualLitersController.dispose();
    super.dispose();
  }

  String _computeNextDay(String yyyyMmDd) {
    try {
      final dt = NepalClock.parseDate(yyyyMmDd);
      final next = dt.add(const Duration(days: 1));
      return NepalClock.formatDate(next);
    } catch (_) {
      return yyyyMmDd;
    }
  }

  /// Calculates total KM synchronously from currently loaded attendance logs.
  void _calculateKmFromCurrentLogs() {
    final logs = ref.read(attendanceControllerProvider).logs;
    final start = DateTime.tryParse(_startDate);
    final end = DateTime.tryParse(_endDate);

    int km = 0;
    if (start != null && end != null) {
      for (final log in logs) {
        if (log.isUnselected || log.kmTotal == null || log.kmTotal! <= 0) continue;
        try {
          final dt = DateTime.parse(log.logDate);
          if (!dt.isBefore(start) && !dt.isAfter(end)) {
            km += log.kmTotal!;
          }
        } catch (_) {}
      }
    }

    final expected = km / AppConstants.fuelMileageKmPerLiter;
    setState(() {
      _totalKm = km;
      _expectedLiters = double.parse(expected.toStringAsFixed(2));
    });
  }

  String _formatDisplayDate(String yyyyMmDd) {
    try {
      final parts = yyyyMmDd.split('-');
      if (parts.length == 3) {
        return '${parts[1]}/${parts[2]}/${parts[0]}';
      }
    } catch (_) {}
    return yyyyMmDd;
  }

  String _formatPeriod(String startYmd, String endYmd) {
    try {
      final s = NepalClock.parseDate(startYmd);
      final e = NepalClock.parseDate(endYmd);
      return '${s.month}/${s.day}/${s.year} - ${e.month}/${e.day}/${e.year}';
    } catch (_) {
      return '$startYmd - $endYmd';
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

    if (picked != null) {
      final formatted = NepalClock.formatDate(picked);
      setState(() {
        _endDate = formatted;
      });
      _calculateKmFromCurrentLogs();
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
        _calculateKmFromCurrentLogs();
      }
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final actualLiters = double.tryParse(_actualLitersController.text.trim());
    final success = await ref
        .read(fuelBillsControllerProvider.notifier)
        .createFuelBill(
          startDate: _startDate,
          endDate: _endDate,
          totalKm: _totalKm,
          expectedLiters: _expectedLiters,
          actualLiters: actualLiters,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##,###', 'en_IN');

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
            // Modal Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('⛽', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text(
                      'Generate Fuel Bill',
                      style: TextStyle(
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
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Last Bill Ended On Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Last Bill Ended On',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        side: const BorderSide(color: Color(0xFF93C5FD)),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Text('✏️', style: TextStyle(fontSize: 12)),
                      label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      onPressed: _pickLastBillDate,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: Text(
                    _formatDisplayDate(_lastBillDate),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Previous bill ended on this date',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Bill Start Date (From)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bill Start Date (From)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: Text(
                    _formatDisplayDate(_startDate),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Auto-calculated as day after last bill (edit last bill date to change this)',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. Bill End Date (To)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bill End Date (To)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 5),
                InkWell(
                  onTap: _pickEndDate,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: double.infinity,
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
                          _formatDisplayDate(_endDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6B7280)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Calculation Display Card (Exact Replica of Web App Image 3)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB), // amber-50
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFED7AA), width: 1.5), // amber-200
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Period:',
                            style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatPeriod(_startDate, _endDate),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total KM:',
                            style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currencyFormatter.format(_totalKm)} km',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9333EA), // purple-600
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Expected Fuel (÷ 7.5):',
                    style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_expectedLiters.toStringAsFixed(_expectedLiters.truncateToDouble() == _expectedLiters ? 0 : 2)} Liters',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEA580C), // orange-600
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Actual Fuel Given (Optional)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actual Fuel Given (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _actualLitersController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    hintText: 'e.g. 45.5',
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      borderSide: const BorderSide(color: Color(0xFFEA580C), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Enter the actual liters provided by the company',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bottom Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC2410C), // orange-700
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('💾', style: TextStyle(fontSize: 14)),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Fuel Bill',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
