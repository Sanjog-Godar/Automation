import 'package:flutter/foundation.dart';

/// Centralized clock and date validator evaluating all operations in
/// Nepal Standard Time (Asia/Kathmandu, UTC+5:45) independent of the device's local timezone.
class NepalClock {
  NepalClock._();

  /// Constant offset of Nepal Standard Time: +5 hours and 45 minutes from UTC.
  static const Duration nepalOffset = Duration(hours: 5, minutes: 45);

  /// Injectable clock provider for current UTC time.
  /// Default produces `DateTime.now().toUtc()`.
  @visibleForTesting
  static DateTime Function() utcNow = () => DateTime.now().toUtc();

  /// Returns current date and time in Nepal Standard Time (UTC+5:45).
  static DateTime now() {
    return utcNow().add(nepalOffset);
  }

  /// Returns today's date in Nepal Standard Time normalized to midnight (00:00:00).
  static DateTime today() {
    final n = now();
    return DateTime.utc(n.year, n.month, n.day);
  }

  /// Returns today's date formatted as ISO string `YYYY-MM-DD`.
  static String todayDateString() {
    return formatDate(today());
  }

  /// Formats a DateTime as ISO string `YYYY-MM-DD`.
  static String formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parses an ISO `YYYY-MM-DD` string into midnight UTC DateTime.
  ///
  /// Rejects malformed strings and nonexistent dates (e.g. `2026-02-30`)
  /// via strict round-trip verification.
  static DateTime parseDate(String yyyyMmDd) {
    final parts = yyyyMmDd.split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid date format: "$yyyyMmDd". Expected YYYY-MM-DD.');
    }

    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);

    if (y == null || m == null || d == null || m < 1 || m > 12 || d < 1 || d > 31) {
      throw FormatException('Invalid date components in "$yyyyMmDd".');
    }

    final dt = DateTime.utc(y, m, d);

    // Strict round-trip check: ensures invalid dates (e.g. 2026-02-30) that roll over
    // in DateTime constructor are rejected as invalid calendar dates.
    if (dt.year != y || dt.month != m || dt.day != d) {
      throw FormatException('Invalid calendar date: "$yyyyMmDd" does not exist.');
    }

    return dt;
  }

  /// Checks whether a given `YYYY-MM-DD` date matches today in Nepal time.
  static bool isToday(String yyyyMmDd) {
    return yyyyMmDd == todayDateString();
  }

  /// Checks whether a given `YYYY-MM-DD` date is strictly in the future
  /// relative to today in Nepal time.
  static bool isFuture(String yyyyMmDd) {
    final date = parseDate(yyyyMmDd);
    final todayDt = today();
    return date.isAfter(todayDt);
  }

  /// Checks whether a given `YYYY-MM-DD` date is strictly in the past
  /// relative to today in Nepal time.
  static bool isPast(String yyyyMmDd) {
    final date = parseDate(yyyyMmDd);
    final todayDt = today();
    return date.isBefore(todayDt);
  }

  /// Resets test clock to system UTC.
  @visibleForTesting
  static void reset() {
    utcNow = () => DateTime.now().toUtc();
  }
}
