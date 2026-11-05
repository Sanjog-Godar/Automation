import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/core/utils/nepal_clock.dart';
import 'package:vehicle_app/core/utils/nepali_calendar_helper.dart';

void main() {
  group('NepalClock Tests', () {
    tearDown(() {
      NepalClock.reset();
    });

    test('18:14 UTC and 18:15 UTC on the same day produce different NPT dates', () {
      // 2026-01-15 18:14:00 UTC + 5h45m = 2026-01-15 23:59:00 NPT (Still Jan 15 in Nepal)
      NepalClock.utcNow = () => DateTime.utc(2026, 1, 15, 18, 14, 0);
      final npt1 = NepalClock.now();
      expect(npt1.year, 2026);
      expect(npt1.month, 1);
      expect(npt1.day, 15);
      expect(npt1.hour, 23);
      expect(npt1.minute, 59);
      expect(NepalClock.todayDateString(), '2026-01-15');

      // 2026-01-15 18:15:00 UTC + 5h45m = 2026-01-16 00:00:00 NPT (Next day Jan 16 in Nepal!)
      NepalClock.utcNow = () => DateTime.utc(2026, 1, 15, 18, 15, 0);
      final npt2 = NepalClock.now();
      expect(npt2.year, 2026);
      expect(npt2.month, 1);
      expect(npt2.day, 16);
      expect(npt2.hour, 0);
      expect(npt2.minute, 0);
      expect(NepalClock.todayDateString(), '2026-01-16');

      // Verify they are different NPT dates
      expect(npt1.day != npt2.day, isTrue);
    });

    test('UTC instant just before and after NPT midnight behaves accurately', () {
      // 1 ms before midnight
      NepalClock.utcNow = () => DateTime.utc(2026, 1, 15, 18, 14, 59, 999);
      expect(NepalClock.now().day, 15);
      expect(NepalClock.todayDateString(), '2026-01-15');

      // At midnight
      NepalClock.utcNow = () => DateTime.utc(2026, 1, 15, 18, 15, 0, 0);
      expect(NepalClock.now().day, 16);
      expect(NepalClock.todayDateString(), '2026-01-16');
    });

    test('isToday, isFuture, and isPast evaluate accurately across NPT midnight boundary', () {
      // Before midnight boundary (NPT Date is 2026-01-15)
      NepalClock.utcNow = () => DateTime.utc(2026, 1, 15, 18, 14, 0);
      expect(NepalClock.isToday('2026-01-15'), isTrue);
      expect(NepalClock.isFuture('2026-01-16'), isTrue);
      expect(NepalClock.isPast('2026-01-14'), isTrue);
      expect(NepalClock.isPast('2026-01-15'), isFalse);
      expect(NepalClock.isFuture('2026-01-15'), isFalse);

      // After midnight boundary (NPT Date transitions to 2026-01-16)
      NepalClock.utcNow = () => DateTime.utc(2026, 1, 15, 18, 15, 0);
      expect(NepalClock.isToday('2026-01-16'), isTrue);
      expect(NepalClock.isPast('2026-01-15'), isTrue); // Jan 15 is now in the past!
      expect(NepalClock.isFuture('2026-01-15'), isFalse);
      expect(NepalClock.isFuture('2026-01-17'), isTrue);
      expect(NepalClock.isPast('2026-01-16'), isFalse);
    });

    test('getCurrentNepaliYearMonth() advances to next BS month and year at 18:15 UTC boundary', () {
      // End of Chaitra 2081 BS (Chaitra 31, 2081 BS = 2025-04-13 AD)
      // At 18:14:00 UTC on 2025-04-13 -> NPT is 2025-04-13 23:59:00 (Last minute of BS 2081 Chaitra)
      NepalClock.utcNow = () => DateTime.utc(2025, 4, 13, 18, 14, 0);
      final ymBefore = NepaliCalendarHelper.getCurrentNepaliYearMonth();
      expect(ymBefore.year, 2081);
      expect(ymBefore.monthIndex, 11); // Chaitra (Index 11)

      // At 18:15:00 UTC on 2025-04-13 -> NPT is 2025-04-14 00:00:00 (First second of BS 2082 Baisakh!)
      NepalClock.utcNow = () => DateTime.utc(2025, 4, 13, 18, 15, 0);
      final ymAfter = NepaliCalendarHelper.getCurrentNepaliYearMonth();
      expect(ymAfter.year, 2082); // Successfully transitioned to new BS year!
      expect(ymAfter.monthIndex, 0); // Baisakh (Index 0)
    });

    test('getCurrentNepaliYearMonth() advances to next BS month within the same year at 18:15 UTC boundary', () {
      // Magh 2082 ends on 2026-02-12 AD (29 days)
      // At 18:14:00 UTC on 2026-02-12 -> NPT is 2026-02-12 23:59:00 (Last minute of Magh 2082)
      NepalClock.utcNow = () => DateTime.utc(2026, 2, 12, 18, 14, 0);
      final ymMagh = NepaliCalendarHelper.getCurrentNepaliYearMonth();
      expect(ymMagh.year, 2082);
      expect(ymMagh.monthIndex, 9); // Magh (Index 9)

      // At 18:15:00 UTC on 2026-02-12 -> NPT is 2026-02-13 00:00:00 (First second of Falgun 2082!)
      NepalClock.utcNow = () => DateTime.utc(2026, 2, 12, 18, 15, 0);
      final ymFalgun = NepaliCalendarHelper.getCurrentNepaliYearMonth();
      expect(ymFalgun.year, 2082);
      expect(ymFalgun.monthIndex, 10); // Falgun (Index 10)
    });

    test('parseDate succeeds on valid dates', () {
      final dt1 = NepalClock.parseDate('2026-01-15');
      expect(dt1, DateTime.utc(2026, 1, 15));

      final dtLeap = NepalClock.parseDate('2024-02-29'); // 2024 is leap year
      expect(dtLeap, DateTime.utc(2024, 2, 29));
    });

    test('parseDate strictly rejects invalid formats and nonexistent calendar dates with FormatException', () {
      // Malformed strings
      expect(() => NepalClock.parseDate('invalid'), throwsA(isA<FormatException>()));
      expect(() => NepalClock.parseDate('2026/01/15'), throwsA(isA<FormatException>()));
      expect(() => NepalClock.parseDate('2026-01'), throwsA(isA<FormatException>()));

      // Out of range components
      expect(() => NepalClock.parseDate('2026-13-01'), throwsA(isA<FormatException>()));
      expect(() => NepalClock.parseDate('2026-00-10'), throwsA(isA<FormatException>()));
      expect(() => NepalClock.parseDate('2026-05-32'), throwsA(isA<FormatException>()));

      // Nonexistent calendar dates (round-trip validation caught)
      expect(() => NepalClock.parseDate('2026-02-30'), throwsA(isA<FormatException>()));
      expect(() => NepalClock.parseDate('2026-04-31'), throwsA(isA<FormatException>()));
      expect(() => NepalClock.parseDate('2025-02-29'), throwsA(isA<FormatException>())); // 2025 is not leap
    });
  });
}
