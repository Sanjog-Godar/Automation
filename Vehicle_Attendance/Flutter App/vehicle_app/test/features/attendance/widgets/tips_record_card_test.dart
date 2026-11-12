import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/widgets/tips_record_card.dart';
import 'package:vehicle_app/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget({
    required Widget child,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ne')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('TipsRecordCard Widget Tests', () {
    testWidgets('Returns SizedBox.shrink() when no tip records exist', (tester) async {
      final logs = [
        const AttendanceLog(
          logDate: '2026-11-05',
          status: AttendanceStatus.present,
          extraTripIncome: 0,
          extraTipAmount: 0,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          child: TipsRecordCard(logs: logs),
        ),
      );

      expect(find.byType(TipsRecordCard), findsOneWidget);
      expect(find.text('Tips Record'), findsNothing);
      expect(find.text('टिप रेकर्ड'), findsNothing);
    });

    testWidgets('Renders tip records in English locale matching website layout', (tester) async {
      AttendanceLog? tappedLog;

      final logs = [
        const AttendanceLog(
          logDate: '2026-11-10',
          status: AttendanceStatus.present,
          extraTipAmount: 6000,
          extraTipNote: 'Kushma',
        ),
        const AttendanceLog(
          logDate: '2026-11-12',
          status: AttendanceStatus.present,
          extraTipAmount: 1500,
          extraTipNote: null,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('en'),
          child: TipsRecordCard(
            logs: logs,
            onEditTip: (log) => tappedLog = log,
          ),
        ),
      );

      // Verify title
      expect(find.text('Tips Record'), findsOneWidget);

      // Verify header total badge (6000 + 1500 = 7500)
      expect(find.text('Rs. 7,500'), findsOneWidget);

      // Verify Kushma entry
      expect(find.text('Kushma'), findsOneWidget);
      expect(find.text('(2026-11-10)'), findsOneWidget);
      expect(find.text('Rs. 6,000'), findsOneWidget);

      // Verify entry without note shows fallback
      expect(find.text('No destination'), findsOneWidget);
      expect(find.text('(2026-11-12)'), findsOneWidget);
      expect(find.text('Rs. 1,500'), findsOneWidget);

      // Verify tapping triggers onEditTip
      await tester.tap(find.text('Kushma'));
      await tester.pump();
      expect(tappedLog?.logDate, '2026-11-10');
      expect(tappedLog?.extraTipAmount, 6000);
    });

    testWidgets('Renders tip records in Nepali locale', (tester) async {
      final logs = [
        const AttendanceLog(
          logDate: '2026-11-10',
          status: AttendanceStatus.present,
          extraTipAmount: 6000,
          extraTipNote: 'कुश्मा',
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('ne'),
          child: TipsRecordCard(logs: logs),
        ),
      );

      // Verify title in Nepali
      expect(find.text('टिप रेकर्ड'), findsOneWidget);

      // Verify Nepali currency and note
      expect(find.text('रु. ६,०००'), findsNWidgets(2)); // Total badge + item row
      expect(find.text('कुश्मा'), findsOneWidget);
      expect(find.text('(2026-11-10)'), findsOneWidget);
    });
  });
}

