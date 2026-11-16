import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../models/monthly_settlement.dart';

final settlementsRepositoryProvider = Provider<SettlementsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SettlementsRepository(apiClient: apiClient);
});

class SettlementsRepository {
  final ApiClient apiClient;

  SettlementsRepository({required this.apiClient});

  static String _cacheKey(int year, int monthIndex) =>
      'cached_settlement_${year}_$monthIndex';

  /// Fetches the settlement for the specified BS month and its preceding month.
  Future<({MonthlySettlement? current, MonthlySettlement? previous})> fetchSettlements({
    required int bsYear,
    required int bsMonthIndex,
  }) async {
    MonthlySettlement? current;
    MonthlySettlement? previous;

    try {
      final response = await apiClient.get<dynamic>(
        '/api/settlements',
        queryParameters: {
          'year': bsYear.toString(),
          'month_index': bsMonthIndex.toString(),
        },
      );

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final currentJson = data['data'] as Map<String, dynamic>?;
        final prevJson = data['previous'] as Map<String, dynamic>?;

        final prevMonthIndex = bsMonthIndex == 0 ? 11 : bsMonthIndex - 1;
        final prevYear = bsMonthIndex == 0 ? bsYear - 1 : bsYear;

        if (currentJson != null) {
          current = MonthlySettlement.fromJson(currentJson);
          _saveToCache(bsYear, bsMonthIndex, current);
        } else {
          current = await _loadFromCache(bsYear, bsMonthIndex);
        }

        if (prevJson != null) {
          previous = MonthlySettlement.fromJson(prevJson);
          _saveToCache(prevYear, prevMonthIndex, previous);
        } else {
          previous = await _loadFromCache(prevYear, prevMonthIndex);
        }

        return (current: current, previous: previous);
      }
    } catch (_) {
      // Gracefully fall through to local cache
    }

    // Fallback to local persistent cache
    current ??= await _loadFromCache(bsYear, bsMonthIndex);
    final prevMonthIndex = bsMonthIndex == 0 ? 11 : bsMonthIndex - 1;
    final prevYear = bsMonthIndex == 0 ? bsYear - 1 : bsYear;
    previous ??= await _loadFromCache(prevYear, prevMonthIndex);

    return (current: current, previous: previous);
  }

  /// Saves or updates the month-end settlement.
  Future<MonthlySettlement?> saveSettlement(MonthlySettlement settlement) async {
    // 1. Always cache locally first so user data is never lost
    await _saveToCache(settlement.bsYear, settlement.bsMonthIndex, settlement);

    try {
      final response = await apiClient.post<dynamic>(
        '/api/settlements',
        data: settlement.toJson(),
      );

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data is Map<String, dynamic>) {
        final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
        if (data != null) {
          final saved = MonthlySettlement.fromJson(data);
          await _saveToCache(settlement.bsYear, settlement.bsMonthIndex, saved);
          return saved;
        }
      }
    } catch (_) {
      // Return cached settlement if network fails
    }

    return settlement;
  }

  Future<void> _saveToCache(int year, int monthIndex, MonthlySettlement s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey(year, monthIndex), jsonEncode(s.toJson()));
    } catch (_) {}
  }

  Future<MonthlySettlement?> _loadFromCache(int year, int monthIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(year, monthIndex));
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return MonthlySettlement.fromJson(map);
      }
    } catch (_) {}
    return null;
  }
}
