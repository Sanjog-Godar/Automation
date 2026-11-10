import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/widgets/calendar_grid.dart';
import 'package:vehicle_app/features/attendance/widgets/day_card.dart';
import 'package:vehicle_app/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final fontData = File('assets/fonts/Mukta-SemiBold.ttf').readAsBytesSync();
    final fontLoader = FontLoader('Mukta')..addFont(Future.value(fontData.buffer.asByteData()));
    await fontLoader.load();
  });

  final List<double> targetWidths = [320.0, 360.0, 411.0, 800.0];
  final List<double> textScaleFactors = [1.0, 1.2, 2.0];

  group('Calendar Overflow Regression Tests - DayCard & CalendarGrid', () {
    late List<FlutterErrorDetails> errorDetailsList;
    late void Function(FlutterErrorDetails)? oldHandler;

    setUp(() {
      errorDetailsList = [];
      oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errorDetailsList.add(details);
        // Do not throw so that all states are evaluated and captured
      };
    });

    tearDown(() {
      FlutterError.onError = oldHandler;
    });

    // Test each state on DayCard inside constrained cell
    final states = <String, Map<String, dynamic>>{
      'unselected past': {
        'log': const AttendanceLog(logDate: '2026-11-01', status: AttendanceStatus.present, isUnselected: true),
        'isToday': false,
        'isPast': true,
        'isFuture': false,
        'isMissingStatus': true,
        'isMissingKm': false,
      },
      'unselected today': {
        'log': const AttendanceLog(logDate: '2026-11-05', status: AttendanceStatus.present, isUnselected: true),
        'isToday': true,
        'isPast': false,
        'isFuture': false,
        'isMissingStatus': false,
        'isMissingKm': false,
      },
      'unselected future': {
        'log': const AttendanceLog(logDate: '2026-11-10', status: AttendanceStatus.present, isUnselected: true),
        'isToday': false,
        'isPast': false,
        'isFuture': true,
        'isMissingStatus': false,
        'isMissingKm': false,
      },
      'P': {
        'log': const AttendanceLog(logDate: '2026-11-02', status: AttendanceStatus.present, isUnselected: false, kmTotal: 50),
        'isToday': false,
        'isPast': true,
        'isFuture': false,
        'isMissingStatus': false,
        'isMissingKm': false,
      },
      'H': {
        'log': const AttendanceLog(logDate: '2026-11-03', status: AttendanceStatus.absentHoliday, isUnselected: false),
        'isToday': false,
        'isPast': true,
        'isFuture': false,
        'isMissingStatus': false,
        'isMissingKm': false,
      },
      'R': {
        'log': const AttendanceLog(logDate: '2026-11-04', status: AttendanceStatus.absentReplacement, isUnselected: false),
        'isToday': false,
        'isPast': true,
        'isFuture': false,
        'isMissingStatus': false,
        'isMissingKm': false,
      },
      'missing status': {
        'log': const AttendanceLog(logDate: '2026-11-01', status: AttendanceStatus.present, isUnselected: true),
        'isToday': false,
        'isPast': true,
        'isFuture': false,
        'isMissingStatus': true,
        'isMissingKm': false,
      },
      'missing KM': {
        'log': const AttendanceLog(logDate: '2026-11-02', status: AttendanceStatus.present, isUnselected: false, kmTotal: 0),
        'isToday': false,
        'isPast': true,
        'isFuture': false,
        'isMissingStatus': false,
        'isMissingKm': true,
      },
      'present with KM': {
        'log': const AttendanceLog(logDate: '2026-11-03', status: AttendanceStatus.present, isUnselected: false, kmStart: 100, kmEnd: 200, kmTotal: 100),
        'isToday': false,
        'isPast': true,
        'isFuture': false,
        'isMissingStatus': false,
        'isMissingKm': false,
      },
      'present with extra trip': {
        'log': const AttendanceLog(logDate: '2026-11-04', status: AttendanceStatus.present, isUnselected: false, extraTripIncome: 200, kmTotal: 50),
        'isToday': false,
        'isPast': true,
        'isFuture': false,
        'isMissingStatus': false,
        'isMissingKm': false,
      },
    };

    for (final width in targetWidths) {
      for (final scale in textScaleFactors) {
        testWidgets('No overflow in DayCard for all states at width $width, textScale $scale', (tester) async {
          // Compute cell dimensions using LayoutBuilder cellHeight formula:
          final cardWidth = math.min(width, 560.0) - 32.0; // 16 padding on each side
          final cellWidth = (cardWidth - (6 * 6)) / 7;
          final clampedScale = scale.clamp(1.0, 1.2);
          final baseHeight = math.max(56.0, cellWidth * 0.95);
          final cellHeight = baseHeight * clampedScale;

          for (final entry in states.entries) {
            final stateName = entry.key;
            final config = entry.value;

            await tester.pumpWidget(
              MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 800),
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: Scaffold(
                    body: Center(
                      child: SizedBox(
                        width: cellWidth,
                        height: cellHeight,
                        child: DayCard(
                          log: config['log'] as AttendanceLog,
                          dayNumber: 15,
                          nepaliDayNumber: '१५',
                          dateLabel: '28',
                          semanticsLabel: 'Test $stateName',
                          isToday: config['isToday'] as bool,
                          isPast: config['isPast'] as bool,
                          isFuture: config['isFuture'] as bool,
                          isMissingStatus: config['isMissingStatus'] as bool,
                          isMissingKm: config['isMissingKm'] as bool,
                          isSaving: false,
                          onTap: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );

            // Check for RenderFlex overflow errors
            final overflowErrors = errorDetailsList.where((d) =>
              d.exceptionAsString().contains('overflowed') ||
              d.toString().contains('RenderFlex overflowed')
            ).toList();

            expect(
              overflowErrors,
              isEmpty,
              reason: 'DayCard overflowed in state "$stateName" at width $width, scale $scale:\n'
                  '${overflowErrors.map((e) => e.exceptionAsString()).join("\n")}',
            );
            expect(tester.takeException(), isNull);
          }
        });
      }
    }

    // Full month calendar grid test across all widths and scales
    for (final width in targetWidths) {
      for (final scale in textScaleFactors) {
        testWidgets('No overflow in full CalendarGrid at width $width, textScale $scale', (tester) async {
          // Build a month with a variety of all states
          final logs = List.generate(30, (i) {
            final day = i + 1;
            final dateStr = '2026-11-${day.toString().padLeft(2, '0')}';
            if (day == 5) {
              return AttendanceLog(logDate: dateStr, status: AttendanceStatus.present, isUnselected: false, kmTotal: 50);
            } else if (day == 6) {
              return AttendanceLog(logDate: dateStr, status: AttendanceStatus.absentHoliday, isUnselected: false);
            } else if (day == 7) {
              return AttendanceLog(logDate: dateStr, status: AttendanceStatus.absentReplacement, isUnselected: false);
            } else if (day < 5) {
              // Past days: some missing status, some missing km, some with km
              if (day == 1) return AttendanceLog(logDate: dateStr, status: AttendanceStatus.present, isUnselected: true);
              if (day == 2) return AttendanceLog(logDate: dateStr, status: AttendanceStatus.present, isUnselected: false, kmTotal: 0);
              return AttendanceLog(logDate: dateStr, status: AttendanceStatus.present, isUnselected: false, kmTotal: 80);
            } else {
              // Future days
              return AttendanceLog(logDate: dateStr, status: AttendanceStatus.present, isUnselected: true);
            }
          });

          await tester.binding.setSurfaceSize(Size(width, 900));

          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 900),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: CalendarGrid(
                      bsYear: 2083,
                      bsMonthIndex: 7, // Kartik
                      logs: logs,
                      savingDates: const {},
                      onPreviousMonth: () {},
                      onNextMonth: () {},
                      onToday: () {},
                      onStatusChange: (d, s) {},
                      onOpenKm: (l) {},
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          final overflowErrors = errorDetailsList.where((d) =>
            d.exceptionAsString().contains('overflowed') ||
            d.toString().contains('RenderFlex overflowed')
          ).toList();

          expect(
            overflowErrors,
            isEmpty,
            reason: 'CalendarGrid overflowed at width $width, scale $scale:\n'
                '${overflowErrors.map((e) => e.exceptionAsString()).join("\n")}',
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
