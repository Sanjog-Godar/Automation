import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicle_app/core/l10n/locale_provider.dart';
import 'package:vehicle_app/core/network/cookie_manager_provider.dart';
import 'package:vehicle_app/core/services/app_update_service.dart';
import 'package:vehicle_app/features/attendance/widgets/app_drawer.dart';
import 'package:vehicle_app/l10n/app_localizations.dart';

class MockAppUpdateService extends Mock implements AppUpdateService {}
class FakeBuildContext extends Fake implements BuildContext {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBuildContext());
  });
  group('AppUpdateDialog Widget Tests', () {
    testWidgets('Renders update dialog in Nepali with release notes and action buttons', (tester) async {
      const info = AppUpdateInfo(
        version: '1.3.0',
        buildNumber: 4,
        apkUrl: 'https://vehiclemgmt.vercel.app/bolero-attendance.apk',
        releaseNotes: 'Fixed senior UI bugs',
        releaseNotesNe: 'ठूला अक्षर र सुरक्षित किलोमिटर विवरण',
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ne'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppUpdateService().showUpdateDialog(context, info);
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check header and version
      expect(find.text('नयाँ अपडेट उपलब्ध छ'), findsOneWidget);
      expect(find.text('v1.3.0'), findsOneWidget);

      // Check Nepali release notes
      expect(find.text('ठूला अक्षर र सुरक्षित किलोमिटर विवरण'), findsOneWidget);

      // Check action buttons
      expect(find.text('अहिले अपडेट गर्नुहोस्'), findsOneWidget);
      expect(find.text('पछिको लागि'), findsOneWidget);

      // Tapping later dismisses dialog
      await tester.tap(find.text('पछिको लागि'));
      await tester.pumpAndSettle();
      expect(find.text('नयाँ अपडेट उपलब्ध छ'), findsNothing);
    });

    testWidgets('Renders update dialog in English', (tester) async {
      const info = AppUpdateInfo(
        version: '1.3.0',
        buildNumber: 4,
        apkUrl: 'https://vehiclemgmt.vercel.app/bolero-attendance.apk',
        releaseNotes: 'Fixed senior UI bugs',
        releaseNotesNe: 'ठूला अक्षर र सुरक्षित किलोमिटर विवरण',
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppUpdateService().showUpdateDialog(context, info);
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('New Update Available'), findsOneWidget);
      expect(find.text('v1.3.0'), findsOneWidget);
      expect(find.text('Fixed senior UI bugs'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
    });
  });

  group('AppDrawer Check for Updates Integration Tests', () {
    testWidgets('AppDrawer contains Check for Updates navigation item', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockService = MockAppUpdateService();
      when(() => mockService.checkForUpdateAndPrompt(any(), silent: any(named: 'silent')))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            cookieJarProvider.overrideWithValue(CookieJar()),
            appUpdateServiceProvider.overrideWithValue(mockService),
          ],
          child: const MaterialApp(
            locale: Locale('ne'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              drawer: AppDrawer(),
              body: Center(child: Text('Body')),
            ),
          ),
        ),
      );

      // Open Drawer
      final state = tester.state<ScaffoldState>(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      // Verify the check updates item is present in Nepali
      final checkUpdatesFinder = find.byKey(const Key('drawer_nav_check_updates'));
      await tester.scrollUntilVisible(checkUpdatesFinder, 100);
      expect(checkUpdatesFinder, findsOneWidget);
      expect(find.text('अपडेट जाँच गर्नुहोस्'), findsOneWidget);

      // Tap Check for Updates
      await tester.tap(checkUpdatesFinder);
      await tester.pumpAndSettle();

      // Drawer is closed and service was invoked
      verify(() => mockService.checkForUpdateAndPrompt(any(), silent: false)).called(1);
    });
  });
}
