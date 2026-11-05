import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/nepali_calendar_helper.dart';
import '../models/attendance_log.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AttendanceRepository(apiClient: apiClient);
});

/// Repository responsible for attendance data fetching, cross-month merging,
/// and API mutations.
class AttendanceRepository {
  final ApiClient apiClient;

  AttendanceRepository({required this.apiClient});

  /// Fetches attendance records for the given Bikram Sambat year and monthIndex (0-11).
  ///
  /// Since a Nepali month spans across 1 or 2 Gregorian months, this method:
  /// 1. Queries all spanned Gregorian months via `/api/attendance?month=YYYY-MM`.
  /// 2. Merges and de-duplicates the returned records.
  /// 3. Builds a complete daily list for all days of the BS month,
  ///    populating missing days with `AttendanceLog.unselectedPlaceholder`.
  Future<List<AttendanceLog>> fetchMonthLogs(int year, int monthIndex) async {
    final spannedMonths = NepaliCalendarHelper.getSpannedGregorianMonths(year, monthIndex);
    final byDate = <String, AttendanceLog>{};

    for (final monthStr in spannedMonths) {
      try {
        final response = await apiClient.get<Map<String, dynamic>>(
          '/api/attendance',
          queryParameters: {'month': monthStr},
        );

        if (response.statusCode == 200 && response.data != null) {
          final rawList = response.data!['data'] as List<dynamic>? ?? [];
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              final log = AttendanceLog.fromJson(item);
              byDate[log.logDate] = log;
            }
          }
        }
      } catch (e) {
        // If one Gregorian month fails, log and continue to allow partial display if possible
      }
    }

    final totalDays = NepaliCalendarHelper.getDaysInMonth(year, monthIndex);
    final fullMonthLogs = <AttendanceLog>[];

    for (int day = 1; day <= totalDays; day++) {
      final adDate = NepaliCalendarHelper.toGregorian(year, monthIndex, day);
      final dateStr = NepaliCalendarHelper.formatDate(adDate);

      final existing = byDate[dateStr];
      if (existing != null) {
        fullMonthLogs.add(existing.copyWith(isUnselected: false));
      } else {
        fullMonthLogs.add(AttendanceLog.unselectedPlaceholder(dateStr));
      }
    }

    return fullMonthLogs;
  }

  /// Upserts an attendance record matching `POST /api/attendance`.
  Future<AttendanceLog> upsertAttendance(AttendanceLog log) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/api/attendance',
      data: log.toJson(),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return AttendanceLog.fromJson(data);
      }
      return log.copyWith(isUnselected: false);
    }

    final errorMsg = response.data?['error'] as String? ?? 'Failed to save attendance';
    throw Exception(errorMsg);
  }

  /// Deletes an attendance record matching `DELETE /api/attendance?log_date=YYYY-MM-DD`.
  Future<void> deleteAttendance(String logDate) async {
    final response = await apiClient.delete<Map<String, dynamic>>(
      '/api/attendance',
      queryParameters: {'log_date': logDate},
    );

    if (response.statusCode == 200) {
      return;
    }

    final errorMsg = response.data?['error'] as String? ?? 'Failed to delete attendance';
    throw Exception(errorMsg);
  }
}

