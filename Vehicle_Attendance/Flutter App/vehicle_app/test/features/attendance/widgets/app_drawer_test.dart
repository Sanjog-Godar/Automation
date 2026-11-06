import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicle_app/core/l10n/locale_provider.dart';
import 'package:vehicle_app/core/network/cookie_manager_provider.dart';
import 'package:vehicle_app/features/attendance/widgets/app_drawer.dart';
import 'package:vehicle_app/l10n/app_localizations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableDrawer(WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      locale: locale,
      supportedLocales: const [
        Locale('ne'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Scaffold(
        drawer: AppDrawer(),
        body: Center(child: Text('Main Body')),
      ),
    );
  }

  testWidgets('AppDrawer renders bilingual language header and switches languages cleanly', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          cookieJarProvider.overrideWithValue(CookieJar()),
        ],
        child: Consumer(
          builder: (context, ref, _) => buildTestableDrawer(ref),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open drawer
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    // 1. Verify "Language / भाषा" header exists (allowed bilingual exception)
    expect(find.text('Language / भाषा'), findsOneWidget);

    // 2. Verify language choices
    expect(find.byKey(const Key('drawer_language_en')), findsOneWidget);
    expect(find.byKey(const Key('drawer_language_ne')), findsOneWidget);

    // In initial Nepali state, verify Nepali strings are displayed in navigation
    expect(find.text('ड्यासबोर्ड'), findsOneWidget);
    expect(find.text('ईन्धन बिल रेकर्ड'), findsOneWidget);
    expect(find.text('बाहिरिनुहोस्'), findsOneWidget);

    // 3. Tap English option
    await tester.tap(find.byKey(const Key('drawer_language_en')));
    // Tap pops drawer after 180ms delay, pump with duration
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    // Reopen drawer to inspect updated language
    final scaffoldState2 = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState2.openDrawer();
    await tester.pumpAndSettle();

    // Now drawer should be in English
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Fuel Bill Records'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);

    // 4. Tap Nepali option again
    await tester.tap(find.byKey(const Key('drawer_language_ne')));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    // Reopen drawer
    final scaffoldState3 = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState3.openDrawer();
    await tester.pumpAndSettle();

    // Now drawer should be back in Nepali
    expect(find.text('ड्यासबोर्ड'), findsOneWidget);
    expect(find.text('ईन्धन बिल रेकर्ड'), findsOneWidget);
    expect(find.text('बाहिरिनुहोस्'), findsOneWidget);
  });
}
