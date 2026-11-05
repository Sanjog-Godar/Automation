import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vehicle_app/core/config/app_constants.dart';
import 'package:vehicle_app/core/services/toast_service.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/repositories/attendance_repository.dart';
import 'package:vehicle_app/features/attendance/views/attendance_screen.dart';
import 'package:vehicle_app/features/auth/repositories/auth_repository.dart';
import 'package:vehicle_app/features/fuel_bills/models/fuel_bill.dart';
import 'package:vehicle_app/features/fuel_bills/repositories/fuel_bills_repository.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockToastService extends Mock implements ToastService {}
class MockFuelBillsRepository extends Mock implements FuelBillsRepository {}

void main() {
  late MockAttendanceRepository mockAttendanceRepository;
  late MockAuthRepository mockAuthRepository;
  late MockToastService mockToastService;
  late MockFuelBillsRepository mockFuelBillsRepository;

  setUp(() {
    mockAttendanceRepository = MockAttendanceRepository();
    mockAuthRepository = MockAuthRepository();
    mockToastService = MockToastService();
    mockFuelBillsRepository = MockFuelBillsRepository();

    when(() => mockAuthRepository.hasValidSession()).thenAnswer((_) async => true);
    when(() => mockAttendanceRepository.fetchMonthLogs(any(), any())).thenAnswer(
      (_) async => [
        const AttendanceLog(
          logDate: '2026-01-15',
          status: AttendanceStatus.present,
          extraTripIncome: 300,
          isUnselected: false,
        ),
      ],
    );

    when(() => mockFuelBillsRepository.fetchFuelBills()).thenAnswer(
      (_) async => [
        const FuelBill(
          id: 3,
          startDate: '2026-02-01',
          endDate: '2026-02-12',
          totalKm: 1076,
          expectedLiters: 143.47,
          actualLiters: 144,
        ),
      ],
    );
    when(() => mockFuelBillsRepository.fetchLastBillDate()).thenAnswer(
      (_) async => '2026-02-12',
    );
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(mockAttendanceRepository),
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        toastServiceProvider.overrideWithValue(mockToastService),
        fuelBillsRepositoryProvider.overrideWithValue(mockFuelBillsRepository),
      ],
      child: const MaterialApp(
        home: AttendanceScreen(),
      ),
    );
  }

  group('AttendanceScreen Widget Tests', () {
    testWidgets('Renders Vehicle number, monthly summary card, and navigation', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text(AppConstants.vehicleNumber), findsOneWidget);
      expect(find.text('Monthly Summary'), findsOneWidget);
      expect(find.text('Present Days'), findsOneWidget);
      expect(find.text('Replacement Days'), findsOneWidget);
      expect(find.text('Total KM Run'), findsOneWidget);
      expect(find.text('Net Income (Rs.)'), findsOneWidget);
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Verify Fuel Bill Records card is rendered
      expect(find.text('Fuel Bill Records / ईन्धन बिल रेकर्ड'), findsOneWidget);
      expect(find.text('Last Fuel Bill End Date'), findsOneWidget);

      // Verify Quick Actions card is rendered
      expect(find.text('Quick Actions / छिटो कार्यहरू'), findsOneWidget);
      expect(find.text('Generate Fuel Bill'), findsOneWidget);
      expect(find.text('Download Report'), findsOneWidget);
    });
  });
}
