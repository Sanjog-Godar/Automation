import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/l10n/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/toast_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_splash.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/models/auth_state.dart';
import 'l10n/app_localizations.dart';

/// Root application widget configuring Theme, Localization, Router, and Toast service.
class VehicleAttendanceApp extends ConsumerWidget {
  const VehicleAttendanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Vehicle Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: AppConfig.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      scaffoldMessengerKey: scaffoldMessengerKey,
      builder: (context, child) {
        // Keep the branded splash on screen while the stored session is being
        // verified, so startup never flashes a blank frame or the login screen.
        if (ref.watch(authControllerProvider).status == AuthStatus.initial) {
          return const AppSplashBody();
        }
        return child ?? const SizedBox.shrink();
      },
      routerConfig: router,
    );
  }
}
