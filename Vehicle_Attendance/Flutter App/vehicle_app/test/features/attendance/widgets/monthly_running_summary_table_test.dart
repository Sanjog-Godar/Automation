import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/core/theme/app_theme.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/widgets/monthly_running_summary_table.dart';
import 'package:vehicle_app/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({
    required List<AttendanceLog> logs,
    Locale locale = const Locale('ne'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: MonthlyRunningSummaryTable(
            bsYear: 2083,
            bsMonthIndex: 7, // Kartik
            logs: logs,
          ),
        ),
      ),
    );
  }

  group('MonthlyRunningSummaryTable Widget Tests', () {
    testWidgets('Displays empty state message when no KM is recorded', (tester) async {
      final logs = [
        AttendanceLog(logDate: '2026-10-18', status: AttendanceStatus.present, isUnselected: false),
        AttendanceLog(logDate: '2026-10-19', status: AttendanceStatus.absentHoliday, isUnselected: false),
      ];

      await tester.pumpWidget(buildTestWidget(logs: logs));
      await tester.pumpAndSettle();

      expect(find.text('यस महिना कुनै किलोमिटर रेकर्ड छैन'), findsOneWidget);
      expect(find.text('मिति'), findsOneWidget);
      expect(find.text('सुरु'), findsOneWidget);
      expect(find.text('अन्तिम'), findsOneWidget);
      expect(find.text('जम्मा'), findsOneWidget);
    });

    testWidgets('Displays dual date with Nepali on top and English below', (tester) async {
      final logs = [
        AttendanceLog(
          logDate: '2026-10-27',
          status: AttendanceStatus.present,
          isUnselected: false,
          kmStart: 12345,
          kmEnd: 12350,
          kmTotal: 5,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(logs: logs));
      await tester.pumpAndSettle();

      // Top line Nepali: २०८३ कार्तिक ११
      expect(find.text('२०८३ कार्तिक ११'), findsOneWidget);
      // Bottom line English: 2026 Oct 27
      expect(find.text('2026 Oct 27'), findsOneWidget);

      // Start, End, Total KM
      expect(find.text('१२,३४५'), findsOneWidget);
      expect(find.text('१२,३५०'), findsOneWidget);
      expect(find.text('५ कि.मि.'), findsNWidgets(3)); // header badge, row total, footer total
    });

    testWidgets('Renders in English correctly with dual date preserved', (tester) async {
      final logs = [
        AttendanceLog(
          logDate: '2026-10-27',
          status: AttendanceStatus.present,
          isUnselected: false,
          kmStart: 1000,
          kmEnd: 1050,
          kmTotal: 50,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(logs: logs, locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);

      // Dual date is preserved: Nepali on top, English below
      expect(find.text('२०८३ कार्तिक ११'), findsOneWidget);
      expect(find.text('2026 Oct 27'), findsOneWidget);

      expect(find.text('1,000'), findsOneWidget);
      expect(find.text('1,050'), findsOneWidget);
      expect(find.text('50 km'), findsNWidgets(3));
    });
  });
}

