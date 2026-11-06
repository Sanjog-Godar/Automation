import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicle_app/core/config/app_config.dart';
import 'package:vehicle_app/core/config/app_constants.dart';
import 'package:vehicle_app/core/l10n/locale_provider.dart';
import 'package:vehicle_app/core/network/cookie_manager_provider.dart';
import 'package:vehicle_app/core/services/toast_service.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/repositories/attendance_repository.dart';
import 'package:vehicle_app/features/attendance/views/attendance_screen.dart';
import 'package:vehicle_app/features/auth/repositories/auth_repository.dart';
import 'package:vehicle_app/features/fuel_bills/models/fuel_bill.dart';
import 'package:vehicle_app/features/fuel_bills/repositories/fuel_bills_repository.dart';
import 'package:vehicle_app/l10n/app_localizations.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockToastService extends Mock implements ToastService {}
class MockFuelBillsRepository extends Mock implements FuelBillsRepository {}

void main() {
  late MockAttendanceRepository mockAttendanceRepository;
  late MockAuthRepository mockAuthRepository;
  late MockToastService mockToastService;
  late MockFuelBillsRepository mockFuelBillsRepository;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      AppConfig.languagePrefsKey: 'en',
    });
    prefs = await SharedPreferences.getInstance();

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

  Widget buildScreen({Locale locale = const Locale('en')}) {
    return ProviderScope(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(mockAttendanceRepository),
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        toastServiceProvider.overrideWithValue(mockToastService),
        fuelBillsRepositoryProvider.overrideWithValue(mockFuelBillsRepository),
        sharedPreferencesProvider.overrideWithValue(prefs),
        cookieJarProvider.overrideWithValue(CookieJar()),
        localeProvider.overrideWith(() => _FixedLocaleNotifier(locale)),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ne')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AttendanceScreen(),
      ),
    );
  }

  group('AttendanceScreen Widget Tests', () {
    testWidgets('Renders Vehicle number, monthly summary card, and navigation in English', (tester) async {
      await tester.pumpWidget(buildScreen(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text(AppConstants.vehicleNumber), findsOneWidget);
      expect(find.text('Monthly Summary'), findsOneWidget);
      expect(find.text('Present Days'), findsOneWidget);
      expect(find.text('Replacement Days'), findsOneWidget);
      expect(find.text('Total KM Run'), findsOneWidget);
      expect(find.text('Net Income (Rs.)'), findsOneWidget);
      expect(find.byTooltip('Previous Month'), findsOneWidget);
      expect(find.byTooltip('Next Month'), findsOneWidget);
      expect(find.byKey(const Key('calendar_header_today_chip')), findsOneWidget);

      // Verify Fuel Bill Records tile is rendered and tapping it opens dialog
      final tileFinder = find.byKey(const Key('fuel_bill_records_tile'));
      await tester.ensureVisible(tileFinder);
      await tester.pumpAndSettle();
      expect(tileFinder, findsOneWidget);
      expect(find.text('Fuel Bill Records'), findsOneWidget);
      expect(find.text('Last bill ended: 2026-02-12'), findsOneWidget);

      await tester.tap(tileFinder);
      await tester.pumpAndSettle();
      expect(find.text('Last Fuel Bill End Date'), findsOneWidget);
      await tester.tap(find.byKey(const Key('fuel_bill_dialog_close')));
      await tester.pumpAndSettle();

      // Verify Quick Action tiles are rendered
      final fuelBillAction = find.byKey(const Key('quick_action_generate_fuel_bill'));
      await tester.ensureVisible(fuelBillAction);
      await tester.pumpAndSettle();
      expect(fuelBillAction, findsOneWidget);
      expect(find.text('Generate Fuel Bill'), findsOneWidget);
      expect(find.text('Download Report'), findsOneWidget);
    });

    testWidgets('Renders properly localized in Nepali without any English text leakage', (tester) async {
      await tester.pumpWidget(buildScreen(locale: const Locale('ne')));
      await tester.pumpAndSettle();

      expect(find.text('मासिक सारांश'), findsOneWidget);
      expect(find.text('उपस्थित दिन'), findsOneWidget);
      expect(find.text('सट्टा दिन'), findsOneWidget);
      expect(find.text('जम्मा किलोमिटर'), findsOneWidget);
      expect(find.text('खुद आम्दानी (रु.)'), findsOneWidget);
      expect(find.text('ईन्धन बिल रेकर्ड'), findsOneWidget);
      expect(find.byKey(const Key('quick_action_generate_fuel_bill')), findsOneWidget);
      expect(find.text('ईन्धन बिल बनाउनुहोस्'), findsOneWidget);
      expect(find.text('रिपोर्ट डाउनलोड'), findsOneWidget);
    });
  });
}

class _FixedLocaleNotifier extends LocaleNotifier {
  final Locale _fixed;
  _FixedLocaleNotifier(this._fixed);

  @override
  Locale build() => _fixed;
}
