import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/l10n/locale_provider.dart';
import 'core/network/cookie_manager_provider.dart';
import 'core/widgets/app_splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Paint a frame immediately. Startup dependencies are loaded behind the
  // splash instead of blocking `runApp`, which used to leave a blank white
  // window (and a permanently white app if any of them threw).
  runApp(const AppBootstrap());
}

/// Loads startup dependencies in the background and hands the app over to the
/// provider scope only once they are available.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<_StartupDependencies> _startup = _loadStartupDependencies();

  Future<_StartupDependencies> _loadStartupDependencies() async {
    CookieJar cookieJar;
    try {
      cookieJar = await initializeCookieJar();
    } catch (e) {
      // Never block startup on cookie storage: fall back to an in-memory jar.
      debugPrint('CookieJar initialization failed; using in-memory jar: $e');
      cookieJar = CookieJar();
    }

    SharedPreferences? preferences;
    try {
      preferences = await SharedPreferences.getInstance();
    } catch (e) {
      // The locale provider tolerates a null instance (defaults to Nepali).
      debugPrint('SharedPreferences initialization failed: $e');
    }

    return _StartupDependencies(
      cookieJar: cookieJar,
      preferences: preferences,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartupDependencies>(
      future: _startup,
      builder: (context, snapshot) {
        final dependencies = snapshot.data;
        if (dependencies == null) {
          return const AppSplashScreen();
        }

        return ProviderScope(
          overrides: [
            cookieJarProvider.overrideWithValue(dependencies.cookieJar),
            if (dependencies.preferences != null)
              sharedPreferencesProvider.overrideWithValue(dependencies.preferences!),
          ],
          child: const VehicleAttendanceApp(),
        );
      },
    );
  }
}

class _StartupDependencies {
  final CookieJar cookieJar;
  final SharedPreferences? preferences;

  const _StartupDependencies({
    required this.cookieJar,
    required this.preferences,
  });
}
