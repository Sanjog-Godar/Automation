import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/locale_provider.dart';
import '../theme/app_colors.dart';

/// Global scaffold messenger key used by ToastService to display
/// SnackBars without requiring an explicit BuildContext.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Provider for ToastService singleton, dynamically aware of active [Locale].
///
/// The locale is resolved lazily (instead of `ref.watch`-ing it here) so that a
/// language switch does not recreate this service and, through it, reset the
/// state of every controller that depends on it.
final toastServiceProvider = Provider<ToastService>((ref) {
  return ToastService(localeResolver: () => ref.read(localeProvider));
});

/// Service for displaying toast notifications with strict single-language rendering.
/// In Nepali mode, only [nepaliMessage] is shown; in English mode, only [message] is shown.
class ToastService {
  final Locale? fixedLocale;
  final Locale Function()? localeResolver;

  ToastService({Locale? locale, this.localeResolver}) : fixedLocale = locale;

  /// Active application locale, resolved on every read so a single instance
  /// always reflects the current language selection.
  Locale? get locale => localeResolver?.call() ?? fixedLocale;

  void showSuccess(
    String message, {
    String? nepaliMessage,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      message: message,
      nepaliMessage: nepaliMessage,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_outline,
      duration: duration,
    );
  }

  void showError(
    String message, {
    String? nepaliMessage,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showSnackBar(
      message: message,
      nepaliMessage: nepaliMessage,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline,
      duration: duration,
    );
  }

  void showInfo(
    String message, {
    String? nepaliMessage,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      message: message,
      nepaliMessage: nepaliMessage,
      backgroundColor: AppColors.primary,
      icon: Icons.info_outline,
      duration: duration,
    );
  }

  void _showSnackBar({
    required String message,
    String? nepaliMessage,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    final state = scaffoldMessengerKey.currentState;
    if (state == null) return;

    state.hideCurrentSnackBar();

    // Render strictly ONE language based on active application locale.
    final isNepali = locale?.languageCode == 'ne';
    final displayText = (isNepali && nepaliMessage != null && nepaliMessage.isNotEmpty)
        ? nepaliMessage
        : message;

    state.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
