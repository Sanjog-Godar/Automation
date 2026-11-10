import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Branded startup screen painted immediately at launch and while the stored
/// session is verified. It exists so the app never shows a blank white window
/// while cookies, preferences, or the auth check are still in flight.
class AppSplashBody extends StatelessWidget {
  const AppSplashBody({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.heroNavyStart,
            AppColors.heroNavyMid,
            AppColors.heroNavyEnd,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppConstants.vehicleNumber,
              style: const TextStyle(
                fontFamily: 'Mukta',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standalone app shell used before the provider scope and router are ready.
class AppSplashScreen extends StatelessWidget {
  const AppSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(body: AppSplashBody()),
    );
  }
}
