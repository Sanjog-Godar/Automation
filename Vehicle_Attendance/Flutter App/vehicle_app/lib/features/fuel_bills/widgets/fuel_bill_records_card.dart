import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/nepal_clock.dart';
import '../controllers/fuel_bills_controller.dart';

/// Card displaying vehicle fuel consumption history and the editable Last Fuel Bill End Date.
/// 100% device-responsive with ZERO horizontal scrolling across all mobile and tablet viewports.
class FuelBillRecordsCard extends ConsumerWidget {
  const FuelBillRecordsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelBillsState = ref.watch(fuelBillsControllerProvider);
    final controller = ref.read(fuelBillsControllerProvider.notifier);
    final currencyFormatter = NumberFormat('#,##,###', 'en_IN');

    final bills = fuelBillsState.bills;
    final lastBillDate = fuelBillsState.lastBillDate ??
        (bills.isNotEmpty ? bills.first.endDate : '2026-01-15');

    // Format date as MM/DD/YYYY to match the web view
    String displayDate = lastBillDate;
    try {
      final dt = NepalClock.parseDate(lastBillDate);
      final mm = dt.month.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      final yyyy = dt.year.toString();
      displayDate = '$mm/$dd/$yyyy';
    } catch (_) {}

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Title
            const Text(
              'Fuel Bill Records / ईन्धन बिल रेकर्ड',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),

            // Last Fuel Bill End Date Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED), // orange-50
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDBA74), width: 1.5), // orange-300
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('🗓️', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text(
                        'Last Fuel Bill End Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This is the last date your previous fuel bill ended. Edit it if there was a mistake.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Date Display Box
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                          ),
                          child: Text(
                            displayDate,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Edit Date Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFC2410C), // orange-700
                          side: const BorderSide(color: Color(0xFFFDBA74), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text(
                          'Edit Date',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: fuelBillsState.isSaving
                            ? null
                            : () async {
                                final cur = NepalClock.parseDate(lastBillDate);
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: cur,
                                  firstDate: DateTime(2020),
                                  lastDate: NepalClock.today(),
                                );
                                if (picked != null) {
                                  final formatted = NepalClock.formatDate(picked);
                                  await controller.updateLastBillDate(formatted);
                                }
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Fuel Bills Table (Zero Horizontal Scroll, Matches Web App Exactly)
            if (fuelBillsState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (bills.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: const Text(
                  'No fuel bill records found.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FlexColumnWidth(3.4),
                    1: FlexColumnWidth(2.2),
                    2: FlexColumnWidth(2.4),
                    3: FlexColumnWidth(2.0),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
                      children: [
                        _buildHeaderCell('Period'),
                        _buildHeaderCell('Total KM', alignRight: true),
                        _buildHeaderCell('Expected Liters', alignRight: true),
                        _buildHeaderCell('Actual Liters', alignRight: true),
                      ],
                    ),
                    ...bills.map((bill) {
                      return TableRow(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                        ),
                        children: [
                          _buildDataCell('${bill.startDate} → ${bill.endDate}'),
                          _buildDataCell(
                            '${currencyFormatter.format(bill.totalKm)} km',
                            alignRight: true,
                            textColor: const Color(0xFF9333EA),
                            isBold: true,
                          ),
                          _buildDataCell(
                            '${bill.expectedLiters} L',
                            alignRight: true,
                            textColor: const Color(0xFF2563EB),
                            isBold: true,
                          ),
                          _buildDataCell(
                            bill.actualLiters != null ? '${bill.actualLiters} L' : '-',
                            alignRight: true,
                            textColor: const Color(0xFF16A34A),
                            isBold: true,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
        ),
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  Widget _buildDataCell(
    String text, {
    bool alignRight = false,
    Color textColor = const Color(0xFF334155),
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
      ),
    );
  }
}
