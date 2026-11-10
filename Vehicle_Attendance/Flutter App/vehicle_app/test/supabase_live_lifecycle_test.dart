// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/core/config/app_config.dart';

/// Test validating all 9 Supabase REST endpoints against live Supabase backend.
void main() {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${AppConfig.defaultSupabaseUrl}/rest/v1',
      headers: {
        'apikey': AppConfig.defaultSupabaseAnonKey,
        'Authorization': 'Bearer ${AppConfig.defaultSupabaseAnonKey}',
        'Content-Type': 'application/json',
      },
    ),
  );

  group('Supabase Live Backend Complete Lifecycle', () {
    test('1. GET /fuel_bills', () async {
      final res = await dio.get('/fuel_bills', queryParameters: {
        'select': '*',
        'order': 'end_date.desc',
      });
      expect(res.statusCode, 200);
      final list = res.data as List;
      expect(list.length, greaterThanOrEqualTo(2));
      print('Verified ${list.length} fuel bills in Supabase.');
    });

    test('2. GET /last_fuel_bill_date', () async {
      final res = await dio.get('/last_fuel_bill_date', queryParameters: {
        'select': 'last_bill_date',
        'id': 'eq.1',
      });
      expect(res.statusCode, 200);
      final list = res.data as List;
      expect(list.first['last_bill_date'], '2026-02-12');
      print('Verified last fuel bill date is 2026-02-12.');
    });

    test('3. GET /attendance_logs for Kartik 2083', () async {
      final res = await dio.get('/attendance_logs', queryParameters: {
        'log_date': 'gte.2026-10-01',
        'and': '(log_date.lte.2026-11-30)',
        'order': 'log_date.asc',
      });
      expect(res.statusCode, 200);
      final list = res.data as List;
      print('Found ${list.length} attendance logs for Oct/Nov 2026.');
    });

    test('4. Upsert Present / Holiday / Replace & Delete in Supabase', () async {
      const testDate = '2099-12-31';

      // 4a. Mark Present
      final upsertPresent = await dio.post(
        '/attendance_logs',
        options: Options(headers: {
          'Prefer': 'resolution=merge-duplicates,return=representation',
        }),
        data: {
          'log_date': testDate,
          'status': 'present',
          'extra_trip_income': 0,
        },
      );
      expect(upsertPresent.statusCode, inInclusiveRange(200, 201));
      expect((upsertPresent.data as List).first['status'], 'present');

      // 4b. Update to Holiday
      final upsertHoliday = await dio.post(
        '/attendance_logs',
        options: Options(headers: {
          'Prefer': 'resolution=merge-duplicates,return=representation',
        }),
        data: {
          'log_date': testDate,
          'status': 'absent_holiday',
          'extra_trip_income': 0,
        },
      );
      expect(upsertHoliday.statusCode, inInclusiveRange(200, 201));
      expect((upsertHoliday.data as List).first['status'], 'absent_holiday');

      // 4c. Update to Replace
      final upsertReplace = await dio.post(
        '/attendance_logs',
        options: Options(headers: {
          'Prefer': 'resolution=merge-duplicates,return=representation',
        }),
        data: {
          'log_date': testDate,
          'status': 'absent_replacement',
          'extra_trip_income': 0,
        },
      );
      expect(upsertReplace.statusCode, inInclusiveRange(200, 201));
      expect((upsertReplace.data as List).first['status'], 'absent_replacement');

      // 4d. Delete (when unselected)
      final del = await dio.delete(
        '/attendance_logs',
        queryParameters: {'log_date': 'eq.$testDate'},
      );
      expect(del.statusCode, 204);
      print('Successfully tested full Present -> Holiday -> Replace -> Delete cycle.');
    });
  });
}
