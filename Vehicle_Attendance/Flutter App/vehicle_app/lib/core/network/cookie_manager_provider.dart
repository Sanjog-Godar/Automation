import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Provider for the application's CookieJar instance.
/// Persists cookies on native platforms (Android, iOS) across app restarts,
/// and provides in-memory cookie storage on web.
final cookieJarProvider = Provider<CookieJar>((ref) {
  throw UnimplementedError('cookieJarProvider must be initialized in main()');
});

/// Factory function to initialize the CookieJar during app startup.
Future<CookieJar> initializeCookieJar() async {
  if (kIsWeb) {
    return CookieJar();
  }

  try {
    final docsDir = await getApplicationDocumentsDirectory();
    final cookieDir = Directory('${docsDir.path}/.cookies');
    if (!await cookieDir.exists()) {
      await cookieDir.create(recursive: true);
    }
    return PersistCookieJar(
      storage: FileStorage(cookieDir.path),
      ignoreExpires: false,
    );
  } catch (e) {
    debugPrint('Failed to initialize PersistCookieJar: $e. Falling back to memory CookieJar.');
    return CookieJar();
  }
}

