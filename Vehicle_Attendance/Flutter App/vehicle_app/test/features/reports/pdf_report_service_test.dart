import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/fuel_bills/models/fuel_bill.dart';
import 'package:vehicle_app/features/reports/services/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfReportService Tests', () {
    testWidgets('buildPdfDocument builds valid PDF in Nepali without errors', (tester) async {
      await tester.runAsync(() async {
        final sampleLogs = [
          AttendanceLog(
            logDate: '2026-10-18',
            status: AttendanceStatus.present,
            isUnselected: false,
            kmStart: 100,
            kmEnd: 150,
            kmTotal: 50,
          ),
          AttendanceLog(
            logDate: '2026-10-19',
            status: AttendanceStatus.absentReplacement,
            isUnselected: false,
          ),
          AttendanceLog(
            logDate: '2026-10-20',
            status: AttendanceStatus.absentHoliday,
            isUnselected: false,
          ),
        ];

        const sampleFuelBills = [
          FuelBill(
            id: 1,
            startDate: '2026-02-01',
            endDate: '2026-02-12',
            totalKm: 500,
            expectedLiters: 50.0,
            actualLiters: 52,
          ),
        ];

        final doc = await PdfReportService.buildPdfDocument(
          bsYear: 2083,
          bsMonthIndex: 7,
          fullMonthLogs: sampleLogs,
          fuelBills: sampleFuelBills,
          locale: const Locale('ne'),
        );

        final bytes = await doc.save();
        expect(bytes, isNotEmpty);
      });
    });

    testWidgets('toImageSync and TextPainter creates valid PNG bytes for Devanagari', (tester) async {
      final strings = [
        'मासिक विवरण पाना',
        'कार्तिक २०८३',
        'जम्मा उपस्थित दिनहरू',
        'बिदा दिनहरू',
        'सट्टा दिनहरू',
        'कुल आम्दानी',
        'अन्तिम हिसाब मिलान',
        'रु. २,४००',
        'रु. ३६',
        'रु. २,३६४',
        'मासिक गाडी चलेको विवरण',
        'ईन्धन बिल रेकर्ड',
      ];
      final stopwatch = Stopwatch()..start();
      for (final s in strings) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final painter = TextPainter(
          text: TextSpan(
            text: s,
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
          textDirection: TextDirection.ltr,
        );
        painter.layout();
        painter.paint(canvas, Offset.zero);
        final picture = recorder.endRecording();
        final img = picture.toImageSync(painter.width.ceil().clamp(1, 1000), painter.height.ceil().clamp(1, 1000));
        final byteData = await tester.runAsync(() => img.toByteData(format: ui.ImageByteFormat.png));
        expect(byteData, isNotNull);
      }
      stopwatch.stop();
      // print('Rendered ${strings.length} strings in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('buildPdfDocument builds valid PDF when no KM logs exist (empty table state)', (tester) async {
      await tester.runAsync(() async {
        final sampleLogs = [
          AttendanceLog(
            logDate: '2026-10-18',
            status: AttendanceStatus.present,
            isUnselected: false,
          ),
        ];

        final doc = await PdfReportService.buildPdfDocument(
          bsYear: 2083,
          bsMonthIndex: 7,
          fullMonthLogs: sampleLogs,
          fuelBills: const [],
          locale: const Locale('ne'),
        );

        final bytes = await doc.save();
        expect(bytes, isNotEmpty);
      });
    });

    testWidgets('buildPdfDocument builds valid PDF with Upaye and Solo Extra Tips in Nepali and English', (tester) async {
      await tester.runAsync(() async {
        final sampleLogs = [
          AttendanceLog(
            logDate: '2026-10-18',
            status: AttendanceStatus.present,
            isUnselected: false,
            extraTipAmount: 6000,
            extraTipNote: 'Upaye - Kushma',
            kmStart: 100,
            kmEnd: 150,
            kmTotal: 50,
          ),
          AttendanceLog(
            logDate: '2026-10-19',
            status: AttendanceStatus.present,
            isUnselected: false,
            extraTipAmount: 1500,
            extraTipNote: 'Pokhara Solo Return',
            kmStart: 150,
            kmEnd: 200,
            kmTotal: 50,
          ),
          AttendanceLog(
            logDate: '2026-10-20',
            status: AttendanceStatus.absentReplacement,
            isUnselected: false,
          ),
        ];

        // 1. Nepali Locale
        final docNe = await PdfReportService.buildPdfDocument(
          bsYear: 2083,
          bsMonthIndex: 7,
          fullMonthLogs: sampleLogs,
          locale: const Locale('ne'),
        );
        final bytesNe = await docNe.save();
        expect(bytesNe, isNotEmpty);

        // 2. English Locale
        final docEn = await PdfReportService.buildPdfDocument(
          bsYear: 2083,
          bsMonthIndex: 7,
          fullMonthLogs: sampleLogs,
          locale: const Locale('en'),
        );
        final bytesEn = await docEn.save();
        expect(bytesEn, isNotEmpty);
      });
    });
  });
}
