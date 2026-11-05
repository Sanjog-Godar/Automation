import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vehicle_app/core/network/api_client.dart';
import 'package:vehicle_app/core/utils/nepali_calendar_helper.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/repositories/attendance_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late AttendanceRepository repository;

  setUp(() {
    mockApiClient = MockApiClient();
    repository = AttendanceRepository(apiClient: mockApiClient);
  });

  group('AttendanceRepository Tests', () {
    test('fetchMonthLogs queries spanned Gregorian months and returns exact month length', () async {
      // Magh 2082 (index 9) spans 2026-01 and 2026-02 and has 29 days
      final expectedDays = NepaliCalendarHelper.getDaysInMonth(2082, 9);
      expect(expectedDays, 29);

      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          '/api/attendance',
          queryParameters: {'month': '2026-01'},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/attendance'),
          statusCode: 200,
          data: {
            'data': [
              {
                'log_date': '2026-01-15',
                'status': 'present',
                'extra_trip_income': 0,
                'extra_tip_amount': 150,
                'km_total': 45,
              }
            ],
          },
        ),
      );

      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          '/api/attendance',
          queryParameters: {'month': '2026-02'},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/attendance'),
          statusCode: 200,
          data: {'data': []},
        ),
      );

      final logs = await repository.fetchMonthLogs(2082, 9);

      // Must have exactly 29 entries for all days of Magh 2082
      expect(logs.length, 29);

      final day1 = logs.firstWhere((l) => l.logDate == '2026-01-15');
      expect(day1.status, AttendanceStatus.present);
      expect(day1.isUnselected, isFalse);
      expect(day1.extraTipAmount, 150);

      // Other days must be unselected placeholders
      final unselectedDay = logs.firstWhere((l) => l.logDate != '2026-01-15');
      expect(unselectedDay.isUnselected, isTrue);
    });

    test('upsertAttendance posts JSON payload and parses response', () async {
      const log = AttendanceLog(
        logDate: '2026-01-15',
        status: AttendanceStatus.present,
        extraTripIncome: 400,
      );

      when(
        () => mockApiClient.post<Map<String, dynamic>>(
          '/api/attendance',
          data: log.toJson(),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/attendance'),
          statusCode: 200,
          data: {
            'data': {
              'log_date': '2026-01-15',
              'status': 'present',
              'extra_trip_income': 400,
              'extra_tip_amount': 0,
            },
          },
        ),
      );

      final result = await repository.upsertAttendance(log);
      expect(result.logDate, '2026-01-15');
      expect(result.status, AttendanceStatus.present);
      expect(result.extraTripIncome, 400);
      expect(result.isUnselected, isFalse);
    });

    test('deleteAttendance issues DELETE request with log_date query parameter', () async {
      when(
        () => mockApiClient.delete<Map<String, dynamic>>(
          '/api/attendance',
          queryParameters: {'log_date': '2026-01-15'},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/attendance'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      await repository.deleteAttendance('2026-01-15');

      verify(
        () => mockApiClient.delete<Map<String, dynamic>>(
          '/api/attendance',
          queryParameters: {'log_date': '2026-01-15'},
        ),
      ).called(1);
    });
  });
}

