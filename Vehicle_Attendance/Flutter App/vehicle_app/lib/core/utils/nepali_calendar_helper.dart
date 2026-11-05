import 'package:nepali_utils/nepali_utils.dart';
import 'nepal_clock.dart';
import 'nepali_month_table.g.dart';

/// Helper utility for Nepali Bikram Sambat (BS) calendar operations,
/// date conversions, formatting, and Devanagari numerals.
///
/// Source of Truth Decision:
/// The precomputed `nepaliMonthTable` and `nepaliMonthMetadataList` emitted by
/// `scripts/generate_golden.js` from the web project's `nepali-date-converter`
/// is the PRIMARY source of truth for BS years 2080–2084.
/// This guarantees 100% parity with the web Next.js application and eliminates
/// OS-specific historical timezone offset bugs.
/// `nepali_utils` serves as a fallback engine for years outside the 2080–2084 range.
class NepaliCalendarHelper {
  NepaliCalendarHelper._();

  /// Month names in Devanagari (Index 0 = बैशाख to 11 = चैत्र).
  static const List<String> nepaliMonths = [
    'बैशाख',
    'जेष्ठ',
    'अषाढ',
    'श्रावण',
    'भाद्र',
    'आश्विन',
    'कार्तिक',
    'मंसिर',
    'पौष',
    'माघ',
    'फाल्गुन',
    'चैत्र',
  ];

  /// Month names in English phonetics (Index 0 = Baisakh to 11 = Chaitra).
  static const List<String> nepaliMonthsEnglish = [
    'Baisakh',
    'Jestha',
    'Ashadh',
    'Shrawan',
    'Bhadra',
    'Ashwin',
    'Kartik',
    'Mangsir',
    'Poush',
    'Magh',
    'Falgun',
    'Chaitra',
  ];

  /// Devanagari digits ० - ९.
  static const List<String> nepaliDigits = [
    '०', '१', '२', '३', '४', '५', '६', '७', '८', '९'
  ];

  /// Converts an integer or numeric string into Devanagari numerals.
  /// Example: `2082` -> `'२०८२'`
  static String toNepaliNumber(int number) {
    return number
        .toString()
        .split('')
        .map((digit) {
          final index = int.tryParse(digit);
          return index != null ? nepaliDigits[index] : digit;
        })
        .join('');
  }

  /// Returns current Nepali year and 0-based month index based on NepalClock.
  static ({int year, int monthIndex}) getCurrentNepaliYearMonth() {
    final todayStr = NepalClock.todayDateString();

    for (final entry in nepaliMonthMetadataList) {
      if (entry.startDateAD.compareTo(todayStr) <= 0 &&
          todayStr.compareTo(entry.endDateAD) <= 0) {
        return (year: entry.year, monthIndex: entry.monthIndex);
      }
    }

    // Fallback outside precomputed range
    final nepalNow = NepalClock.now();
    final nepaliDate = nepalNow.toNepaliDateTime();
    return (year: nepaliDate.year, monthIndex: nepaliDate.month - 1);
  }

  /// Calculates total days in a Nepali month (monthIndex: 0-11).
  ///
  /// Uses the generated `nepaliMonthTable` as primary for 2080–2084.
  /// Falls back to `nepali_utils` for years outside this range.
  static int getDaysInMonth(int year, int monthIndex) {
    final table = nepaliMonthTable[year];
    if (table != null && monthIndex >= 0 && monthIndex < 12) {
      return table[monthIndex];
    }

    final monthNumber = monthIndex + 1; // 1-12
    final nd = NepaliDateTime(year, monthNumber, 1);
    return nd.totalDays;
  }

  /// Converts a specific Nepali date (year, monthIndex 0-11, day 1-32)
  /// to a Gregorian DateTime normalized to midnight UTC.
  static DateTime toGregorian(int year, int monthIndex, int day) {
    for (final entry in nepaliMonthMetadataList) {
      if (entry.year == year && entry.monthIndex == monthIndex) {
        final startDt = NepalClock.parseDate(entry.startDateAD);
        return startDt.add(Duration(days: day - 1));
      }
    }

    // Fallback outside precomputed range
    final monthNumber = monthIndex + 1;
    final nepaliDt = NepaliDateTime(year, monthNumber, day);
    final dt = nepaliDt.toDateTime();
    return DateTime.utc(dt.year, dt.month, dt.day);
  }

  /// Converts a Gregorian DateTime into a NepaliDateTime.
  static NepaliDateTime fromGregorian(DateTime gregorian) {
    return gregorian.toNepaliDateTime();
  }

  /// Formats a Gregorian DateTime into an ISO `YYYY-MM-DD` string.
  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Calculates previous month navigation.
  static ({int year, int monthIndex}) previousMonth(int year, int monthIndex) {
    if (monthIndex == 0) {
      return (year: year - 1, monthIndex: 11);
    }
    return (year: year, monthIndex: monthIndex - 1);
  }

  /// Calculates next month navigation.
  static ({int year, int monthIndex}) nextMonth(int year, int monthIndex) {
    if (monthIndex == 11) {
      return (year: year + 1, monthIndex: 0);
    }
    return (year: year, monthIndex: monthIndex + 1);
  }

  /// Returns English Month & Year subtitle for the header
  /// (e.g. "January 2026" or "January - February 2026").
  static String getEnglishMonthSubtitle(int year, int monthIndex) {
    final startAD = toGregorian(year, monthIndex, 1);
    final days = getDaysInMonth(year, monthIndex);
    final endAD = toGregorian(year, monthIndex, days);

    const monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final startMonthName = monthNames[startAD.month];
    final endMonthName = monthNames[endAD.month];

    if (startMonthName == endMonthName) {
      return '$startMonthName ${startAD.year}';
    } else if (startAD.year == endAD.year) {
      return '$startMonthName - $endMonthName ${startAD.year}';
    } else {
      return '$startMonthName ${startAD.year} - $endMonthName ${endAD.year}';
    }
  }

  /// Computes the distinct Gregorian months (format `YYYY-MM`) spanned by a BS month.
  /// (Used by AttendanceRepository to fetch cross-month logs).
  static List<String> getSpannedGregorianMonths(int year, int monthIndex) {
    final startAD = toGregorian(year, monthIndex, 1);
    final days = getDaysInMonth(year, monthIndex);
    final endAD = toGregorian(year, monthIndex, days);

    final startKey = '${startAD.year}-${startAD.month.toString().padLeft(2, '0')}';
    final endKey = '${endAD.year}-${endAD.month.toString().padLeft(2, '0')}';

    if (startKey == endKey) {
      return [startKey];
    }
    return [startKey, endKey];
  }
}
