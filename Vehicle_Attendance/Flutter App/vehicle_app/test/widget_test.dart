import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/app.dart';
import 'package:vehicle_app/core/network/cookie_manager_provider.dart';

void main() {
  testWidgets('App initializes and routes unauthenticated user to LoginScreen', (WidgetTester tester) async {
    final cookieJar = CookieJar();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cookieJarProvider.overrideWithValue(cookieJar),
        ],
        child: const VehicleAttendanceApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Vehicle Attendance'), findsOneWidget);
    expect(find.text('Sign in to access your dashboard'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
