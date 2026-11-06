import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vehicle_app/core/services/toast_service.dart';
import 'package:vehicle_app/core/utils/nepal_clock.dart';
import 'package:vehicle_app/features/attendance/controllers/attendance_controller.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/repositories/attendance_repository.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}
class MockToastService extends Mock implements ToastService {}

void main() {
  late MockAttendanceRepository mockRepository;
  late MockToastService mockToastService;

  setUpAll(() {
    registerFallbackValue(
      const AttendanceLog(
        logDate: '2026-01-15',
        status: AttendanceStatus.present,
      ),
    );
  });

  setUp(() {
    mockRepository = MockAttendanceRepository();
    mockToastService = MockToastService();
    // Fix test clock to 2026-01-15
    NepalClock.utcNow = () => DateTime.utc(2026, 1, 15, 6, 0, 0);
  });

  tearDown(() {
    NepalClock.reset();
  });

  ProviderContainer createContainer(List<AttendanceLog> initialLogs) {
    when(() => mockRepository.fetchMonthLogs(any(), any()))
        .thenAnswer((_) async => initialLogs);

    final container = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(mockRepository),
        toastServiceProvider.overrideWithValue(mockToastService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AttendanceController Tests', () {
    test('Optimistic toggle delete replaces entry with isUnselected placeholder and preserves list length', () async {
      final initialLogs = [
        const AttendanceLog(
          logDate: '2026-01-14',
          status: AttendanceStatus.present,
          extraTripIncome: 200,
          isUnselected: false,
        ),
        const AttendanceLog(
          logDate: '2026-01-15',
          status: AttendanceStatus.absentHoliday,
          isUnselected: false,
        ),
      ];

      when(() => mockRepository.deleteAttendance('2026-01-14')).thenAnswer((_) async {});

      final container = createContainer(initialLogs);
      final controller = container.read(attendanceControllerProvider.notifier);
      await controller.loadMonth(2082, 9);

      expect(container.read(attendanceControllerProvider).logs.length, 2);

      // Clicking present on an already-present day toggles delete
      await controller.changeStatus('2026-01-14', AttendanceStatus.present);

      final state = container.read(attendanceControllerProvider);
      // List length MUST remain exactly 2
      expect(state.logs.length, 2);

      final day1 = state.logs[0];
      expect(day1.logDate, '2026-01-14');
      expect(day1.isUnselected, isTrue);
      expect(day1.status, AttendanceStatus.absentHoliday); // default placeholder status

      verify(() => mockRepository.deleteAttendance('2026-01-14')).called(1);
    });

    test('Rollback on failure restores ONLY the affected date without clobbering other dates', () async {
      final initialLogs = [
        const AttendanceLog(
          logDate: '2026-01-14',
          status: AttendanceStatus.present,
          extraTripIncome: 500,
          isUnselected: false,
        ),
        const AttendanceLog(
          logDate: '2026-01-15',
          status: AttendanceStatus.present,
          extraTripIncome: 0,
          isUnselected: false,
        ),
      ];

      when(() => mockRepository.deleteAttendance('2026-01-14'))
          .thenThrow(Exception('Network timeout'));

      final container = createContainer(initialLogs);
      final controller = container.read(attendanceControllerProvider.notifier);
      await controller.loadMonth(2082, 9);

      await controller.changeStatus('2026-01-14', AttendanceStatus.present);

      final state = container.read(attendanceControllerProvider);
      // Day 1 must be rolled back to original values
      final day1 = state.logs[0];
      expect(day1.status, AttendanceStatus.present);
      expect(day1.extraTripIncome, 500);
      expect(day1.isUnselected, isFalse);

      // Day 2 must remain completely untouched
      final day2 = state.logs[1];
      expect(day2.status, AttendanceStatus.present);
      expect(day2.logDate, '2026-01-15');

      verify(() => mockToastService.showError(any(), nepaliMessage: any(named: 'nepaliMessage'))).called(1);
    });

    test('Changing status away from present resets extraTripIncome to 0 but preserves tips and km', () async {
      final initialLogs = [
        const AttendanceLog(
          logDate: '2026-01-15',
          status: AttendanceStatus.present,
          extraTripIncome: 600,
          extraTipAmount: 300,
          kmTotal: 75,
          isUnselected: false,
        ),
      ];

      when(() => mockRepository.upsertAttendance(any())).thenAnswer(
        (invocation) async => invocation.positionalArguments.first as AttendanceLog,
      );

      final container = createContainer(initialLogs);
      final controller = container.read(attendanceControllerProvider.notifier);
      await controller.loadMonth(2082, 9);

      await controller.changeStatus('2026-01-15', AttendanceStatus.absentReplacement);

      final state = container.read(attendanceControllerProvider);
      final updated = state.logs[0];
      expect(updated.status, AttendanceStatus.absentReplacement);
      expect(updated.extraTripIncome, 0); // Reset to 0!
      expect(updated.extraTipAmount, 300); // Preserved!
      expect(updated.kmTotal, 75); // Preserved!
      expect(updated.isUnselected, isFalse);
    });

    test('Rejects attendance marking on future dates', () async {
      final initialLogs = [
        const AttendanceLog(
          logDate: '2026-01-20', // Future relative to 2026-01-15
          status: AttendanceStatus.absentHoliday,
          isUnselected: true,
        ),
      ];

      final container = createContainer(initialLogs);
      final controller = container.read(attendanceControllerProvider.notifier);
      await controller.loadMonth(2082, 9);

      await controller.changeStatus('2026-01-20', AttendanceStatus.present);

      // Repository must NEVER be called
      verifyNever(() => mockRepository.upsertAttendance(any()));
      verify(() => mockToastService.showError(
            'You cannot mark attendance for future dates',
            nepaliMessage: any(named: 'nepaliMessage'),
          )).called(1);
    });

    test('updateKm rejects if end KM is less than start KM', () async {
      final initialLogs = [
        const AttendanceLog(
          logDate: '2026-01-15',
          status: AttendanceStatus.present,
          isUnselected: false,
        ),
      ];

      final container = createContainer(initialLogs);
      final controller = container.read(attendanceControllerProvider.notifier);
      await controller.loadMonth(2082, 9);

      // Attempt to save 12500 end with 13000 start
      await controller.updateKm('2026-01-15', 13000, 12500);

      verifyNever(() => mockRepository.upsertAttendance(any()));
      verify(() => mockToastService.showError(
            'Ending KM cannot be less than Starting KM',
            nepaliMessage: any(named: 'nepaliMessage'),
          )).called(1);
    });

    test('AttendanceController can be rebuilt/refreshed without LateInitializationError', () {
      final container = createContainer([]);
      // First read triggers build()
      expect(container.read(attendanceControllerProvider), isNotNull);

      // Refresh triggers build() again
      expect(() => container.refresh(attendanceControllerProvider), returnsNormally);
      expect(container.read(attendanceControllerProvider), isNotNull);
    });
  });
}

