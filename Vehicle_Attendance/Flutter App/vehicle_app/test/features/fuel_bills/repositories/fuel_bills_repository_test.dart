import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vehicle_app/features/fuel_bills/repositories/fuel_bills_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late FuelBillsRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = FuelBillsRepository(mockDio);
  });

  group('FuelBillsRepository Tests', () {
    test('fetchFuelBills calls GET /api/fuel-bills and maps results', () async {
      when(() => mockDio.get('/api/fuel-bills')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/fuel-bills'),
          statusCode: 200,
          data: {
            'data': [
              {
                'id': 3,
                'start_date': '2026-02-01',
                'end_date': '2026-02-12',
                'total_km': 1076,
                'expected_liters': 143.47,
                'actual_liters': 144,
              }
            ]
          },
        ),
      );

      final bills = await repository.fetchFuelBills();
      expect(bills.length, 1);
      expect(bills.first.id, 3);
      expect(bills.first.startDate, '2026-02-01');
      expect(bills.first.endDate, '2026-02-12');
      expect(bills.first.totalKm, 1076);
      expect(bills.first.expectedLiters, 143.47);
      expect(bills.first.actualLiters, 144);
    });

    test('fetchLastBillDate calls GET /api/fuel-bills?type=last-date', () async {
      when(
        () => mockDio.get(
          '/api/fuel-bills',
          queryParameters: {'type': 'last-date'},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/fuel-bills'),
          statusCode: 200,
          data: {
            'data': {'last_bill_date': '2026-02-12'}
          },
        ),
      );

      final date = await repository.fetchLastBillDate();
      expect(date, '2026-02-12');
    });

    test('updateLastBillDate calls PATCH /api/fuel-bills with last_bill_date', () async {
      when(
        () => mockDio.patch(
          '/api/fuel-bills',
          data: {'last_bill_date': '2026-02-15'},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/fuel-bills'),
          statusCode: 200,
          data: {
            'data': {'last_bill_date': '2026-02-15'}
          },
        ),
      );

      final updated = await repository.updateLastBillDate('2026-02-15');
      expect(updated, '2026-02-15');
    });

    test('createFuelBill calls POST /api/fuel-bills', () async {
      when(
        () => mockDio.post(
          '/api/fuel-bills',
          data: {
            'start_date': '2026-02-13',
            'end_date': '2026-02-28',
            'total_km': 1200,
            'expected_liters': 160.0,
            'actual_liters': 160.0,
          },
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/fuel-bills'),
          statusCode: 200,
          data: {
            'data': {
              'id': 4,
              'start_date': '2026-02-13',
              'end_date': '2026-02-28',
              'total_km': 1200,
              'expected_liters': 160.0,
              'actual_liters': 160.0,
            }
          },
        ),
      );

      final bill = await repository.createFuelBill(
        startDate: '2026-02-13',
        endDate: '2026-02-28',
        totalKm: 1200,
        expectedLiters: 160.0,
        actualLiters: 160.0,
      );

      expect(bill.id, 4);
      expect(bill.totalKm, 1200);
      expect(bill.expectedLiters, 160.0);
    });
  });
}

