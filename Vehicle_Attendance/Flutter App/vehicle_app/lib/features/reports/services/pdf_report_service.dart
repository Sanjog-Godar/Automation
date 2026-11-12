import 'dart:ui' as ui;
import 'dart:ui' show Locale;
import 'package:flutter/material.dart'
    show Color, FontWeight, TextDirection, TextPainter, TextSpan, TextStyle, Canvas, Offset;
import 'package:flutter/services.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../../core/utils/nepali_calendar_helper.dart';
import '../../attendance/models/attendance_log.dart';
import '../../attendance/models/monthly_summary.dart';
import '../../attendance/widgets/extra_trip_dialog.dart';
import '../../fuel_bills/models/fuel_bill.dart';

/// Helper to render Devanagari (Nepali) text with authentic complex script shaping
/// (GSUB conjuncts, halanta / half-letters, reph, and pre-base matras) using Flutter's
/// native HarfBuzz text engine, rasterized to high-density crisp images for package:pdf.
class DevanagariShaper {
  DevanagariShaper._();

  static final Map<String, ({Uint8List bytes, double width, double height})> _cache = {};

  /// Checks if [text] contains any Devanagari code points (U+0900 - U+097F).
  static bool hasDevanagari(String text) {
    for (final r in text.runes) {
      if (r >= 0x0900 && r <= 0x097F) return true;
    }
    return false;
  }

  /// Pre-renders unique Devanagari strings into retina-crisp PNG bytes using Flutter's TextPainter.
  static Future<void> preWarm(
    List<({String text, double fontSize, bool isBold, PdfColor color})> items,
  ) async {
    const double pixelScale = 3.0; // 3x pixel ratio gives 216 DPI (crisp print & zoom quality)
    for (final item in items) {
      if (item.text.isEmpty || !hasDevanagari(item.text)) continue;
      final key = '${item.text}_${item.fontSize}_${item.isBold}_${item.color.toInt()}';
      if (_cache.containsKey(key)) continue;

      try {
        final painter = TextPainter(
          text: TextSpan(
            text: item.text,
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: item.fontSize,
              fontWeight: item.isBold ? FontWeight.bold : FontWeight.normal,
              color: Color(item.color.toInt()),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        painter.layout();

        final displayWidth = painter.width;
        final displayHeight = painter.height;

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.scale(pixelScale, pixelScale);
        painter.paint(canvas, Offset.zero);
        final picture = recorder.endRecording();

        final imgWidth = (displayWidth * pixelScale).ceil().clamp(1, 4000);
        final imgHeight = (displayHeight * pixelScale).ceil().clamp(1, 4000);
        final img = picture.toImageSync(imgWidth, imgHeight);

        final byteData = await img.toByteData(format: ui.ImageByteFormat.png).timeout(
              const Duration(milliseconds: 300),
              onTimeout: () => null,
            );
        if (byteData != null) {
          _cache[key] = (
            bytes: byteData.buffer.asUint8List(),
            width: displayWidth,
            height: displayHeight,
          );
        }
      } catch (_) {
        // Fallback to standard vector pw.Text gracefully
      }
    }
  }

  /// Returns an image-rendered shaped widget if pre-warmed, or standard pw.Text.
  static pw.Widget render(
    String text, {
    double fontSize = 10,
    bool isBold = false,
    PdfColor textColor = PdfColors.black,
    bool alignRight = false,
    bool center = false,
    pw.Alignment? alignment,
  }) {
    if (text.isEmpty) return pw.SizedBox();
    final key = '${text}_${fontSize}_${isBold}_${textColor.toInt()}';
    final entry = _cache[key];
    if (entry != null) {
      final align = alignRight
          ? pw.Alignment.centerRight
          : center
              ? pw.Alignment.center
              : (alignment ?? pw.Alignment.centerLeft);
      return pw.Align(
        alignment: align,
        child: pw.Image(
          pw.MemoryImage(entry.bytes),
          width: entry.width,
          height: entry.height,
        ),
      );
    }

    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: fontSize,
        fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: textColor,
      ),
      textAlign: alignRight
          ? pw.TextAlign.right
          : center
              ? pw.TextAlign.center
              : pw.TextAlign.left,
    );
  }
}

/// Service responsible for generating the official monthly vehicle attendance and settlement PDF.
/// Fully localized in English or Nepali based on the active locale.
class PdfReportService {
  PdfReportService._();

  /// Builds the monthly vehicle attendance and settlement PDF document.
  /// Fully localized in Nepali or English based on the active app language.
  static Future<pw.Document> buildPdfDocument({
    required int bsYear,
    required int bsMonthIndex,
    required List<AttendanceLog> fullMonthLogs,
    List<FuelBill> fuelBills = const [],
    Locale locale = const Locale('ne'),
  }) async {
    final pdf = pw.Document();
    final isNepali = locale.languageCode == 'ne';

    // Load bundled Mukta TTF fonts from assets (supports both Latin and Devanagari)
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

      if (log.effectiveTipAmount > 0) {
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

    final presentSummaryLine = isNepali
        ? 'जम्मा उपस्थित दिनहरू = ${presentDayNums.isNotEmpty ? presentDayNums.join(", ") : noneText} (जम्मा दिनहरू: ${AppFormatters.toDevanagariDigits("${presentDates.length}")})'
        : 'Total Present Days = ${presentDayNums.isNotEmpty ? presentDayNums.join(", ") : noneText} (Total Days: ${presentDates.length})';
    final absentSummaryLine = isNepali
        ? 'बिदा = ${absentDayNums.isNotEmpty ? absentDayNums.join(", ") : noneText} (${AppFormatters.toDevanagariDigits("${absentDates.length}")})'
        : 'Absent = ${absentDayNums.isNotEmpty ? absentDayNums.join(", ") : noneText} (${absentDates.length})';
    final replaceSummaryLine = isNepali
        ? 'सट्टा = ${replaceDayNums.isNotEmpty ? replaceDayNums.join(", ") : noneText} (${AppFormatters.toDevanagariDigits("${replaceDates.length}")})'
        : 'Replace = ${replaceDayNums.isNotEmpty ? replaceDayNums.join(", ") : noneText} (${replaceDates.length})';
    final tipSummaryLine = isNepali
        ? 'अतिरिक्त टिप = ${tipDayNums.isNotEmpty ? tipDayNums.join(", ") : noneText}'
        : 'Extra tips = ${tipDayNums.isNotEmpty ? tipDayNums.join(", ") : noneText}';

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

    // Separate Upaye vs Solo Extra Tips
    int upayeTipIncome = 0;
    int soloTipIncome = 0;
    for (final log in logsUpToToday) {
      final tip = log.effectiveTipAmount;
      if (tip > 0) {
        final parsed = ExtraTripDialog.parseUpayeNote(log.extraTipNote);
        if (parsed.isUpaye) {
          upayeTipIncome += tip;
        } else {
          soloTipIncome += tip;
        }
      }
    }
    // Fallback if logsUpToToday had no individual tip notes but totalExtraIncome was recorded
    if (upayeTipIncome == 0 && soloTipIncome == 0 && summaryUpToToday.totalExtraIncome > 0) {
      upayeTipIncome = summaryUpToToday.totalExtraIncome;
    }

    // TDS Calculation @ 1.5% strictly on totalEarning
    final tdsAmount = (totalEarning * AppConstants.tdsRate).round();
    final totalBeforeTDS = totalEarning + upayeTipIncome;
    final netIncomeAfterTDS = totalBeforeTDS - tdsAmount;
    final totalEarnings = netIncomeAfterTDS + soloTipIncome;

    // 5. Monthly Running KM entries for the selected month
    final kmLogs = fullMonthLogs
        .where((log) => !log.isUnselected && log.kmTotal != null && log.kmTotal! > 0)
        .toList()
      ..sort((a, b) => a.logDate.compareTo(b.logDate));
    final totalMonthKm = kmLogs.fold<int>(0, (sum, item) => sum + (item.kmTotal ?? 0));

    // 6. Extra Tips list for the selected month
    final tipLogs = fullMonthLogs
        .where((log) => !log.isUnselected && log.effectiveTipAmount > 0)
        .toList()
      ..sort((a, b) => a.logDate.compareTo(b.logDate));
    final totalMonthTips = tipLogs.fold<int>(0, (sum, item) => sum + item.effectiveTipAmount);

    // Pre-warm Devanagari text representations to achieve perfect ligatures/conjuncts
    if (isNepali) {
      final preWarmList = <({String text, double fontSize, bool isBold, PdfColor color})>[
        // Header
        (text: 'मासिक विवरण पाना', fontSize: 18.0, isBold: true, color: PdfColors.black),
        (text: monthYearTitle, fontSize: 14.0, isBold: false, color: PdfColors.grey800),
        // Footer
        (text: 'तयार मिति: ${AppFormatters.toDevanagariDigits(NepalClock.todayDateString())}', fontSize: 8.0, isBold: false, color: PdfColors.grey600),
        (text: 'सवारी साधन उपस्थिति प्रणाली', fontSize: 8.0, isBold: false, color: PdfColors.grey600),
        // Date Lists
        (text: presentSummaryLine, fontSize: 9.5, isBold: false, color: PdfColors.black),
        (text: absentSummaryLine, fontSize: 9.5, isBold: false, color: PdfColors.black),
        (text: replaceSummaryLine, fontSize: 9.5, isBold: false, color: PdfColors.black),
        (text: tipSummaryLine, fontSize: 9.5, isBold: false, color: PdfColors.black),
        // Section titles
        (text: 'आम्दानी विवरण', fontSize: 12.0, isBold: true, color: PdfColors.black),
        (text: 'अन्तिम हिसाब मिलान', fontSize: 12.0, isBold: true, color: PdfColors.black),
        (text: 'मासिक गाडी चलेको विवरण', fontSize: 12.0, isBold: true, color: PdfColors.black),
        (text: 'ईन्धन बिल रेकर्ड', fontSize: 12.0, isBold: true, color: PdfColors.black),
        // Table 1 headers
        (text: 'जम्मा दिनहरू', fontSize: 9.0, isBold: true, color: PdfColors.white),
        (text: 'दर (हिसाब)', fontSize: 9.0, isBold: true, color: PdfColors.white),
        (text: 'जम्मा', fontSize: 9.0, isBold: true, color: PdfColors.white),
        // Table 1 rows
        (text: 'उपस्थित दिनहरू', fontSize: 9.0, isBold: false, color: PdfColors.black),
        (text: AppFormatters.toDevanagariDigits('${summaryUpToToday.totalPresentDays}'), fontSize: 9.0, isBold: false, color: PdfColors.black),
        (text: presentFormula, fontSize: 9.0, isBold: false, color: PdfColors.black),
        (text: AppFormatters.formatCurrency(presentIncome, locale), fontSize: 9.0, isBold: false, color: PdfColors.black),
        (text: 'बिदा दिनहरू', fontSize: 9.0, isBold: false, color: PdfColors.black),
        (text: AppFormatters.toDevanagariDigits('$totalHolidayDays'), fontSize: 9.0, isBold: false, color: PdfColors.black),
        (text: 'सट्टा दिनहरू', fontSize: 9.0, isBold: false, color: PdfColors.black),
        (text: AppFormatters.toDevanagariDigits('${summaryUpToToday.totalReplacementDays}'), fontSize: 9.0, isBold: false, color: PdfColors.black),
        (text: replaceFormula, fontSize: 9.0, isBold: false, color: PdfColors.black),
        (text: AppFormatters.formatCurrency(summaryUpToToday.totalDeductions, locale), fontSize: 9.0, isBold: false, color: PdfColors.black),
        (text: 'कुल आम्दानी', fontSize: 9.0, isBold: true, color: PdfColors.black),
        (text: AppFormatters.formatCurrency(totalEarning, locale), fontSize: 9.0, isBold: true, color: PdfColors.black),
        (text: 'उपस्थित दिनको आम्दानीबाट सट्टा दिनको कटौती घटाई गणना गरिएको', fontSize: 8.5, isBold: false, color: PdfColors.grey600),
        // Settlement Box
        (text: 'उपस्थिति आम्दानी:', fontSize: 10.0, isBold: false, color: PdfColors.black),
        (text: 'अतिरिक्त टिप (उपाय):', fontSize: 10.0, isBold: false, color: PdfColors.black),
        (text: 'अतिरिक्त टिप (व्यक्तिगत):', fontSize: 10.0, isBold: false, color: PdfColors.black),
        (text: AppFormatters.formatCurrency(upayeTipIncome, locale), fontSize: 10.0, isBold: false, color: PdfColors.black),
        (text: AppFormatters.formatCurrency(soloTipIncome, locale), fontSize: 10.0, isBold: false, color: PdfColors.black),
        (text: 'कुल जम्मा:', fontSize: 10.0, isBold: true, color: PdfColors.black),
        (text: AppFormatters.formatCurrency(totalBeforeTDS, locale), fontSize: 10.0, isBold: true, color: PdfColors.black),
        (text: 'कट्टी: टीडीएस @ १.५%:', fontSize: 10.0, isBold: true, color: const PdfColor.fromInt(0xFFDC2626)),
        (text: AppFormatters.formatCurrency(tdsAmount, locale), fontSize: 10.0, isBold: true, color: const PdfColor.fromInt(0xFFDC2626)),
        (text: 'खुद आम्दानी (टीडीएस पछि):', fontSize: 10.5, isBold: true, color: PdfColors.black),
        (text: AppFormatters.formatCurrency(netIncomeAfterTDS, locale), fontSize: 10.5, isBold: true, color: PdfColors.black),
        (text: 'खुद आम्दानी (टीडीएस पछि):', fontSize: 13.0, isBold: true, color: const PdfColor.fromInt(0xFF16A34A)),
        (text: AppFormatters.formatCurrency(netIncomeAfterTDS, locale), fontSize: 13.0, isBold: true, color: const PdfColor.fromInt(0xFF16A34A)),
        (text: 'जम्मा कुल आम्दानी:', fontSize: 13.0, isBold: true, color: const PdfColor.fromInt(0xFF16A34A)),
        (text: AppFormatters.formatCurrency(totalEarnings, locale), fontSize: 13.0, isBold: true, color: const PdfColor.fromInt(0xFF16A34A)),
        // Monthly Running Summary Table
        (text: 'मिति (Date)', fontSize: 9.0, isBold: true, color: PdfColors.white),
        (text: 'सुरु (Start)', fontSize: 9.0, isBold: true, color: PdfColors.white),
        (text: 'अन्तिम (End)', fontSize: 9.0, isBold: true, color: PdfColors.white),
        (text: 'जम्मा (Total)', fontSize: 9.0, isBold: true, color: PdfColors.white),
        (text: 'यस महिना कुनै किलोमिटर रेकर्ड छैन', fontSize: 8.5, isBold: false, color: PdfColors.grey600),
        (text: 'महिनाको जम्मा', fontSize: 9.0, isBold: true, color: PdfColors.black),
        (text: AppFormatters.formatUnit(totalMonthKm, 'km', locale), fontSize: 9.0, isBold: true, color: PdfColors.black),
        // Tips Record Table
        (text: 'टिप रेकर्ड', fontSize: 12.0, isBold: true, color: PdfColors.black),
        (text: 'स्थान / विवरण', fontSize: 9.0, isBold: true, color: PdfColors.white),
        (text: 'प्रकार', fontSize: 9.0, isBold: true, color: PdfColors.white),
        (text: 'रकम', fontSize: 9.0, isBold: true, color: PdfColors.white),
        (text: 'उपाय', fontSize: 9.0, isBold: true, color: const PdfColor.fromInt(0xFF2563EB)),
        (text: 'व्यक्तिगत', fontSize: 9.0, isBold: true, color: const PdfColor.fromInt(0xFFD97706)),
        (text: 'महिनाको जम्मा टिप', fontSize: 9.0, isBold: true, color: PdfColors.black),
        (text: AppFormatters.formatCurrency(totalMonthTips, locale), fontSize: 9.0, isBold: true, color: PdfColors.black),
      ];

      for (final item in kmLogs) {
        final adDate = NepalClock.parseDate(item.logDate);
        final nepaliDate = adDate.toNepaliDateTime();
        final bsMonth = NepaliCalendarHelper.nepaliMonths[nepaliDate.month - 1];
        final bsDay = AppFormatters.toDevanagariDigits('${nepaliDate.day}');
        final bsYearNum = AppFormatters.toDevanagariDigits('${nepaliDate.year}');
        final nepaliDateFormatted = '$bsYearNum $bsMonth $bsDay';
        final startKmStr = AppFormatters.formatNumber(item.kmStart ?? 0, locale);
        final endKmStr = AppFormatters.formatNumber(item.kmEnd ?? 0, locale);
        final totalKmStr = AppFormatters.formatUnit(item.kmTotal ?? 0, 'km', locale);

        preWarmList.add((text: nepaliDateFormatted, fontSize: 9.5, isBold: true, color: PdfColors.black));
        preWarmList.add((text: startKmStr, fontSize: 9.0, isBold: false, color: PdfColors.black));
        preWarmList.add((text: endKmStr, fontSize: 9.0, isBold: false, color: PdfColors.black));
        preWarmList.add((text: totalKmStr, fontSize: 9.0, isBold: true, color: PdfColors.black));
      }

      for (final item in tipLogs) {
        final adDate = NepalClock.parseDate(item.logDate);
        final nepaliDate = adDate.toNepaliDateTime();
        final bsMonth = NepaliCalendarHelper.nepaliMonths[nepaliDate.month - 1];
        final bsDay = AppFormatters.toDevanagariDigits('${nepaliDate.day}');
        final bsYearNum = AppFormatters.toDevanagariDigits('${nepaliDate.year}');
        final nepaliDateFormatted = '$bsYearNum $bsMonth $bsDay';

        final parsed = ExtraTripDialog.parseUpayeNote(item.extraTipNote);
        final locationText = parsed.cleanNote.isNotEmpty ? parsed.cleanNote : '-';
        final amountStr = AppFormatters.formatCurrency(item.effectiveTipAmount, locale);

        preWarmList.add((text: nepaliDateFormatted, fontSize: 9.5, isBold: true, color: PdfColors.black));
        if (locationText != '-') {
          preWarmList.add((text: locationText, fontSize: 9.0, isBold: false, color: PdfColors.black));
        }
        preWarmList.add((text: amountStr, fontSize: 9.0, isBold: true, color: PdfColors.black));
      }

      for (final fb in fuelBills) {
        preWarmList.add((text: 'समयावधि', fontSize: 9.0, isBold: true, color: PdfColors.white));
        preWarmList.add((text: 'जम्मा कि.मि.', fontSize: 9.0, isBold: true, color: PdfColors.white));
        preWarmList.add((text: 'अनुमानित', fontSize: 9.0, isBold: true, color: PdfColors.white));
        preWarmList.add((text: 'प्राप्त', fontSize: 9.0, isBold: true, color: PdfColors.white));
        final formattedStart = AppFormatters.toDevanagariDigits(fb.startDate);
        final formattedEnd = AppFormatters.toDevanagariDigits(fb.endDate);
        preWarmList.add((text: '$formattedStart - $formattedEnd', fontSize: 9.0, isBold: false, color: PdfColors.black));
        preWarmList.add((text: AppFormatters.formatUnit(fb.totalKm, 'km', locale), fontSize: 9.0, isBold: false, color: PdfColors.black));
        preWarmList.add((text: AppFormatters.formatUnit(fb.expectedLiters, 'L', locale), fontSize: 9.0, isBold: false, color: PdfColors.black));
        if (fb.actualLiters != null) {
          final isMoreOrEqual = fb.actualLiters! >= fb.expectedLiters;
          final actualColor = isMoreOrEqual
              ? const PdfColor.fromInt(0xFF16A34A)
              : const PdfColor.fromInt(0xFFDC2626);
          preWarmList.add((
            text: AppFormatters.formatUnit(fb.actualLiters!, 'L', locale),
            fontSize: 9.0,
            isBold: true,
            color: actualColor,
          ));
        }
      }

      await DevanagariShaper.preWarm(preWarmList);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        theme: pw.ThemeData.withFont(
          base: ttfRegular,
          bold: ttfBold,
          italic: ttfRegular,
          boldItalic: ttfBold,
        ),
        header: (context) {
          return pw.Column(
            children: [
              pw.Center(
                child: DevanagariShaper.render(
                  isNepali ? 'मासिक विवरण पाना' : 'Monthly Details Sheet',
                  fontSize: 18,
                  isBold: true,
                  center: true,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Center(
                child: DevanagariShaper.render(
                  monthYearTitle,
                  fontSize: 14,
                  textColor: PdfColors.grey800,
                  center: true,
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
              DevanagariShaper.render(
                isNepali
                    ? 'तयार मिति: ${AppFormatters.toDevanagariDigits(NepalClock.todayDateString())}'
                    : 'Generated: ${NepalClock.todayDateString()}',
                fontSize: 8,
                textColor: PdfColors.grey600,
              ),
              DevanagariShaper.render(
                isNepali ? 'सवारी साधन उपस्थिति प्रणाली' : 'Vehicle Attendance System',
                fontSize: 8,
                textColor: PdfColors.grey600,
              ),
              DevanagariShaper.render(
                isNepali ? 'पृष्ठ $pageStr / $pagesTotalStr' : 'Page $pageStr of $pagesTotalStr',
                fontSize: 8,
                textColor: PdfColors.grey600,
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
                DevanagariShaper.render(presentSummaryLine, fontSize: 9.5),
                pw.SizedBox(height: 4),
                DevanagariShaper.render(absentSummaryLine, fontSize: 9.5),
                pw.SizedBox(height: 4),
                DevanagariShaper.render(replaceSummaryLine, fontSize: 9.5),
                pw.SizedBox(height: 4),
                DevanagariShaper.render(tipSummaryLine, fontSize: 9.5),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Earning Sheet Table Header
          DevanagariShaper.render(
            isNepali ? 'आम्दानी विवरण' : 'Earning Sheet',
            fontSize: 12,
            isBold: true,
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
                  _tableCell(isNepali ? 'दर (हिसाब)' : 'Earning', isHeader: true, textColor: PdfColors.white),
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
                  _tableCell(isNepali ? 'कुल आम्दानी' : 'Total Earning', isBold: true),
                  _tableCell(AppFormatters.formatCurrency(totalEarning, locale), isBold: true, alignRight: true),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          DevanagariShaper.render(
            isNepali
                ? 'उपस्थित दिनको आम्दानीबाट सट्टा दिनको कटौती घटाई गणना गरिएको'
                : 'Calculated by earning from total present days - Replace Days',
            fontSize: 8.5,
            textColor: PdfColors.grey600,
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
                DevanagariShaper.render(
                  isNepali ? 'अन्तिम हिसाब मिलान' : 'Final Settlement',
                  fontSize: 12,
                  isBold: true,
                ),
                pw.SizedBox(height: 8),
                _summaryRow(
                  isNepali ? 'उपस्थिति आम्दानी:' : 'Total Earning (from attendance):',
                  AppFormatters.formatCurrency(totalEarning, locale),
                ),
                if (upayeTipIncome > 0)
                  _summaryRow(
                    isNepali ? 'अतिरिक्त टिप (उपाय):' : 'Extra Tip Income (Upaye):',
                    AppFormatters.formatCurrency(upayeTipIncome, locale),
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
                  textColor: soloTipIncome > 0 ? PdfColors.black : const PdfColor.fromInt(0xFF16A34A),
                  isBold: true,
                  fontSize: soloTipIncome > 0 ? 10.5 : 13,
                ),
                if (soloTipIncome > 0) ...[
                  pw.SizedBox(height: 4),
                  _summaryRow(
                    isNepali ? 'अतिरिक्त टिप (व्यक्तिगत):' : 'Extra Tip (Solo):',
                    AppFormatters.formatCurrency(soloTipIncome, locale),
                  ),
                  pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                  pw.SizedBox(height: 4),
                  _summaryRow(
                    isNepali ? 'जम्मा कुल आम्दानी:' : 'Total Earnings:',
                    AppFormatters.formatCurrency(totalEarnings, locale),
                    textColor: const PdfColor.fromInt(0xFF16A34A),
                    isBold: true,
                    fontSize: 13,
                  ),
                ],
              ],
            ),
          ),

          // Monthly Running Summary Table
          pw.SizedBox(height: 16),
          DevanagariShaper.render(
            isNepali ? 'मासिक गाडी चलेको विवरण' : 'Monthly Running Summary',
            fontSize: 12,
            isBold: true,
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(4.5),
              1: pw.FlexColumnWidth(2.5),
              2: pw.FlexColumnWidth(2.5),
              3: pw.FlexColumnWidth(2.5),
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2563EB)),
                children: [
                  _tableCell(isNepali ? 'मिति (Date)' : 'Date', isHeader: true, textColor: PdfColors.white),
                  _tableCell(isNepali ? 'सुरु (Start)' : 'Start', isHeader: true, textColor: PdfColors.white, center: true),
                  _tableCell(isNepali ? 'अन्तिम (End)' : 'End', isHeader: true, textColor: PdfColors.white, center: true),
                  _tableCell(isNepali ? 'जम्मा (Total)' : 'Total', isHeader: true, textColor: PdfColors.white, alignRight: true),
                ],
              ),
              if (kmLogs.isEmpty)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: DevanagariShaper.render(
                        isNepali ? 'यस महिना कुनै किलोमिटर रेकर्ड छैन' : 'No odometer records for this month',
                        fontSize: 8.5,
                        textColor: PdfColors.grey600,
                      ),
                    ),
                    _tableCell('-'),
                    _tableCell('-'),
                    _tableCell('-', alignRight: true),
                  ],
                )
              else ...[
                ...kmLogs.map((item) {
                  final adDate = NepalClock.parseDate(item.logDate);
                  final nepaliDate = adDate.toNepaliDateTime();

                  final bsMonth = NepaliCalendarHelper.nepaliMonths[nepaliDate.month - 1];
                  final bsDay = isNepali
                      ? AppFormatters.toDevanagariDigits('${nepaliDate.day}')
                      : NepaliCalendarHelper.toNepaliNumber(nepaliDate.day);
                  final bsYearNum = isNepali
                      ? AppFormatters.toDevanagariDigits('${nepaliDate.year}')
                      : NepaliCalendarHelper.toNepaliNumber(nepaliDate.year);
                  final nepaliDateFormatted = '$bsYearNum $bsMonth $bsDay';

                  const adMonthNamesShort = [
                    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                  ];
                  final adMonth = adMonthNamesShort[adDate.month - 1];
                  final englishDateFormatted = '${adDate.year} $adMonth ${adDate.day}';

                  final startKmStr = AppFormatters.formatNumber(item.kmStart ?? 0, locale);
                  final endKmStr = AppFormatters.formatNumber(item.kmEnd ?? 0, locale);
                  final totalKmStr = AppFormatters.formatUnit(item.kmTotal ?? 0, 'km', locale);

                  return pw.TableRow(
                    children: [
                      // Dual date: Nepali Bikram Sambat date on top (bold), English Gregorian below
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            DevanagariShaper.render(
                              nepaliDateFormatted,
                              fontSize: 9.5,
                              isBold: true,
                              textColor: PdfColors.black,
                            ),
                            pw.SizedBox(height: 1.5),
                            pw.Text(
                              englishDateFormatted,
                              style: const pw.TextStyle(
                                fontSize: 7.5,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _tableCell(startKmStr, center: true),
                      _tableCell(endKmStr, center: true),
                      _tableCell(totalKmStr, isBold: true, alignRight: true),
                    ],
                  );
                }),
                // Month Total Footer
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFF6FF)),
                  children: [
                    _tableCell(isNepali ? 'महिनाको जम्मा' : 'Month Total', isBold: true),
                    _tableCell(''),
                    _tableCell(''),
                    _tableCell(
                      AppFormatters.formatUnit(totalMonthKm, 'km', locale),
                      isBold: true,
                      alignRight: true,
                    ),
                  ],
                ),
              ],
            ],
          ),

          // Tips Record Table
          if (tipLogs.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            DevanagariShaper.render(
              isNepali ? 'टिप रेकर्ड' : 'Tips Record',
              fontSize: 12,
              isBold: true,
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(3.5),
                1: pw.FlexColumnWidth(3.5),
                2: pw.FlexColumnWidth(2.0),
                3: pw.FlexColumnWidth(2.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2563EB)),
                  children: [
                    _tableCell(isNepali ? 'मिति (Date)' : 'Date', isHeader: true, textColor: PdfColors.white),
                    _tableCell(isNepali ? 'स्थान / विवरण' : 'Location / Note', isHeader: true, textColor: PdfColors.white),
                    _tableCell(isNepali ? 'प्रकार' : 'Type', isHeader: true, textColor: PdfColors.white, center: true),
                    _tableCell(isNepali ? 'रकम' : 'Amount', isHeader: true, textColor: PdfColors.white, alignRight: true),
                  ],
                ),
                ...tipLogs.map((item) {
                  final adDate = NepalClock.parseDate(item.logDate);
                  final nepaliDate = adDate.toNepaliDateTime();
                  final bsMonth = NepaliCalendarHelper.nepaliMonths[nepaliDate.month - 1];
                  final bsDay = isNepali
                      ? AppFormatters.toDevanagariDigits('${nepaliDate.day}')
                      : NepaliCalendarHelper.toNepaliNumber(nepaliDate.day);
                  final bsYearNum = isNepali
                      ? AppFormatters.toDevanagariDigits('${nepaliDate.year}')
                      : NepaliCalendarHelper.toNepaliNumber(nepaliDate.year);
                  final nepaliDateFormatted = '$bsYearNum $bsMonth $bsDay';

                  const adMonthNamesShort = [
                    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                  ];
                  final adMonth = adMonthNamesShort[adDate.month - 1];
                  final englishDateFormatted = '${adDate.year} $adMonth ${adDate.day}';

                  final parsed = ExtraTripDialog.parseUpayeNote(item.extraTipNote);
                  final locationText = parsed.cleanNote.isNotEmpty ? parsed.cleanNote : '-';
                  final typeText = parsed.isUpaye
                      ? (isNepali ? 'उपाय' : 'Upaye')
                      : (isNepali ? 'व्यक्तिगत' : 'Solo');
                  final amountStr = AppFormatters.formatCurrency(item.effectiveTipAmount, locale);

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            DevanagariShaper.render(
                              nepaliDateFormatted,
                              fontSize: 9.5,
                              isBold: true,
                              textColor: PdfColors.black,
                            ),
                            pw.SizedBox(height: 1.5),
                            pw.Text(
                              englishDateFormatted,
                              style: const pw.TextStyle(
                                fontSize: 7.5,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _tableCell(locationText),
                      _tableCell(
                        typeText,
                        center: true,
                        isBold: true,
                        textColor: parsed.isUpaye
                            ? const PdfColor.fromInt(0xFF2563EB)
                            : const PdfColor.fromInt(0xFFD97706),
                      ),
                      _tableCell(amountStr, isBold: true, alignRight: true),
                    ],
                  );
                }),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFF6FF)),
                  children: [
                    _tableCell(isNepali ? 'महिनाको जम्मा टिप' : 'Month Total Tips', isBold: true),
                    _tableCell(''),
                    _tableCell(''),
                    _tableCell(
                      AppFormatters.formatCurrency(totalMonthTips, locale),
                      isBold: true,
                      alignRight: true,
                    ),
                  ],
                ),
              ],
            ),
          ],

          // Fuel Bill Summary if available
          if (fuelBills.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            DevanagariShaper.render(
              isNepali ? 'ईन्धन बिल रेकर्ड' : 'Fuel Bill Records',
              fontSize: 12,
              isBold: true,
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
                  final hasActual = fb.actualLiters != null;
                  final isMoreOrEqual = hasActual && fb.actualLiters! >= fb.expectedLiters;
                  final actualColor = !hasActual
                      ? PdfColors.black
                      : isMoreOrEqual
                          ? const PdfColor.fromInt(0xFF16A34A)
                          : const PdfColor.fromInt(0xFFDC2626);

                  return pw.TableRow(
                    children: [
                      _tableCell('$formattedStart - $formattedEnd'),
                      _tableCell(AppFormatters.formatUnit(fb.totalKm, 'km', locale), alignRight: true),
                      _tableCell(AppFormatters.formatUnit(fb.expectedLiters, 'L', locale), alignRight: true),
                      _tableCell(
                        hasActual ? AppFormatters.formatUnit(fb.actualLiters!, 'L', locale) : '-',
                        alignRight: true,
                        isBold: hasActual,
                        textColor: actualColor,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );

    return pdf;
  }

  /// Generates and previews/prints/downloads the monthly PDF report.
  static Future<void> generateAndDownloadReport({
    required int bsYear,
    required int bsMonthIndex,
    required List<AttendanceLog> fullMonthLogs,
    List<FuelBill> fuelBills = const [],
    Locale locale = const Locale('ne'),
  }) async {
    final pdf = await buildPdfDocument(
      bsYear: bsYear,
      bsMonthIndex: bsMonthIndex,
      fullMonthLogs: fullMonthLogs,
      fuelBills: fuelBills,
      locale: locale,
    );

    final isNepali = locale.languageCode == 'ne';
    final monthName = AppFormatters.bsMonthName(bsMonthIndex, locale);
    final formattedYear = isNepali ? AppFormatters.toDevanagariDigits('$bsYear') : '$bsYear';
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
    final effectiveColor = textColor ?? (isHeader ? PdfColors.white : PdfColors.black);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: DevanagariShaper.render(
        text,
        fontSize: 9,
        isBold: isHeader || isBold,
        textColor: effectiveColor,
        alignRight: alignRight,
        center: center,
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
          DevanagariShaper.render(
            label,
            fontSize: fontSize,
            isBold: isBold,
            textColor: PdfColors.black,
          ),
          DevanagariShaper.render(
            value,
            fontSize: fontSize,
            isBold: isBold,
            textColor: textColor ?? PdfColors.black,
            alignRight: true,
          ),
        ],
      ),
    );
  }
}
