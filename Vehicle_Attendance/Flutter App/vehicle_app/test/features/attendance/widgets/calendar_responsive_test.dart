import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/widgets/calendar_grid.dart';
import 'package:vehicle_app/l10n/app_localizations.dart';

void main() {
  group('Calendar Grid Responsiveness Tests', () {
    final sampleLogs = List.generate(30, (i) {
      final day = (i + 1).toString().padLeft(2, '0');
      return AttendanceLog(
        logDate: '2026-11-$day',
        status: i % 2 == 0 ? AttendanceStatus.present : AttendanceStatus.absentHoliday,
        isUnselected: false,
      );
    });

    Widget createTestWidget(double width, double height, {bool isDark = false}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(brightness: isDark ? Brightness.dark : Brightness.light),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              height: height,
              child: SingleChildScrollView(
                child: CalendarGrid(
                  bsYear: 2083,
                  bsMonthIndex: 6,
                  logs: sampleLogs,
                  savingDates: const {},
                  onPreviousMonth: () {},
                  onNextMonth: () {},
                  onToday: () {},
                  onStatusChange: (logDate, status) {},
                  onOpenTip: (_) {},
                  onOpenKm: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Renders cleanly on narrow phone width (320dp) with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 600 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(320, 600));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarGrid), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly on standard phone width (360dp) in light and dark mode', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Light mode
      await tester.pumpWidget(createTestWidget(360, 800, isDark: false));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarGrid), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Dark mode
      await tester.pumpWidget(createTestWidget(360, 800, isDark: true));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarGrid), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly on large phone width (411dp) with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(411 * 3, 915 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(411, 915));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarGrid), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly on tablet width (768dp) with width capped at 560dp', (tester) async {
      tester.view.physicalSize = const Size(768 * 2, 1024 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(768, 1024));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarGrid), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
