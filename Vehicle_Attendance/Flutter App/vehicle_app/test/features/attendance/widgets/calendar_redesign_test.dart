import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/core/theme/app_colors.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/models/monthly_summary.dart';
import 'package:vehicle_app/features/attendance/widgets/calendar_grid.dart';
import 'package:vehicle_app/features/attendance/widgets/day_card.dart';
import 'package:vehicle_app/features/attendance/widgets/day_details_bottom_sheet.dart';
import 'package:vehicle_app/features/attendance/widgets/monthly_summary_card.dart';
import 'package:vehicle_app/l10n/app_localizations.dart';

void main() {
  group('Calendar Redesign DayCard Widget Tests', () {
    testWidgets('Renders unselected day cell with clean styling and without dash placeholder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCard(
              log: const AttendanceLog(
                logDate: '2026-11-05',
                status: AttendanceStatus.present,
                isUnselected: true,
              ),
              dayNumber: 5,
              nepaliDayNumber: '५',
              dateLabel: '5',
              semanticsLabel: 'Kartik 5, Thursday, 5 Nov 2026, Unselected',
              isToday: false,
              isPast: false,
              isFuture: false,
              isMissingStatus: false,
              isMissingKm: false,
              isSaving: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('५'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.byKey(const Key('day_cell_unselected_dash')), findsNothing);
      expect(find.text('—'), findsNothing);
    });

    testWidgets('Renders Present (P) day cell with green pill', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCard(
              log: const AttendanceLog(
                logDate: '2026-11-04',
                status: AttendanceStatus.present,
                isUnselected: false,
              ),
              dayNumber: 4,
              nepaliDayNumber: '४',
              dateLabel: '4',
              semanticsLabel: 'Kartik 4, Wednesday, 4 Nov 2026, Present',
              isToday: false,
              isPast: true,
              isFuture: false,
              isMissingStatus: false,
              isMissingKm: false,
              isSaving: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('day_cell_status_p')), findsOneWidget);
      expect(find.text('P'), findsOneWidget);
    });

    testWidgets('Renders Present with KM entry showing green P pill and no missing badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCard(
              log: const AttendanceLog(
                logDate: '2026-11-04',
                status: AttendanceStatus.present,
                kmStart: 1000,
                kmEnd: 1085,
                kmTotal: 85,
                isUnselected: false,
              ),
              dayNumber: 4,
              nepaliDayNumber: '४',
              dateLabel: '4',
              semanticsLabel: 'Kartik 4, Wednesday, 4 Nov 2026, Present, 85 km',
              isToday: false,
              isPast: true,
              isFuture: false,
              isMissingStatus: false,
              isMissingKm: false,
              isSaving: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('day_cell_status_p')), findsOneWidget);
      expect(find.byKey(const Key('day_cell_warning_badge_km')), findsNothing);
    });

    testWidgets('Renders Holiday (H) day cell with red pill', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCard(
              log: const AttendanceLog(
                logDate: '2026-11-03',
                status: AttendanceStatus.absentHoliday,
                isUnselected: false,
              ),
              dayNumber: 3,
              nepaliDayNumber: '३',
              dateLabel: '3',
              semanticsLabel: 'Kartik 3, Tuesday, 3 Nov 2026, Holiday',
              isToday: false,
              isPast: true,
              isFuture: false,
              isMissingStatus: false,
              isMissingKm: false,
              isSaving: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('day_cell_status_h')), findsOneWidget);
      expect(find.text('H'), findsOneWidget);
    });

    testWidgets('Renders Replacement (R) day cell with orange pill', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCard(
              log: const AttendanceLog(
                logDate: '2026-11-02',
                status: AttendanceStatus.absentReplacement,
                isUnselected: false,
              ),
              dayNumber: 2,
              nepaliDayNumber: '२',
              dateLabel: '2',
              semanticsLabel: 'Kartik 2, Monday, 2 Nov 2026, Replacement',
              isToday: false,
              isPast: true,
              isFuture: false,
              isMissingStatus: false,
              isMissingKm: false,
              isSaving: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('day_cell_status_r')), findsOneWidget);
      expect(find.text('R'), findsOneWidget);
    });

    testWidgets('Renders Today cell with primary colored day chip and ring', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCard(
              log: const AttendanceLog(
                logDate: '2026-11-05',
                status: AttendanceStatus.present,
                isUnselected: true,
              ),
              dayNumber: 5,
              nepaliDayNumber: '५',
              dateLabel: '5',
              semanticsLabel: 'Kartik 5, Thursday, 5 Nov 2026, Today',
              isToday: true,
              isPast: false,
              isFuture: false,
              isMissingStatus: false,
              isMissingKm: false,
              isSaving: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('day_cell_today_chip')), findsOneWidget);
      final chip = tester.widget<Container>(find.byKey(const Key('day_cell_today_chip')));
      final decoration = chip.decoration as BoxDecoration;
      expect(decoration.color, AppColors.primary);
    });

    testWidgets('Renders Future day cell with 50% opacity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCard(
              log: const AttendanceLog(
                logDate: '2026-11-20',
                status: AttendanceStatus.present,
                isUnselected: true,
              ),
              dayNumber: 20,
              nepaliDayNumber: '२०',
              dateLabel: '20',
              semanticsLabel: 'Kartik 20, Friday, 20 Nov 2026, Future',
              isToday: false,
              isPast: false,
              isFuture: true,
              isMissingStatus: false,
              isMissingKm: false,
              isSaving: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('day_cell_future_opacity')), findsOneWidget);
      final opacityWidget = tester.widget<Opacity>(find.byKey(const Key('day_cell_future_opacity')));
      expect(opacityWidget.opacity, 0.5);
    });

    testWidgets('Renders Missing Status with red badge icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCard(
              log: const AttendanceLog(
                logDate: '2026-10-25',
                status: AttendanceStatus.present,
                isUnselected: true,
              ),
              dayNumber: 9,
              nepaliDayNumber: '९',
              dateLabel: '25',
              semanticsLabel: 'Kartik 9, Sunday, 25 Oct 2026, Status missing',
              isToday: false,
              isPast: true,
              isFuture: false,
              isMissingStatus: true,
              isMissingKm: false,
              isSaving: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.warning_amber_rounded);
      expect(iconFinder, findsOneWidget);
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, AppColors.missingStatus);
    });

    testWidgets('Renders Missing KM with amber badge indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCard(
              log: const AttendanceLog(
                logDate: '2026-10-26',
                status: AttendanceStatus.present,
                kmTotal: 0,
                isUnselected: false,
              ),
              dayNumber: 10,
              nepaliDayNumber: '१०',
              dateLabel: '26',
              semanticsLabel: 'Kartik 10, Monday, 26 Oct 2026, KM missing',
              isToday: false,
              isPast: true,
              isFuture: false,
              isMissingStatus: false,
              isMissingKm: true,
              isSaving: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('day_cell_status_p')), findsOneWidget);
      expect(find.byKey(const Key('day_cell_warning_badge_km')), findsOneWidget);
    });
  });

  group('Calendar Grid and Bottom Sheet Integration Tests', () {
    testWidgets('Tapping future day triggers onFutureDateTap and does NOT open sheet', (tester) async {
      bool futureTapped = false;

      final futureLog = AttendanceLog(
        logDate: '2026-12-01',
        status: AttendanceStatus.present,
        isUnselected: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ne'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CalendarGrid(
              bsYear: 2083,
              bsMonthIndex: 7, // Mangsir
              logs: [futureLog],
              savingDates: const {},
              onPreviousMonth: () {},
              onNextMonth: () {},
              onToday: () {},
              onStatusChange: (logDate, status) {},
              onOpenKm: (_) {},
              onFutureDateTap: (date) {
                futureTapped = true;
              },
            ),
          ),
        ),
      ),
    );

      // Tap the first day cell
      await tester.tap(find.byType(DayCard).first);
      await tester.pumpAndSettle();

      expect(futureTapped, isTrue);
      // Ensure bottom sheet is NOT opened
      expect(find.byType(DayDetailsBottomSheet), findsNothing);
    });

    testWidgets('Tapping active status button in sheet triggers delete / unselect', (tester) async {
      String? changedDate;
      AttendanceStatus? changedStatus;

      final selectedLog = const AttendanceLog(
        logDate: '2026-11-04',
        status: AttendanceStatus.present,
        isUnselected: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ne'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DayDetailsBottomSheet(
              dayNumber: 4,
              bsYear: 2083,
              bsMonthIndex: 6,
              log: selectedLog,
              isSaving: false,
              onStatusChange: (date, status) {
                changedDate = date;
                changedStatus = status;
              },
              onOpenKm: (_) {},
            ),
          ),
        ),
      );

      // Tapping already-active 'Present' triggers onStatusChange with AttendanceStatus.present
      // (which AttendanceController handles by toggling delete)
      await tester.tap(find.byKey(const Key('sheet_status_btn_present')));
      await tester.pump();

      expect(changedDate, '2026-11-04');
      expect(changedStatus, AttendanceStatus.present);
    });

    testWidgets('Missing days count chip accurately matches missing cells', (tester) async {
      // Create 30 logs where 2 past days have missing status, 1 past day has missing KM
      final logs = List.generate(30, (i) {
        final day = (i + 1).toString().padLeft(2, '0');
        if (i == 0) {
          // Missing status (past + unselected)
          return AttendanceLog(logDate: '2026-10-$day', status: AttendanceStatus.present, isUnselected: true);
        } else if (i == 1) {
          // Missing status (past + unselected)
          return AttendanceLog(logDate: '2026-10-$day', status: AttendanceStatus.absentHoliday, isUnselected: true);
        } else if (i == 2) {
          // Missing KM (past + present + kmTotal null)
          return AttendanceLog(logDate: '2026-10-$day', status: AttendanceStatus.present, kmTotal: null, isUnselected: false);
        } else {
          // Satisfied past day (present with KM)
          return AttendanceLog(logDate: '2026-10-$day', status: AttendanceStatus.present, kmTotal: 50, isUnselected: false);
        }
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('ne')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: SingleChildScrollView(
              child: CalendarGrid(
                bsYear: 2083,
                bsMonthIndex: 6,
                logs: logs,
                savingDates: const {},
                onPreviousMonth: () {},
                onNextMonth: () {},
                onToday: () {},
                onStatusChange: (logDate, status) {},
                onOpenKm: (_) {},
              ),
            ),
          ),
        ),
      );

      // The summary chip should display localized "3 days need data"
      expect(find.byKey(const Key('calendar_missing_summary_chip')), findsOneWidget);
      expect(find.textContaining('3 days need data'), findsOneWidget);
    });

    testWidgets('CalendarGrid header renders year without commas in English (Kartik 2083)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('ne')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: SingleChildScrollView(
              child: CalendarGrid(
                bsYear: 2083,
                bsMonthIndex: 6, // Kartik
                logs: const [],
                savingDates: const {},
                onPreviousMonth: () {},
                onNextMonth: () {},
                onToday: () {},
                onStatusChange: (logDate, status) {},
                onOpenKm: (_) {},
              ),
            ),
          ),
        ),
      );

      // Must display 'Kartik 2083' without comma
      expect(find.text('Kartik 2083'), findsOneWidget);
      expect(find.text('Kartik 2,083'), findsNothing);
    });

    testWidgets('CalendarGrid header renders year without commas in Nepali (कार्तिक २०८३)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ne'),
          supportedLocales: const [Locale('en'), Locale('ne')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: SingleChildScrollView(
              child: CalendarGrid(
                bsYear: 2083,
                bsMonthIndex: 6, // Kartik
                logs: const [],
                savingDates: const {},
                onPreviousMonth: () {},
                onNextMonth: () {},
                onToday: () {},
                onStatusChange: (logDate, status) {},
                onOpenKm: (_) {},
              ),
            ),
          ),
        ),
      );

      // Must display 'कार्तिक २०८३' without comma
      expect(find.text('कार्तिक २०८३'), findsOneWidget);
      expect(find.text('कार्तिक २,०८३'), findsNothing);
    });

    testWidgets('MonthlySummaryCard renders negative net income in red', (tester) async {
      const negativeSummary = MonthlySummary(
        totalPresentDays: 2,
        totalReplacementDays: 2,
        totalExtraIncome: 0,
        totalKm: 1,
        grossIncome: 2400,
        totalDeductions: 6000,
        netIncome: -3600,
      );

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          supportedLocales: [Locale('en'), Locale('ne')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: MonthlySummaryCard(summary: negativeSummary),
          ),
        ),
      );

      final amountFinder = find.text('−3,600');
      expect(amountFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(amountFinder);
      expect(textWidget.style?.color, AppColors.netIncomeNegativeOnHero);
    });

    testWidgets('MonthlySummaryCard renders positive net income in green', (tester) async {
      const positiveSummary = MonthlySummary(
        totalPresentDays: 3,
        totalReplacementDays: 0,
        totalExtraIncome: 300,
        totalKm: 50,
        grossIncome: 3900,
        totalDeductions: 0,
        netIncome: 3900,
      );

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          supportedLocales: [Locale('en'), Locale('ne')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: MonthlySummaryCard(summary: positiveSummary),
          ),
        ),
      );

      final amountFinder = find.text('3,900');
      expect(amountFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(amountFinder);
      expect(textWidget.style?.color, AppColors.netIncomePositiveOnHero);
    });
  });
}
