import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/toast_service.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../../fuel_bills/controllers/fuel_bills_controller.dart';
import '../../fuel_bills/widgets/generate_fuel_bill_dialog.dart';
import '../services/pdf_report_service.dart';

/// Quick Actions card presenting large touch-friendly buttons for:
/// 1. "Generate Fuel Bill" (calculates consumption)
/// 2. "Download Report" (PDF format up to today)
/// Exact visual reproduction of Next.js `MonthlyAttendanceClient.tsx` Quick Actions section.
class QuickActionsCard extends ConsumerStatefulWidget {
  const QuickActionsCard({super.key});

  @override
  ConsumerState<QuickActionsCard> createState() => _QuickActionsCardState();
}

class _QuickActionsCardState extends ConsumerState<QuickActionsCard> {
  bool _isGeneratingPdf = false;

  Future<void> _handleDownloadPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final attendanceState = ref.read(attendanceControllerProvider);
      final fuelBills = ref.read(fuelBillsControllerProvider).bills;

      await PdfReportService.generateAndDownloadReport(
        bsYear: attendanceState.currentYear,
        bsMonthIndex: attendanceState.currentMonthIndex,
        fullMonthLogs: attendanceState.logs,
        fuelBills: fuelBills,
      );
    } catch (e) {
      if (mounted) {
        ref.read(toastServiceProvider).showError(
          'Error generating PDF: $e',
          nepaliMessage: 'PDF सिर्जना गर्न समस्या भयो',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // Title
            const Text(
              'Quick Actions / छिटो कार्यहरू',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // Two Action Buttons (Generate Fuel Bill & Download Report)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 550;

                final fuelBillBtn = _buildActionButton(
                  icon: '⛽',
                  title: 'Generate Fuel Bill',
                  subtitle: 'Calculate consumption',
                  gradientColors: const [
                    Color(0xFFC2410C), // orange-700
                    Color(0xFFEA580C), // orange-600
                  ],
                  onTap: () => GenerateFuelBillDialog.show(context),
                );

                final downloadBtn = _buildActionButton(
                  icon: '📄',
                  title: 'Download Report',
                  subtitle: 'PDF format (up to today)',
                  gradientColors: const [
                    Color(0xFF1D4ED8), // blue-700
                    Color(0xFF2563EB), // blue-600
                  ],
                  isLoading: _isGeneratingPdf,
                  onTap: _isGeneratingPdf ? null : _handleDownloadPdf,
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: fuelBillBtn),
                      const SizedBox(width: 12),
                      Expanded(child: downloadBtn),
                    ],
                  );
                }

                return Column(
                  children: [
                    fuelBillBtn,
                    const SizedBox(height: 10),
                    downloadBtn,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              else
                Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
