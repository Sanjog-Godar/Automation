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
import 'package:vehicle_app/core/theme/app_colors.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/repositories/attendance_repository.dart';
import 'package:vehicle_app/features/attendance/widgets/calendar_grid.dart';
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
  int attendanceFetchCount = 0;

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
    attendanceFetchCount = 0;
    when(() => mockAttendanceRepository.fetchMonthLogs(any(), any())).thenAnswer(
      (_) async {
        attendanceFetchCount++;
        return [
          const AttendanceLog(
            logDate: '2026-01-15',
            status: AttendanceStatus.present,
            extraTripIncome: 300,
            isUnselected: false,
          ),
        ];
      },
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

  Widget buildScreenLive({Locale locale = const Locale('en')}) {
    return ProviderScope(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(mockAttendanceRepository),
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        toastServiceProvider.overrideWithValue(mockToastService),
        fuelBillsRepositoryProvider.overrideWithValue(mockFuelBillsRepository),
        sharedPreferencesProvider.overrideWithValue(prefs),
        cookieJarProvider.overrideWithValue(CookieJar()),
        localeProvider.overrideWith(() => _LiveLocaleNotifier(locale)),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final activeLocale = ref.watch(localeProvider);
          return MaterialApp(
            locale: activeLocale,
            supportedLocales: const [Locale('en'), Locale('ne')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AttendanceScreen(),
          );
        },
      ),
    );
  }

  group('AttendanceScreen Widget Tests', () {
    testWidgets('Renders Vehicle number, monthly summary card, and navigation in English', (tester) async {
      await tester.pumpWidget(buildScreen(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text(AppConstants.vehicleNumber), findsOneWidget);
      expect(find.text('Net Income (Rs.)'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Performance'), findsOneWidget);
      // Positive net income (1200 wage + 300 extra trip) is rendered in green.
      expect(
        tester.widget<Text>(find.text('1,500')).style?.color,
        AppColors.netIncomePositiveOnHero,
      );
      expect(find.text('Present'), findsAtLeastNWidgets(1));
      expect(find.text('Replacement'), findsOneWidget);
      expect(find.text('Distance run'), findsOneWidget);

      // The calendar grid lives on the Calendar tab, not on Home.
      expect(find.byTooltip('Previous Month'), findsNothing);
      expect(find.byTooltip('Next Month'), findsNothing);
      expect(find.byKey(const Key('calendar_header_today_chip')), findsNothing);

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

      // Bottom navigation switches to the Calendar tab, which holds the grid.
      await tester.tap(find.byKey(const Key('bottom_nav_calendar')));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarGrid), findsOneWidget);
      expect(find.byTooltip('Previous Month'), findsOneWidget);
      expect(find.byTooltip('Next Month'), findsOneWidget);
      expect(find.byKey(const Key('calendar_header_today_chip')), findsOneWidget);
      expect(find.text('Net Income (Rs.)'), findsNothing);

      await tester.tap(find.byKey(const Key('bottom_nav_home')));
      await tester.pumpAndSettle();
      expect(find.text('Net Income (Rs.)'), findsOneWidget);
    });

    testWidgets('Renders properly localized in Nepali without any English text leakage', (tester) async {
      await tester.pumpWidget(buildScreen(locale: const Locale('ne')));
      await tester.pumpAndSettle();

      expect(find.text('खुद आम्दानी (रु.)'), findsOneWidget);
      expect(find.text('उपस्थिति'), findsOneWidget);
      expect(find.text('कार्य सम्पादन'), findsOneWidget);
      expect(find.text('उपस्थित'), findsOneWidget);
      expect(find.text('सट्टा'), findsOneWidget);
      expect(find.text('चलेको दुरी'), findsOneWidget);
      expect(find.text('ईन्धन बिल रेकर्ड'), findsOneWidget);
      expect(find.byKey(const Key('quick_action_generate_fuel_bill')), findsOneWidget);
      expect(find.text('ईन्धन बिल बनाउनुहोस्'), findsOneWidget);
      expect(find.text('रिपोर्ट डाउनलोड'), findsOneWidget);
    });

    testWidgets('Switching language refetches the API and keeps the loaded data', (tester) async {
      await tester.pumpWidget(buildScreenLive());
      await tester.pumpAndSettle();

      expect(attendanceFetchCount, 1);
      expect(find.text('Net Income (Rs.)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('dashboard_drawer_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('drawer_language_ne')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Language switched, a fresh API call was made, and the values survived.
      expect(find.text('खुद आम्दानी (रु.)'), findsOneWidget);
      expect(attendanceFetchCount, 2);
      expect(find.text('१,५००'), findsOneWidget);
      expect(find.text('उपस्थित'), findsOneWidget);
    });

    testWidgets('Bottom navigation switches between Home and Calendar tabs', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bottom_nav_home')), findsOneWidget);
      expect(find.byKey(const Key('bottom_nav_calendar')), findsOneWidget);
      expect(find.text('Net Income (Rs.)'), findsOneWidget);
      expect(find.byType(CalendarGrid), findsNothing);

      await tester.tap(find.byKey(const Key('bottom_nav_calendar')));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarGrid), findsOneWidget);
      expect(find.text('Net Income (Rs.)'), findsNothing);

      await tester.tap(find.byKey(const Key('bottom_nav_home')));
      await tester.pumpAndSettle();

      expect(find.text('Net Income (Rs.)'), findsOneWidget);
      expect(find.byType(CalendarGrid), findsNothing);
    });
  });
}

class _LiveLocaleNotifier extends LocaleNotifier {
  final Locale _initial;
  _LiveLocaleNotifier(this._initial);

  @override
  Locale build() => _initial;
}

class _FixedLocaleNotifier extends LocaleNotifier {
  final Locale _fixed;
  _FixedLocaleNotifier(this._fixed);

  @override
  Locale build() => _fixed;
}
