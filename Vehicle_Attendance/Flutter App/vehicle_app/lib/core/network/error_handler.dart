import 'package:dio/dio.dart';
import '../../l10n/app_localizations.dart';

/// Centralized mapper that converts raw server error payloads, HTTP status codes,
/// and network exceptions into user-friendly localized messages.
///
/// Prevents raw English server error text from leaking into Nepali mode.
class ErrorHandler {
  ErrorHandler._();

  /// Maps any caught exception or error object to the appropriate localized message.
  static String getLocalizedErrorMessage(Object error, AppLocalizations l10n) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return l10n.toast_networkError;
      }

      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return l10n.error_invalidCredentials;
      } else if (statusCode == 403) {
        return l10n.error_unauthorized;
      } else if (statusCode != null && statusCode >= 500) {
        return l10n.error_serverError;
      }

      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final serverMsg = data['error']?.toString() ?? data['message']?.toString();
        if (serverMsg != null) {
          final lower = serverMsg.toLowerCase();
          if (lower.contains('invalid') ||
              lower.contains('credential') ||
              lower.contains('password') ||
              lower.contains('email')) {
            return l10n.error_invalidCredentials;
          }
          if (lower.contains('unauthorized') ||
              lower.contains('session') ||
              lower.contains('token')) {
            return l10n.error_sessionExpired;
          }
        }
      }
    }

    final str = error.toString().toLowerCase();
    if (str.contains('invalid') || str.contains('credential') || str.contains('password')) {
      return l10n.error_invalidCredentials;
    }
    if (str.contains('network') || str.contains('socket') || str.contains('connection')) {
      return l10n.toast_networkError;
    }

    return l10n.toast_genericError;
  }
}

