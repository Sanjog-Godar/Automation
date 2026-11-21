import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicle_app/core/l10n/locale_provider.dart';
import 'package:vehicle_app/core/network/cookie_manager_provider.dart';
import 'package:vehicle_app/core/theme/font_scale_provider.dart';
import 'package:vehicle_app/features/attendance/models/attendance_log.dart';
import 'package:vehicle_app/features/attendance/widgets/app_drawer.dart';
import 'package:vehicle_app/features/attendance/widgets/day_details_bottom_sheet.dart';
import 'package:vehicle_app/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FontScaleProvider Unit Tests', () {
    test('Defaults to normal (1.0x) scale when unconfigured', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: Container(),
      );

      final element = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      expect(element.read(fontScaleProvider), AppFontScale.normal);
      expect(element.read(fontScaleProvider).scaleFactor, 1.0);
    });

    test('Loads saved font scale from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'app_font_scale': 'senior',
      });
      final prefs = await SharedPreferences.getInstance();
      final element = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      expect(element.read(fontScaleProvider), AppFontScale.senior);
      expect(element.read(fontScaleProvider).scaleFactor, 1.35);
    });

    test('setScale updates state and persists choice', () async {
      final prefs = await SharedPreferences.getInstance();
      final element = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await element.read(fontScaleProvider.notifier).setScale(AppFontScale.large);
      expect(element.read(fontScaleProvider), AppFontScale.large);
      expect(element.read(fontScaleProvider).scaleFactor, 1.18);
      expect(prefs.getString('app_font_scale'), 'large');

      await element.read(fontScaleProvider.notifier).setScale(AppFontScale.senior);
      expect(element.read(fontScaleProvider), AppFontScale.senior);
      expect(element.read(fontScaleProvider).scaleFactor, 1.35);
      expect(prefs.getString('app_font_scale'), 'senior');
    });
  });

  group('Senior UI Accessibility & Font Scale Integration', () {
    testWidgets('AppDrawer renders font scale options and allows switching to Senior size', (tester) async {
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            cookieJarProvider.overrideWithValue(CookieJar()),
          ],
          child: const MaterialApp(
            locale: Locale('ne'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              drawer: AppDrawer(),
              body: Center(child: Text('Test Body')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open Drawer
      final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Verify Text Size section exists
      expect(find.byKey(const Key('drawer_font_scale_normal')), findsOneWidget);
      expect(find.byKey(const Key('drawer_font_scale_large')), findsOneWidget);
      expect(find.byKey(const Key('drawer_font_scale_senior')), findsOneWidget);

      // Tap Senior (धेरै ठूलो)
      await tester.tap(find.byKey(const Key('drawer_font_scale_senior')));
      await tester.pumpAndSettle();

      expect(prefs.getString('app_font_scale'), 'senior');
    });

    testWidgets('DayDetailsBottomSheet renders senior status buttons and clear action buttons cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ne'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.35), // Senior scale
            ),
            child: Scaffold(
              body: DayDetailsBottomSheet(
                dayNumber: 15,
                bsYear: 2083,
                bsMonthIndex: 6,
                isSaving: false,
                log: const AttendanceLog(
                  logDate: '2026-10-15',
                  status: AttendanceStatus.present,
                  kmStart: 12000,
                  kmEnd: 12050,
                  kmTotal: 50,
                  extraTripIncome: 500,
                  isUnselected: false,
                ),
                onStatusChange: (_, __) {},
                onOpenKm: (_) {},
                onOpenExtraTrip: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Status buttons rendered with icons and senior sizing
      expect(find.byKey(const Key('sheet_status_btn_present')), findsOneWidget);
      expect(find.byKey(const Key('sheet_status_btn_holiday')), findsOneWidget);
      expect(find.byKey(const Key('sheet_status_btn_replace')), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.beach_access_rounded), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);

      // Verify no RenderFlex overflow happened
      expect(tester.takeException(), isNull);
    });
  });
}
