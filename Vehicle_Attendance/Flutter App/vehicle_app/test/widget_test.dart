import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicle_app/app.dart';
import 'package:vehicle_app/core/l10n/locale_provider.dart';
import 'package:vehicle_app/core/network/cookie_manager_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App initializes with default Nepali and switches to English via toggle', (WidgetTester tester) async {
    final cookieJar = CookieJar();
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cookieJarProvider.overrideWithValue(cookieJar),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const VehicleAttendanceApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Default locale on first launch is Nepali
    expect(find.text('सवारी साधन उपस्थिति'), findsOneWidget);
    expect(find.text('ड्यासबोर्ड हेर्न लग-इन गर्नुहोस्'), findsOneWidget);
    expect(find.text('लग-इन गर्नुहोस्'), findsOneWidget);

    // Toggle language chip to English
    await tester.tap(find.byKey(const Key('login_language_toggle')));
    await tester.pumpAndSettle();

    // Now in English
    expect(find.text('Vehicle Attendance'), findsOneWidget);
    expect(find.text('Sign in to access your dashboard'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
