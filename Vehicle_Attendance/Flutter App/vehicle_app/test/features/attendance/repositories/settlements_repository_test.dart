import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicle_app/core/network/api_client.dart';
import 'package:vehicle_app/features/attendance/models/monthly_settlement.dart';
import 'package:vehicle_app/features/attendance/repositories/settlements_repository.dart';

class _FakeApiClient extends Fake implements ApiClient {
  final Map<String, dynamic>? mockGetResponse;
  final bool shouldThrowOnGet;
  final bool shouldThrowOnPost;

  _FakeApiClient({
    this.mockGetResponse,
    this.shouldThrowOnGet = false,
    this.shouldThrowOnPost = false,
  });

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (shouldThrowOnGet) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(path: path), statusCode: 404),
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: (mockGetResponse ?? {'data': null, 'previous': null}) as T,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (shouldThrowOnPost) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.unknown,
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {'data': data} as T,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettlementsRepository Tests', () {
    test('saveSettlement caches locally and fetchSettlements retrieves previous month unpaid balance even when remote returns null', () async {
      final fakeApi = _FakeApiClient(
        mockGetResponse: {'data': null, 'previous': null},
      );
      final repo = SettlementsRepository(apiClient: fakeApi);

      // 1. Record bank salary in month 6 (Kartik): Expected 2182, Received 2000 => Unpaid Due = 182
      const kartikSettlement = MonthlySettlement(
        bsYear: 2083,
        bsMonthIndex: 6,
        expectedAmount: 2182,
        bankReceivedAmount: 2000,
        settlementStatus: 'partial',
        paymentDate: '2026-11-16',
      );

      final saved = await repo.saveSettlement(kartikSettlement);
      expect(saved, isNotNull);
      expect(saved!.pendingAmount, 182);

      // 2. Query month 7 (Mangsir): Previous month should be month 6 (Kartik)
      final result = await repo.fetchSettlements(bsYear: 2083, bsMonthIndex: 7);

      expect(result.current, isNull);
      expect(result.previous, isNotNull);
      expect(result.previous!.bsYear, 2083);
      expect(result.previous!.bsMonthIndex, 6);
      expect(result.previous!.expectedAmount, 2182);
      expect(result.previous!.bankReceivedAmount, 2000);
      expect(result.previous!.pendingAmount, 182);
    });

    test('fetchSettlements falls back to cache on API error', () async {
      final fakeApi = _FakeApiClient(shouldThrowOnGet: true);
      final repo = SettlementsRepository(apiClient: fakeApi);

      const kartikSettlement = MonthlySettlement(
        bsYear: 2083,
        bsMonthIndex: 6,
        expectedAmount: 5000,
        bankReceivedAmount: 4000,
      );
      await repo.saveSettlement(kartikSettlement);

      // Fetch month 7 when API throws error
      final result = await repo.fetchSettlements(bsYear: 2083, bsMonthIndex: 7);
      expect(result.previous, isNotNull);
      expect(result.previous!.pendingAmount, 1000);
    });
  });
}

