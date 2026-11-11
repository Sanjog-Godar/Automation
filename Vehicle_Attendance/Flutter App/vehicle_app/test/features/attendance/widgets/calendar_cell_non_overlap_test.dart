import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/widgets/day_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final fontFile = File('assets/fonts/Mukta-SemiBold.ttf');
    if (fontFile.existsSync()) {
      final fontData = fontFile.readAsBytesSync();
      final fontLoader = FontLoader('Mukta')..addFont(Future.value(fontData.buffer.asByteData()));
      await fontLoader.load();
    }
  });

  final targetWidths = [320.0, 360.0, 411.0];
  final textScales = [1.0, 1.2];

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
      'log': const AttendanceLog(logDate: '2026-11-12', status: AttendanceStatus.present, isUnselected: true),
      'isToday': false,
      'isPast': false,
      'isFuture': true,
      'isMissingStatus': false,
      'isMissingKm': false,
    },
    'P (with KM)': {
      'log': const AttendanceLog(logDate: '2026-11-02', status: AttendanceStatus.present, isUnselected: false, kmTotal: 85),
      'isToday': false,
      'isPast': true,
      'isFuture': false,
      'isMissingStatus': false,
      'isMissingKm': false,
    },
    'P (missing KM)': {
      'log': const AttendanceLog(logDate: '2026-11-03', status: AttendanceStatus.present, isUnselected: false, kmTotal: 0),
      'isToday': false,
      'isPast': true,
      'isFuture': false,
      'isMissingStatus': false,
      'isMissingKm': true,
    },
    'H (holiday)': {
      'log': const AttendanceLog(logDate: '2026-11-04', status: AttendanceStatus.absentHoliday, isUnselected: false),
      'isToday': false,
      'isPast': true,
      'isFuture': false,
      'isMissingStatus': false,
      'isMissingKm': false,
    },
    'R (replacement)': {
      'log': const AttendanceLog(logDate: '2026-11-05', status: AttendanceStatus.absentReplacement, isUnselected: false),
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
  };

  group('Calendar Cell Non-Overlap & RenderBox Rect Verification Tests', () {
    for (final width in targetWidths) {
      for (final scale in textScales) {
        testWidgets('Zero overlap among zones at width $width, textScale $scale', (tester) async {
          final cardWidth = math.min(width, 560.0) - 32.0;
          final cellWidth = (cardWidth - (6 * 6)) / 7;
          final clampedScale = scale.clamp(1.0, 1.3);
          final baseHeight = math.max(72.0, cellWidth * 1.15);
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

            // 1. Obtain Devanagari Number Rect
            final devFinder = find.byKey(const Key('day_cell_devanagari_number'));
            expect(devFinder, findsOneWidget, reason: 'Devanagari number must exist in $stateName');
            final devBox = tester.renderObject<RenderBox>(devFinder);
            final devRect = devBox.localToGlobal(Offset.zero) & devBox.size;

            // 2. Obtain AD Day Number Rect
            final adFinder = find.byKey(const Key('day_cell_ad_number'));
            expect(adFinder, findsOneWidget, reason: 'AD number must exist in $stateName');
            final adBox = tester.renderObject<RenderBox>(adFinder);
            final adRect = adBox.localToGlobal(Offset.zero) & adBox.size;

            // Verification: Top row Devanagari and AD numbers NEVER intersect and maintain >= 4.0dp vertical space
            expect(
              devRect.overlaps(adRect),
              isFalse,
              reason: 'Devanagari ($devRect) overlapped AD date ($adRect) in $stateName at width $width, scale $scale',
            );
            final verticalGap = adRect.top - devRect.bottom;
            expect(
              verticalGap >= 4.0,
              isTrue,
              reason: 'Vertical gap ($verticalGap dp) between Devanagari and AD date must be >= 4.0dp in $stateName at width $width, scale $scale',
            );

            // 3. Obtain Pill Rect if present
            Rect? pillRect;
            final pFinder = find.byKey(const Key('day_cell_status_p'));
            final hFinder = find.byKey(const Key('day_cell_status_h'));
            final rFinder = find.byKey(const Key('day_cell_status_r'));
            if (pFinder.evaluate().isNotEmpty) {
              final box = tester.renderObject<RenderBox>(pFinder);
              pillRect = box.localToGlobal(Offset.zero) & box.size;
            } else if (hFinder.evaluate().isNotEmpty) {
              final box = tester.renderObject<RenderBox>(hFinder);
              pillRect = box.localToGlobal(Offset.zero) & box.size;
            } else if (rFinder.evaluate().isNotEmpty) {
              final box = tester.renderObject<RenderBox>(rFinder);
              pillRect = box.localToGlobal(Offset.zero) & box.size;
            }

            if (pillRect != null) {
              expect(
                devRect.overlaps(pillRect),
                isFalse,
                reason: 'Devanagari ($devRect) overlapped status pill ($pillRect) in $stateName at width $width, scale $scale',
              );
              expect(
                adRect.overlaps(pillRect),
                isFalse,
                reason: 'AD date ($adRect) overlapped status pill ($pillRect) in $stateName at width $width, scale $scale',
              );
            }

            // 4. Obtain Warning Badge Rects if present
            final statusBadgeFinder = find.byKey(const Key('day_cell_warning_badge_status'));
            final kmBadgeFinder = find.byKey(const Key('day_cell_warning_badge_km'));

            if (statusBadgeFinder.evaluate().isNotEmpty) {
              final box = tester.renderObject<RenderBox>(statusBadgeFinder);
              final statusBadgeRect = box.localToGlobal(Offset.zero) & box.size;
              // Zone 3 Bottom status badge never overlaps top row numerals
              expect(
                devRect.overlaps(statusBadgeRect),
                isFalse,
                reason: 'Devanagari ($devRect) overlapped status badge ($statusBadgeRect) in $stateName at width $width, scale $scale',
              );
              expect(
                adRect.overlaps(statusBadgeRect),
                isFalse,
                reason: 'AD date ($adRect) overlapped status badge ($statusBadgeRect) in $stateName at width $width, scale $scale',
              );
            }

            if (kmBadgeFinder.evaluate().isNotEmpty) {
              final box = tester.renderObject<RenderBox>(kmBadgeFinder);
              final kmBadgeRect = box.localToGlobal(Offset.zero) & box.size;
              // Top-right corner KM warning icon never overlaps Zone 2 AD date or Zone 3 bottom pill
              expect(
                adRect.overlaps(kmBadgeRect),
                isFalse,
                reason: 'AD date ($adRect) overlapped top-right KM warning badge ($kmBadgeRect) in $stateName at width $width, scale $scale',
              );
              if (pillRect != null) {
                expect(
                  pillRect.overlaps(kmBadgeRect),
                  isFalse,
                  reason: 'P pill ($pillRect) overlapped top-right KM warning badge ($kmBadgeRect) in $stateName at width $width, scale $scale',
                );
                final clearSpace = pillRect.top - kmBadgeRect.bottom;
                expect(
                  clearSpace >= 6.0,
                  isTrue,
                  reason: 'Clear space ($clearSpace dp) between bottom P pill and top-right KM badge must be >= 6.0dp at width $width, scale $scale',
                );
              }
            }

            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  });
}
