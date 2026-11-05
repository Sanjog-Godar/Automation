import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/fuel_bill.dart';

final fuelBillsRepositoryProvider = Provider<FuelBillsRepository>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return FuelBillsRepository(dio);
});

/// Repository for managing fuel bill records, consumption calculations, and last bill dates.
class FuelBillsRepository {
  final Dio _dio;

  FuelBillsRepository(this._dio);

  /// Fetches all fuel bills ordered by end_date descending.
  Future<List<FuelBill>> fetchFuelBills() async {
    final response = await _dio.get('/api/fuel-bills');
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((item) => FuelBill.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Fetches the last fuel bill end date from dedicated table.
  Future<String?> fetchLastBillDate() async {
    final response = await _dio.get(
      '/api/fuel-bills',
      queryParameters: {'type': 'last-date'},
    );
    final data = response.data['data'] as Map<String, dynamic>?;
    return data?['last_bill_date'] as String?;
  }

  /// Updates the last fuel bill end date in the database.
  Future<String?> updateLastBillDate(String lastBillDate) async {
    final response = await _dio.patch(
      '/api/fuel-bills',
      data: {'last_bill_date': lastBillDate},
    );
    final data = response.data['data'] as Map<String, dynamic>?;
    return data?['last_bill_date'] as String?;
  }

  /// Creates a new fuel bill record.
  Future<FuelBill> createFuelBill({
    required String startDate,
    required String endDate,
    required int totalKm,
    required double expectedLiters,
    double? actualLiters,
  }) async {
    final response = await _dio.post(
      '/api/fuel-bills',
      data: {
        'start_date': startDate,
        'end_date': endDate,
        'total_km': totalKm,
        'expected_liters': expectedLiters,
        'actual_liters': ?actualLiters,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return FuelBill.fromJson(data);
  }

  /// Calculates total KM between startDate and endDate by fetching spanned months from /api/attendance.
  Future<int> calculateKmInRange(String startDate, String endDate) async {
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);

    if (start.isAfter(end)) return 0;

    // Collect all unique YYYY-MM strings spanned by the date interval
    final List<String> monthsToFetch = [];
    var cur = DateTime.utc(start.year, start.month, 1);
    final endLimit = DateTime.utc(end.year, end.month, 1);

    while (!cur.isAfter(endLimit)) {
      final y = cur.year.toString().padLeft(4, '0');
      final m = cur.month.toString().padLeft(2, '0');
      monthsToFetch.add('$y-$m');
      cur = DateTime.utc(cur.year, cur.month + 1, 1);
    }

    int totalKm = 0;
    for (final monthStr in monthsToFetch) {
      try {
        final res = await _dio.get(
          '/api/attendance',
          queryParameters: {'month': monthStr},
        );
        final logs = res.data['data'] as List<dynamic>? ?? [];
        for (final raw in logs) {
          final logDate = raw['log_date'] as String?;
          final km = raw['km_total'];
          if (logDate != null && km != null) {
            final dt = DateTime.parse(logDate);
            if (!dt.isBefore(start) && !dt.isAfter(end)) {
              totalKm += (km as num).toInt();
            }
          }
        }
      } catch (_) {
        // Continue if single month fails
      }
    }

    return totalKm;
  }
}
