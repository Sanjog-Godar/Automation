import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/l10n/locale_provider.dart';
import 'core/network/cookie_manager_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent CookieJar across restarts (or in-memory for web)
  final cookieJar = await initializeCookieJar();

  // Initialize SharedPreferences prior to first frame (prevents locale flash)
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        cookieJarProvider.overrideWithValue(cookieJar),
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const VehicleAttendanceApp(),
    ),
  );
}
