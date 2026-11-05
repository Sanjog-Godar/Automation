import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../attendance/models/attendance_log.dart';
import '../../attendance/models/monthly_summary.dart';
import '../../fuel_bills/models/fuel_bill.dart';

/// Service responsible for generating the official monthly vehicle attendance and settlement PDF.
/// Replicates the exact layout, formulas, TDS @ 1.5%, and formatting of `MonthlyAttendanceClient.tsx`.
class PdfReportService {
  PdfReportService._();

  static const List<String> nepaliMonthsEnglish = [
    'Baisakh',
    'Jestha',
    'Ashadh',
    'Shrawan',
    'Bhadra',
    'Ashwin',
    'Kartik',
    'Mangsir',
    'Poush',
    'Magh',
    'Falgun',
    'Chaitra',
  ];

  /// Generates and previews/prints/downloads the monthly PDF report.
  static Future<void> generateAndDownloadReport({
    required int bsYear,
    required int bsMonthIndex,
    required List<AttendanceLog> fullMonthLogs,
    List<FuelBill> fuelBills = const [],
  }) async {
    final pdf = pw.Document();

    // Load bundled Mukta TTF fonts from assets
    final regularFontData = await rootBundle.load('assets/fonts/Mukta-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Mukta-Bold.ttf');
    final ttfRegular = pw.Font.ttf(regularFontData);
    final ttfBold = pw.Font.ttf(boldFontData);

    final nepaliMonthNameEnglish = nepaliMonthsEnglish[bsMonthIndex];
    final monthYearTitle = '$nepaliMonthNameEnglish $bsYear';

    // 1. Filter only logs up to today and not unselected
    final todayDt = NepalClock.today();
    final logsUpToToday = fullMonthLogs.where((log) {
      if (log.isUnselected) return false;
      final logDt = NepalClock.parseDate(log.logDate);
      return !logDt.isAfter(todayDt);
    }).toList();

    // 2. Compute summary up to today
    final summaryUpToToday = MonthlySummary.calculate(logsUpToToday);

    // 3. Group BS day numbers by status
    final List<int> presentDates = [];
    final List<int> absentDates = [];
    final List<int> replaceDates = [];
    final List<int> tipDates = [];

    for (int i = 0; i < fullMonthLogs.length; i++) {
      final log = fullMonthLogs[i];
      if (log.isUnselected) continue;
      final logDt = NepalClock.parseDate(log.logDate);
      if (logDt.isAfter(todayDt)) continue;

      final bsDay = i + 1; // 1-based day of the month

      if (log.status == AttendanceStatus.present) {
        presentDates.add(bsDay);
      } else if (log.status == AttendanceStatus.absentHoliday) {
        absentDates.add(bsDay);
      } else if (log.status == AttendanceStatus.absentReplacement) {
        replaceDates.add(bsDay);
      }

      if ((log.extraTipAmount != null && log.extraTipAmount! > 0) ||
          log.extraTripIncome > 0) {
        if (!tipDates.contains(bsDay)) tipDates.add(bsDay);
      }
    }

    presentDates.sort();
    absentDates.sort();
    replaceDates.sort();
    tipDates.sort();

    // 4. Financial formulas (exact match with Next.js web)
    final presentIncome = summaryUpToToday.totalPresentDays * AppConstants.dailyWage;
    final presentFormula = '${summaryUpToToday.totalPresentDays} × ${AppConstants.dailyWage}';
    final replaceFormula = '${summaryUpToToday.totalReplacementDays} × ${AppConstants.replacementDeduction}';
    final totalEarning = presentIncome - summaryUpToToday.totalDeductions;
    final totalHolidayDays = logsUpToToday.where((l) => l.status == AttendanceStatus.absentHoliday).length;

    // Tips data breakdown
    final tipsData = logsUpToToday.where((l) => l.extraTipAmount != null && l.extraTipAmount! > 0).toList();
    final calculatedTipsTotal = summaryUpToToday.totalExtraTips;

    // TDS Calculation @ 1.5% strictly on totalEarning
    final tdsAmount = (totalEarning * AppConstants.tdsRate).round();
    final totalBeforeTDS = totalEarning + calculatedTipsTotal + summaryUpToToday.totalExtraIncome;
    final netIncomeAfterTDS = totalBeforeTDS - tdsAmount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        theme: pw.ThemeData.withFont(
          base: ttfRegular,
          bold: ttfBold,
        ),
        header: (context) {
          return pw.Column(
            children: [
              pw.Center(
                child: pw.Text(
                  'Monthly Details Sheet',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Center(
                child: pw.Text(
                  monthYearTitle,
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  AppConstants.vehicleNumber,
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
            ],
          );
        },
        footer: (context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated: ${NepalClock.todayDateString()}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Vehicle Attendance System',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          );
        },
        build: (context) => [
          // Date Lists Section
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Total Present Days = ${presentDates.isNotEmpty ? presentDates.join(", ") : "None"} (Total Days: ${presentDates.length})',
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Absent = ${absentDates.isNotEmpty ? absentDates.join(", ") : "None"} (${absentDates.length})',
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Replace = ${replaceDates.isNotEmpty ? replaceDates.join(", ") : "None"} (${replaceDates.length})',
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Extra tips = ${tipDates.isNotEmpty ? tipDates.join(", ") : "None"}',
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Earning Sheet Table Header
          pw.Text(
            'Earning Sheet',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),

          // Earning Sheet Grid Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(3),
              3: pw.FlexColumnWidth(2.5),
            },
            children: [
              // Head
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2563EB)),
                children: [
                  _tableCell('', isHeader: true, textColor: PdfColors.white),
                  _tableCell('Total Days', isHeader: true, textColor: PdfColors.white),
                  _tableCell('Earning', isHeader: true, textColor: PdfColors.white),
                  _tableCell('Total', isHeader: true, textColor: PdfColors.white, alignRight: true),
                ],
              ),
              // Present Days
              pw.TableRow(
                children: [
                  _tableCell('Present Days'),
                  _tableCell('${summaryUpToToday.totalPresentDays}', center: true),
                  _tableCell(presentFormula),
                  _tableCell('Rs $presentIncome', alignRight: true),
                ],
              ),
              // Absent Days
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF9FAFB)),
                children: [
                  _tableCell('Absent Days'),
                  _tableCell('$totalHolidayDays', center: true),
                  _tableCell('-'),
                  _tableCell('-', alignRight: true),
                ],
              ),
              // Replace Days
              pw.TableRow(
                children: [
                  _tableCell('Replace Days'),
                  _tableCell('${summaryUpToToday.totalReplacementDays}', center: true),
                  _tableCell(replaceFormula),
                  _tableCell('Rs ${summaryUpToToday.totalDeductions}', alignRight: true),
                ],
              ),
              // Total Earning
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFF6FF)),
                children: [
                  _tableCell(''),
                  _tableCell(''),
                  _tableCell('Total Earning', isBold: true),
                  _tableCell('Rs $totalEarning', isBold: true, alignRight: true),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // Extra Tips Section
          pw.Text(
            'Extra Tips',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),

          if (tipsData.isNotEmpty) ...[
            ...List.generate(tipsData.length, (index) {
              final tip = tipsData[index];
              final adDate = NepalClock.parseDate(tip.logDate);
              const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
              final adDateStr = '${adDate.day} ${months[adDate.month]} ${adDate.year}';

              final destination = (tip.extraTipNote != null && tip.extraTipNote!.isNotEmpty)
                  ? tip.extraTipNote!
                  : 'No destination';
              final amount = tip.extraTipAmount ?? 0;

              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${index + 1}. $destination ($adDateStr)',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Rs $amount',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 4),
            pw.Text(
              'Total Tips Amount: Rs $calculatedTipsTotal',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ] else ...[
            pw.Text(
              'No extra tips recorded',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
          pw.SizedBox(height: 10),

          pw.Text(
            'Calculated by earning from total present days - Replace Days',
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 12),

          // Final Settlement Section
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Final Settlement',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                _summaryRow('Total Earning (from attendance):', 'Rs $totalEarning'),
                _summaryRow('Extra Tips:', 'Rs $calculatedTipsTotal'),
                if (summaryUpToToday.totalExtraIncome > 0)
                  _summaryRow('Extra Trip Income:', 'Rs ${summaryUpToToday.totalExtraIncome}'),
                _summaryRow('Gross Total:', 'Rs $totalBeforeTDS', isBold: true),
                pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                _summaryRow(
                  'Less: TDS @ 1.5%:',
                  'Rs $tdsAmount',
                  textColor: const PdfColor.fromInt(0xFFDC2626), // red
                  isBold: true,
                ),
                pw.SizedBox(height: 4),
                _summaryRow(
                  'Net Income (After TDS):',
                  'Rs $netIncomeAfterTDS',
                  textColor: const PdfColor.fromInt(0xFF16A34A), // green
                  isBold: true,
                  fontSize: 13,
                ),
              ],
            ),
          ),

          // Fuel Bill Summary if available
          if (fuelBills.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              'Fuel Bill Records',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(4),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF475569)),
                  children: [
                    _tableCell('Period', isHeader: true, textColor: PdfColors.white),
                    _tableCell('Total KM', isHeader: true, textColor: PdfColors.white, alignRight: true),
                    _tableCell('Expected', isHeader: true, textColor: PdfColors.white, alignRight: true),
                    _tableCell('Actual', isHeader: true, textColor: PdfColors.white, alignRight: true),
                  ],
                ),
                ...fuelBills.map((fb) {
                  return pw.TableRow(
                    children: [
                      _tableCell('${fb.startDate} -> ${fb.endDate}'),
                      _tableCell('${fb.totalKm} km', alignRight: true),
                      _tableCell('${fb.expectedLiters} L', alignRight: true),
                      _tableCell(fb.actualLiters != null ? '${fb.actualLiters} L' : '-', alignRight: true),
                    ],
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );

    final filename = 'Attendance_${nepaliMonthNameEnglish}_$bsYear.pdf';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: filename,
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    bool alignRight = false,
    bool center = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? PdfColors.black,
        ),
        textAlign: alignRight
            ? pw.TextAlign.right
            : center
                ? pw.TextAlign.center
                : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? textColor,
    double fontSize = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
