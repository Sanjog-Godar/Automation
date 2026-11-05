import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';

/// Global scaffold messenger key used by ToastService to display
/// SnackBars without requiring an explicit BuildContext.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Provider for ToastService singleton.
final toastServiceProvider = Provider<ToastService>((ref) {
  return ToastService();
});

/// Service for displaying toast notifications with bilingual (English/Nepali) capability.
class ToastService {
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

    final displayText = nepaliMessage != null && nepaliMessage.isNotEmpty
        ? '$message ($nepaliMessage)'
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

