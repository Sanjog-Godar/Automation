import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Application environment and build flavor configuration.
///
/// Base URLs and environment properties are supplied via `--dart-define`
/// or default to the live production server and Supabase backend.
///
/// Example:
///   `flutter run` (Connects to live software at https://vehiclemgmt.vercel.app)
///   `flutter run --dart-define=USE_LOCAL_BACKEND=true` (Connects to local dev server)
///   `flutter run --dart-define=API_BASE_URL=https://custom-backend.vercel.app`
class AppConfig {
  AppConfig._();

  /// Production live backend URL deployed on Vercel:
  static const String liveProductionBaseUrl = 'https://vehiclemgmt.vercel.app';

  /// Default local development URL:
  /// - On Web: `http://localhost:3000`
  /// - On Android emulator: `http://10.0.2.2:3000`
  /// - On physical device or iOS simulator: `http://localhost:3000`
  static String get defaultDevBaseUrl =>
      kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

  /// Supabase project URL powering the backend database and auth.
  static const String defaultSupabaseUrl =
      'https://jozvtiijteygfcbbbzgs.supabase.co';

  /// Active Supabase URL (can be overridden via `--dart-define=SUPABASE_URL=...`).
  static String get supabaseUrl {
    const defined = String.fromEnvironment('SUPABASE_URL');
    if (defined.isNotEmpty) return defined;
    return defaultSupabaseUrl;
  }

  /// Supabase public anonymous key safe for client-side authentication.
  static const String defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvenZ0aWlqdGV5Z2ZjYmJiemdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NjI5MzksImV4cCI6MjA4NDEzODkzOX0.7wJ42fpDU1U8qyrhLbOGj7A5Q6KpSiDtipfj7U90zro';

  /// Active Supabase anon key (can be overridden via `--dart-define=SUPABASE_ANON_KEY=...`).
  static String get supabaseAnonKey {
    const defined = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (defined.isNotEmpty) return defined;
    return defaultSupabaseAnonKey;
  }

  /// Active API Base URL.
  ///
  /// Priority:
  /// 1. `--dart-define=API_BASE_URL=...` if explicitly set.
  /// 2. If `--dart-define=USE_LOCAL_BACKEND=true`, uses [defaultDevBaseUrl].
  /// 3. Defaults to [liveProductionBaseUrl] for live backend connectivity.
  static String get apiBaseUrl {
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) return defined;

    const useLocal = bool.fromEnvironment('USE_LOCAL_BACKEND', defaultValue: false);
    if (useLocal) return defaultDevBaseUrl;

    return liveProductionBaseUrl;
  }

  /// HTTP connect timeout in milliseconds.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// HTTP receive timeout in milliseconds.
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Check whether the build is configured with cleartext HTTP (dev).
  static bool get isDev => apiBaseUrl.startsWith('http://');

  /// Check whether the build is configured with HTTPS (production / staging).
  static bool get isProd => apiBaseUrl.startsWith('https://');

  /// Default application language code on first launch (Nepali).
  static const String defaultLanguageCode = 'ne';

  /// Default application locale (Nepali).
  static const Locale defaultLocale = Locale('ne');

  /// Supported locales for the application.
  static const List<Locale> supportedLocales = [
    Locale('ne'),
    Locale('en'),
  ];

  /// SharedPreferences storage key for persistent language selection.
  static const String languagePrefsKey = 'selected_language_code';
}

