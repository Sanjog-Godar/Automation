import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/core/utils/nepali_calendar_helper.dart';

void main() {
  group('Nepali Calendar Golden Tests against web nepali-date-converter', () {
    late List<dynamic> goldenData;

    setUpAll(() {
      final file = File('test/fixtures/nepali_golden.json');
      expect(file.existsSync(), isTrue, reason: 'Golden fixture must exist');
      final jsonStr = file.readAsStringSync();
      goldenData = jsonDecode(jsonStr) as List<dynamic>;
      expect(goldenData.length, 60, reason: 'Fixture must contain exactly 60 months (BS 2080-2084)');
    });

    test('All 60 months (BS 2080-2084) match web reference day counts and AD ranges with 0 mismatches', () {
      int matchedMonths = 0;
      for (final raw in goldenData) {
        final item = raw as Map<String, dynamic>;
        final year = item['year'] as int;
        final monthIndex = item['monthIndex'] as int; // 0-11
        final expectedDays = item['daysInMonth'] as int;
        final expectedStartAD = item['startDateAD'] as String;
        final expectedEndAD = item['endDateAD'] as String;
        final expectedStartDayOfWeek = item['startDayOfWeek'] as int;

        final actualDays = NepaliCalendarHelper.getDaysInMonth(year, monthIndex);
        expect(
          actualDays,
          expectedDays,
          reason: 'Mismatch in days count for BS $year Month ${monthIndex + 1}',
        );

        final startDt = NepaliCalendarHelper.toGregorian(year, monthIndex, 1);
        final startADStr = NepaliCalendarHelper.formatDate(startDt);
        expect(
          startADStr,
          expectedStartAD,
          reason: 'Mismatch in start AD date for BS $year Month ${monthIndex + 1}',
        );

        final endDt = NepaliCalendarHelper.toGregorian(year, monthIndex, actualDays);
        final endADStr = NepaliCalendarHelper.formatDate(endDt);
        expect(
          endADStr,
          expectedEndAD,
          reason: 'Mismatch in end AD date for BS $year Month ${monthIndex + 1}',
        );

        // Day of week in Dart: Monday=1, Sunday=7. In JS: Sunday=0, Monday=1, Saturday=6.
        final jsWeekday = startDt.weekday % 7;
        expect(
          jsWeekday,
          expectedStartDayOfWeek,
          reason: 'Mismatch in start day-of-week for BS $year Month ${monthIndex + 1}',
        );

        matchedMonths++;
      }

      expect(matchedMonths, 60);
    });

    test('toNepaliNumber converts English digits to Devanagari numerals accurately', () {
      expect(NepaliCalendarHelper.toNepaliNumber(0), '०');
      expect(NepaliCalendarHelper.toNepaliNumber(1), '१');
      expect(NepaliCalendarHelper.toNepaliNumber(2082), '२०८२');
      expect(NepaliCalendarHelper.toNepaliNumber(1200), '१२००');
      expect(NepaliCalendarHelper.toNepaliNumber(3000), '३०००');
    });

    test('getSpannedGregorianMonths identifies multi-month cross-AD intervals', () {
      // For Magh 2082: spans Jan 2026 to Feb 2026
      final spanned = NepaliCalendarHelper.getSpannedGregorianMonths(2082, 9); // Magh is index 9
      expect(spanned.length, 2);
      expect(spanned, containsAll(['2026-01', '2026-02']));
    });

    test('previousMonth and nextMonth navigate year boundaries correctly', () {
      // Prev from Baisakh 2082 -> Chaitra 2081
      final prev = NepaliCalendarHelper.previousMonth(2082, 0);
      expect(prev.year, 2081);
      expect(prev.monthIndex, 11);

      // Next from Chaitra 2082 -> Baisakh 2083
      final next = NepaliCalendarHelper.nextMonth(2082, 11);
      expect(next.year, 2083);
      expect(next.monthIndex, 0);
    });
  });
}
