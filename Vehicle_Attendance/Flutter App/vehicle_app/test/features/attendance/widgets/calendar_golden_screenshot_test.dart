import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vehicle_app/core/network/cookie_manager_provider.dart';
import 'package:vehicle_app/core/services/toast_service.dart';
import 'package:vehicle_app/core/theme/app_theme.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/repositories/attendance_repository.dart';
import 'package:vehicle_app/features/attendance/views/attendance_screen.dart';
import 'package:vehicle_app/features/attendance/widgets/calendar_grid.dart';
import 'package:vehicle_app/features/attendance/widgets/day_details_bottom_sheet.dart';
import 'package:vehicle_app/features/auth/repositories/auth_repository.dart';
import 'package:vehicle_app/features/fuel_bills/controllers/fuel_bills_controller.dart';
import 'package:vehicle_app/features/fuel_bills/models/fuel_bill.dart';
import 'package:vehicle_app/features/fuel_bills/repositories/fuel_bills_repository.dart';
import 'package:vehicle_app/features/fuel_bills/widgets/fuel_bill_records_dialog.dart';
import 'package:vehicle_app/l10n/app_localizations.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockToastService extends Mock implements ToastService {}
class MockFuelBillsRepository extends Mock implements FuelBillsRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleLogs = List.generate(30, (i) {
    final day = i + 1;
    final dateStr = '2026-11-${day.toString().padLeft(2, '0')}';
    if (day == 1) {
      return AttendanceLog(logDate: dateStr, status: AttendanceStatus.present, isUnselected: true);
    } else if (day == 2) {
      return AttendanceLog(logDate: dateStr, status: AttendanceStatus.present, isUnselected: false, kmTotal: 0);
    } else if (day == 3) {
      return AttendanceLog(logDate: dateStr, status: AttendanceStatus.present, isUnselected: false, kmTotal: 75);
    } else if (day == 4) {
      return AttendanceLog(logDate: dateStr, status: AttendanceStatus.absentReplacement, isUnselected: false);
    } else if (day == 5) {
      return AttendanceLog(logDate: dateStr, status: AttendanceStatus.present, isUnselected: false, kmTotal: 60, extraTipAmount: 200);
    } else if (day == 6) {
      return AttendanceLog(logDate: dateStr, status: AttendanceStatus.absentHoliday, isUnselected: false);
    } else {
      return AttendanceLog(logDate: dateStr, status: AttendanceStatus.present, isUnselected: true);
    }
  });

  const sampleBills = [
    FuelBill(
      id: 1,
      startDate: '2026-02-01',
      endDate: '2026-02-12',
      totalKm: 1076,
      expectedLiters: 143.47,
      actualLiters: 144,
    ),
    FuelBill(
      id: 2,
      startDate: '2026-01-15',
      endDate: '2026-01-31',
      totalKm: 1507,
      expectedLiters: 200.93,
      actualLiters: 201,
    ),
  ];

  Widget buildHarvestedGrid(double width) {
    return MaterialApp(
      locale: const Locale('ne'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
              child: CalendarGrid(
                bsYear: 2083,
                bsMonthIndex: 7, // Kartik
                logs: sampleLogs,
                savingDates: const {},
                onPreviousMonth: () {},
                onNextMonth: () {},
                onToday: () {},
                onStatusChange: (d, s) {},
                onOpenTip: (l) {},
                onOpenKm: (l) {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHarvestedDashboard() {
    final mockAttendance = MockAttendanceRepository();
    final mockAuth = MockAuthRepository();
    final mockToast = MockToastService();
    final mockFuel = MockFuelBillsRepository();

    when(() => mockAuth.hasValidSession()).thenAnswer((_) async => true);
    when(() => mockAttendance.fetchMonthLogs(any(), any())).thenAnswer((_) async => sampleLogs);
    when(() => mockFuel.fetchFuelBills()).thenAnswer((_) async => sampleBills);
    when(() => mockFuel.fetchLastBillDate()).thenAnswer((_) async => '2026-02-12');

    return ProviderScope(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(mockAttendance),
        authRepositoryProvider.overrideWithValue(mockAuth),
        toastServiceProvider.overrideWithValue(mockToast),
        fuelBillsRepositoryProvider.overrideWithValue(mockFuel),
        cookieJarProvider.overrideWithValue(CookieJar()),
      ],
      child: MaterialApp(
        locale: const Locale('ne'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: const AttendanceScreen(),
      ),
    );
  }

  Widget buildHarvestedSheet() {
    return MaterialApp(
      locale: const Locale('ne'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: SizedBox(
            width: 360,
            child: DayDetailsBottomSheet(
              dayNumber: 4,
              bsYear: 2083,
              bsMonthIndex: 6,
              log: sampleLogs[3],
              isSaving: false,
              onStatusChange: (d, s) {},
              onOpenTip: (l) {},
              onOpenKm: (l) {},
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHarvestedDialog() {
    final mockRepo = MockFuelBillsRepository();
    when(() => mockRepo.fetchFuelBills()).thenAnswer((_) async => sampleBills);
    when(() => mockRepo.fetchLastBillDate()).thenAnswer((_) async => '2026-02-12');

    final container = ProviderContainer(
      overrides: [
        fuelBillsRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    container.read(fuelBillsControllerProvider.notifier).load();

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('ne'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          backgroundColor: Color(0xFFF5F7FA),
          body: Center(
            child: SizedBox(
              width: 360,
              child: FuelBillRecordsDialog(),
            ),
          ),
        ),
      ),
    );
  }

  group('Visual Golden Verification Tests (Light Mode Only)', () {
    // 1. Month grid at 320dp, 360dp, 411dp
    testWidgets('Renders month grid at 320dp cleanly', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 700 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHarvestedGrid(320));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarGrid), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(CalendarGrid),
        matchesGoldenFile('goldens/calendar_grid_320dp_light.png'),
      );
    });

    testWidgets('Renders month grid at 360dp cleanly', (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 700 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHarvestedGrid(360));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarGrid), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(CalendarGrid),
        matchesGoldenFile('goldens/calendar_grid_360dp_light.png'),
      );
    });

    testWidgets('Renders month grid at 411dp cleanly', (tester) async {
      tester.view.physicalSize = const Size(411 * 2, 700 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHarvestedGrid(411));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarGrid), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(CalendarGrid),
        matchesGoldenFile('goldens/calendar_grid_411dp_light.png'),
      );
    });

    // 2. Full dashboard at 360dp
    testWidgets('Renders full dashboard at 360dp cleanly', (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHarvestedDashboard());
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(AttendanceScreen),
        matchesGoldenFile('goldens/dashboard_360dp_light.png'),
      );
    });

    // 3. Day details bottom sheet at 360dp
    testWidgets('Renders day details bottom sheet at 360dp cleanly', (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 600 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHarvestedSheet());
      await tester.pumpAndSettle();

      expect(find.byType(DayDetailsBottomSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(DayDetailsBottomSheet),
        matchesGoldenFile('goldens/day_sheet_360dp_light.png'),
      );
    });

    // 4. Fuel bill records dialog at 360dp
    testWidgets('Renders fuel bill records dialog at 360dp cleanly', (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 600 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHarvestedDialog());
      await tester.pumpAndSettle();

      expect(find.byType(FuelBillRecordsDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(FuelBillRecordsDialog),
        matchesGoldenFile('goldens/fuel_bill_dialog_360dp_light.png'),
      );
    });
  });
}
