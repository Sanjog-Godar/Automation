import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../attendance/models/attendance_log.dart';
import '../../attendance/models/monthly_summary.dart';
import '../../fuel_bills/models/fuel_bill.dart';

/// Service responsible for generating the official monthly vehicle attendance and settlement PDF.
/// Fully localized in English or Nepali based on the active locale.
class PdfReportService {
  PdfReportService._();

  /// Generates and previews/prints/downloads the monthly PDF report.
  static Future<void> generateAndDownloadReport({
    required int bsYear,
    required int bsMonthIndex,
    required List<AttendanceLog> fullMonthLogs,
    List<FuelBill> fuelBills = const [],
    Locale locale = const Locale('ne'),
  }) async {
    final pdf = pw.Document();
    final isNepali = locale.languageCode == 'ne';

    // Load bundled Mukta TTF fonts from assets (Mukta supports both Latin and Devanagari)
    final regularFontData = await rootBundle.load('assets/fonts/Mukta-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Mukta-Bold.ttf');
    final ttfRegular = pw.Font.ttf(regularFontData);
    final ttfBold = pw.Font.ttf(boldFontData);

    final monthName = AppFormatters.bsMonthName(bsMonthIndex, locale);
    final formattedYear = isNepali ? AppFormatters.toDevanagariDigits('$bsYear') : '$bsYear';
    final monthYearTitle = '$monthName $formattedYear';

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

      if (log.extraTripIncome > 0) {
        if (!tipDates.contains(bsDay)) tipDates.add(bsDay);
      }
    }

    presentDates.sort();
    absentDates.sort();
    replaceDates.sort();
    tipDates.sort();

    final presentDayNums = presentDates.map((d) => isNepali ? AppFormatters.toDevanagariDigits('$d') : '$d').toList();
    final absentDayNums = absentDates.map((d) => isNepali ? AppFormatters.toDevanagariDigits('$d') : '$d').toList();
    final replaceDayNums = replaceDates.map((d) => isNepali ? AppFormatters.toDevanagariDigits('$d') : '$d').toList();
    final tipDayNums = tipDates.map((d) => isNepali ? AppFormatters.toDevanagariDigits('$d') : '$d').toList();
    final noneText = isNepali ? 'कुनै छैन' : 'None';

    // 4. Financial formulas (exact match with Next.js web)
    final presentIncome = summaryUpToToday.totalPresentDays * AppConstants.dailyWage;
    final presentFormula = isNepali
        ? '${AppFormatters.toDevanagariDigits("${summaryUpToToday.totalPresentDays}")} × ${AppFormatters.toDevanagariDigits("${AppConstants.dailyWage}")}'
        : '${summaryUpToToday.totalPresentDays} × ${AppConstants.dailyWage}';
    final replaceFormula = isNepali
        ? '${AppFormatters.toDevanagariDigits("${summaryUpToToday.totalReplacementDays}")} × ${AppFormatters.toDevanagariDigits("${AppConstants.replacementDeduction}")}'
        : '${summaryUpToToday.totalReplacementDays} × ${AppConstants.replacementDeduction}';
    final totalEarning = presentIncome - summaryUpToToday.totalDeductions;
    final totalHolidayDays = logsUpToToday.where((l) => l.status == AttendanceStatus.absentHoliday).length;

    // TDS Calculation @ 1.5% strictly on totalEarning
    final tdsAmount = (totalEarning * AppConstants.tdsRate).round();
    final totalBeforeTDS = totalEarning + summaryUpToToday.totalExtraIncome;
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
                  isNepali ? 'मासिक विवरण पाना' : 'Monthly Details Sheet',
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
          final pageStr = isNepali
              ? AppFormatters.toDevanagariDigits(context.pageNumber.toString())
              : '${context.pageNumber}';
          final pagesTotalStr = isNepali
              ? AppFormatters.toDevanagariDigits(context.pagesCount.toString())
              : '${context.pagesCount}';

          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                isNepali
                    ? 'तयार मिति: ${AppFormatters.toDevanagariDigits(NepalClock.todayDateString())}'
                    : 'Generated: ${NepalClock.todayDateString()}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                isNepali ? 'सवारी साधन उपस्थिति प्रणाली' : 'Vehicle Attendance System',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                isNepali ? 'पृष्ठ $pageStr / $pagesTotalStr' : 'Page $pageStr of $pagesTotalStr',
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
                  isNepali
                      ? 'जम्मा उपस्थित दिनहरू = ${presentDayNums.isNotEmpty ? presentDayNums.join(", ") : noneText} (जम्मा दिनहरू: ${AppFormatters.toDevanagariDigits("${presentDates.length}")})'
                      : 'Total Present Days = ${presentDayNums.isNotEmpty ? presentDayNums.join(", ") : noneText} (Total Days: ${presentDates.length})',
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  isNepali
                      ? 'बिदा = ${absentDayNums.isNotEmpty ? absentDayNums.join(", ") : noneText} (${AppFormatters.toDevanagariDigits("${absentDates.length}")})'
                      : 'Absent = ${absentDayNums.isNotEmpty ? absentDayNums.join(", ") : noneText} (${absentDates.length})',
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  isNepali
                      ? 'सट्टा = ${replaceDayNums.isNotEmpty ? replaceDayNums.join(", ") : noneText} (${AppFormatters.toDevanagariDigits("${replaceDates.length}")})'
                      : 'Replace = ${replaceDayNums.isNotEmpty ? replaceDayNums.join(", ") : noneText} (${replaceDates.length})',
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  isNepali
                      ? 'अतिरिक्त टिप = ${tipDayNums.isNotEmpty ? tipDayNums.join(", ") : noneText}'
                      : 'Extra tips = ${tipDayNums.isNotEmpty ? tipDayNums.join(", ") : noneText}',
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Earning Sheet Table Header
          pw.Text(
            isNepali ? 'आम्दानी विवरण' : 'Earning Sheet',
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
                  _tableCell(isNepali ? 'जम्मा दिनहरू' : 'Total Days', isHeader: true, textColor: PdfColors.white),
                  _tableCell(isNepali ? 'हिसाब' : 'Earning', isHeader: true, textColor: PdfColors.white),
                  _tableCell(isNepali ? 'जम्मा' : 'Total', isHeader: true, textColor: PdfColors.white, alignRight: true),
                ],
              ),
              // Present Days
              pw.TableRow(
                children: [
                  _tableCell(isNepali ? 'उपस्थित दिनहरू' : 'Present Days'),
                  _tableCell(
                    isNepali ? AppFormatters.toDevanagariDigits('${summaryUpToToday.totalPresentDays}') : '${summaryUpToToday.totalPresentDays}',
                    center: true,
                  ),
                  _tableCell(presentFormula),
                  _tableCell(AppFormatters.formatCurrency(presentIncome, locale), alignRight: true),
                ],
              ),
              // Absent Days
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF9FAFB)),
                children: [
                  _tableCell(isNepali ? 'बिदा दिनहरू' : 'Absent Days'),
                  _tableCell(
                    isNepali ? AppFormatters.toDevanagariDigits('$totalHolidayDays') : '$totalHolidayDays',
                    center: true,
                  ),
                  _tableCell('-'),
                  _tableCell('-', alignRight: true),
                ],
              ),
              // Replace Days
              pw.TableRow(
                children: [
                  _tableCell(isNepali ? 'सट्टा दिनहरू' : 'Replace Days'),
                  _tableCell(
                    isNepali ? AppFormatters.toDevanagariDigits('${summaryUpToToday.totalReplacementDays}') : '${summaryUpToToday.totalReplacementDays}',
                    center: true,
                  ),
                  _tableCell(replaceFormula),
                  _tableCell(AppFormatters.formatCurrency(summaryUpToToday.totalDeductions, locale), alignRight: true),
                ],
              ),
              // Total Earning
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFF6FF)),
                children: [
                  _tableCell(''),
                  _tableCell(''),
                  _tableCell(isNepali ? 'जम्मा आम्दानी' : 'Total Earning', isBold: true),
                  _tableCell(AppFormatters.formatCurrency(totalEarning, locale), isBold: true, alignRight: true),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          pw.Text(
            isNepali
                ? 'उपस्थित दिनको आम्दानीबाट सट्टा दिनको कटौती घटाई गणना गरिएको'
                : 'Calculated by earning from total present days - Replace Days',
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
                  isNepali ? 'अन्तिम हिसाब मिलान' : 'Final Settlement',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                _summaryRow(
                  isNepali ? 'उपस्थिति आम्दानी:' : 'Total Earning (from attendance):',
                  AppFormatters.formatCurrency(totalEarning, locale),
                ),
                if (summaryUpToToday.totalExtraIncome > 0)
                  _summaryRow(
                    isNepali ? 'अतिरिक्त यात्रा आम्दानी:' : 'Extra Trip Income:',
                    AppFormatters.formatCurrency(summaryUpToToday.totalExtraIncome, locale),
                  ),
                _summaryRow(
                  isNepali ? 'कुल जम्मा:' : 'Gross Total:',
                  AppFormatters.formatCurrency(totalBeforeTDS, locale),
                  isBold: true,
                ),
                pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                _summaryRow(
                  isNepali ? 'कट्टी: टीडीएस @ १.५%:' : 'Less: TDS @ 1.5%:',
                  AppFormatters.formatCurrency(tdsAmount, locale),
                  textColor: const PdfColor.fromInt(0xFFDC2626), // red
                  isBold: true,
                ),
                pw.SizedBox(height: 4),
                _summaryRow(
                  isNepali ? 'खुद आम्दानी (टीडीएस पछि):' : 'Net Income (After TDS):',
                  AppFormatters.formatCurrency(netIncomeAfterTDS, locale),
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
              isNepali ? 'ईन्धन बिल रेकर्ड' : 'Fuel Bill Records',
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
                    _tableCell(isNepali ? 'समयावधि' : 'Period', isHeader: true, textColor: PdfColors.white),
                    _tableCell(isNepali ? 'जम्मा कि.मि.' : 'Total KM', isHeader: true, textColor: PdfColors.white, alignRight: true),
                    _tableCell(isNepali ? 'अनुमानित' : 'Expected', isHeader: true, textColor: PdfColors.white, alignRight: true),
                    _tableCell(isNepali ? 'प्राप्त' : 'Actual', isHeader: true, textColor: PdfColors.white, alignRight: true),
                  ],
                ),
                ...fuelBills.map((fb) {
                  final formattedStart = isNepali ? AppFormatters.toDevanagariDigits(fb.startDate) : fb.startDate;
                  final formattedEnd = isNepali ? AppFormatters.toDevanagariDigits(fb.endDate) : fb.endDate;
                  return pw.TableRow(
                    children: [
                      _tableCell('$formattedStart → $formattedEnd'),
                      _tableCell(AppFormatters.formatUnit(fb.totalKm, 'km', locale), alignRight: true),
                      _tableCell(AppFormatters.formatUnit(fb.expectedLiters, 'L', locale), alignRight: true),
                      _tableCell(fb.actualLiters != null ? AppFormatters.formatUnit(fb.actualLiters!, 'L', locale) : '-', alignRight: true),
                    ],
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );

    final filename = isNepali
        ? 'उपस्थिति_${monthName}_$formattedYear.pdf'
        : 'Attendance_${monthName}_$bsYear.pdf';
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
