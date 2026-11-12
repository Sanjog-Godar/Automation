import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/widgets/extra_trip_dialog.dart';
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
      home: Scaffold(body: child),
    );
  }

  group('AttendanceLog Extra Tip Serialization Tests', () {
    test('AttendanceLog parses extra_tip_amount and extra_tip_note from JSON correctly', () {
      final json = {
        'log_date': '2026-11-05',
        'status': 'present',
        'extra_trip_income': 500,
        'extra_tip_amount': 500,
        'extra_tip_note': 'Upaye - Kushma',
        'km_start': 100,
        'km_end': 150,
        'km_total': 50,
      };

      final log = AttendanceLog.fromJson(json);
      expect(log.logDate, '2026-11-05');
      expect(log.status, AttendanceStatus.present);
      expect(log.extraTipAmount, 500);
      expect(log.extraTipNote, 'Upaye - Kushma');
      expect(log.effectiveTipAmount, 500);
      expect(log.extraTripIncome, 500);

      final outputJson = log.toJson();
      expect(outputJson['extra_tip_amount'], 500);
      expect(outputJson['extra_tip_note'], 'Upaye - Kushma');
      expect(outputJson['extra_trip_income'], 500);
    });

    test('AttendanceLog falls back to extra_trip_income when extra_tip_amount is missing', () {
      final json = {
        'log_date': '2026-11-06',
        'status': 'present',
        'extra_trip_income': 350,
      };

      final log = AttendanceLog.fromJson(json);
      expect(log.extraTripIncome, 350);
      expect(log.extraTipAmount, 350);
      expect(log.effectiveTipAmount, 350);
      expect(log.extraTipNote, isNull);
    });
  });

  group('Upaye Note Parser and Formatter Tests', () {
    test('parseUpayeNote correctly extracts toggle and clean note', () {
      final p1 = ExtraTripDialog.parseUpayeNote('Upaye - Kushma');
      expect(p1.isUpaye, isTrue);
      expect(p1.cleanNote, 'Kushma');

      final p2 = ExtraTripDialog.parseUpayeNote('Upaye');
      expect(p2.isUpaye, isTrue);
      expect(p2.cleanNote, '');

      final p3 = ExtraTripDialog.parseUpayeNote('उपाय - कुश्मा');
      expect(p3.isUpaye, isTrue);
      expect(p3.cleanNote, 'कुश्मा');

      final p4 = ExtraTripDialog.parseUpayeNote('Special market trip');
      expect(p4.isUpaye, isFalse);
      expect(p4.cleanNote, 'Special market trip');
    });

    test('formatUpayeNote correctly builds database string', () {
      final f1 = ExtraTripDialog.formatUpayeNote(isUpaye: true, note: 'Kushma', isNepali: false);
      expect(f1, 'Upaye - Kushma');

      final f2 = ExtraTripDialog.formatUpayeNote(isUpaye: true, note: '', isNepali: false);
      expect(f2, 'Upaye');

      final f3 = ExtraTripDialog.formatUpayeNote(isUpaye: true, note: 'कुश्मा', isNepali: true);
      expect(f3, 'उपाय - कुश्मा');

      final f4 = ExtraTripDialog.formatUpayeNote(isUpaye: false, note: 'Kushma', isNepali: false);
      expect(f4, 'Kushma');
    });
  });

  group('ExtraTipDialog Widget Tests', () {
    testWidgets('Renders Upaye toggle and saves note with Upaye prefix when enabled', (tester) async {
      int? savedAmount;
      String? savedNote;

      const log = AttendanceLog(
        logDate: '2026-11-05',
        status: AttendanceStatus.present,
        extraTipAmount: 500,
        extraTipNote: null,
      );

      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('en'),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                ExtraTipDialog.show(
                  context: context,
                  log: log,
                  dateTitle: '2026-11-05',
                  onSaveTip: (amount, note) {
                    savedAmount = amount;
                    savedNote = note;
                  },
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify "Upaye Ho ?" text and switch present
      expect(find.text('Upaye Ho ?'), findsOneWidget);
      expect(find.byKey(const Key('upaye_toggle_switch')), findsOneWidget);

      // Toggle Upaye ON
      await tester.tap(find.text('Upaye Ho ?'));
      await tester.pumpAndSettle();

      // Enter location and amount
      await tester.enterText(find.byType(TextField).first, 'Kushma');
      await tester.enterText(find.byType(TextField).last, '6000');

      // Click save tip
      await tester.tap(find.text('Save tip'));
      await tester.pumpAndSettle();

      expect(savedAmount, 6000);
      expect(savedNote, 'Upaye - Kushma');
    });

    testWidgets('Pre-populates Upaye toggle as ON when existing note has Upaye', (tester) async {
      const log = AttendanceLog(
        logDate: '2026-11-10',
        status: AttendanceStatus.present,
        extraTipAmount: 6000,
        extraTipNote: 'Upaye - Kushma',
      );

      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('en'),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                ExtraTipDialog.show(
                  context: context,
                  log: log,
                  dateTitle: '2026-11-10',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Switch should be ON and text field should contain "Kushma"
      final switchWidget = tester.widget<Switch>(find.byKey(const Key('upaye_toggle_switch')));
      expect(switchWidget.value, isTrue);
      expect(find.text('Kushma'), findsOneWidget);
    });

    testWidgets('Renders in Nepali localized text with उपाय हो ?', (tester) async {
      int? savedAmount;
      String? savedNote;

      const log = AttendanceLog(
        logDate: '2026-11-05',
        status: AttendanceStatus.present,
      );

      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('ne'),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                ExtraTipDialog.show(
                  context: context,
                  log: log,
                  dateTitle: '२०८३-०७-२०',
                  onSaveTip: (amount, note) {
                    savedAmount = amount;
                    savedNote = note;
                  },
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('अतिरिक्त टिप विवरण'), findsOneWidget);
      expect(find.text('उपाय हो ?'), findsOneWidget);

      // Toggle Upaye ON in Nepali
      await tester.tap(find.text('उपाय हो ?'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'कुश्मा');
      await tester.enterText(find.byType(TextField).last, '6000');
      await tester.tap(find.text('टिप सुरक्षित गर्नुहोस्'));
      await tester.pumpAndSettle();

      expect(savedAmount, 6000);
      expect(savedNote, 'उपाय - कुश्मा');
    });
  });
}
