import 'package:flutter/foundation.dart';

/// Application environment and build flavor configuration.
///
/// Base URLs and environment properties are supplied via `--dart-define`.
/// Example:
///   `flutter run --dart-define=API_BASE_URL=https://my-backend.vercel.app`
class AppConfig {
  AppConfig._();

  /// Default local development URL:
  /// - On Web: `http://localhost:3000`
  /// - On Android emulator: `http://10.0.2.2:3000`
  /// - On physical device or iOS simulator: `http://localhost:3000`
  static String get defaultDevBaseUrl =>
      kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

  /// Active API Base URL.
  static String get apiBaseUrl {
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) return defined;
    return defaultDevBaseUrl;
  }

  /// HTTP connect timeout in milliseconds.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// HTTP receive timeout in milliseconds.
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Check whether the build is configured with cleartext HTTP (dev).
  static bool get isDev => apiBaseUrl.startsWith('http://');

  /// Check whether the build is configured with HTTPS (production / staging).
  static bool get isProd => apiBaseUrl.startsWith('https://');
}

