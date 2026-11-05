import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Minimal authentication interceptor mirroring the Next.js auth model.
///
/// If any backend response returns HTTP 401 Unauthorized:
/// 1. Clears session cookies in CookieJar.
/// 2. Invokes [onUnauthorized] callback to update application auth state and redirect to /login.
///
/// Extensibility Note:
/// If the backend is hardened in the future to require `Authorization: Bearer <token>`,
/// adding it into onRequest() is localized to this file.
class AuthInterceptor extends Interceptor {
  final CookieJar cookieJar;
  final VoidCallback? onUnauthorized;

  AuthInterceptor({
    required this.cookieJar,
    this.onUnauthorized,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Currently, backend relies purely on cookies passed via DioCookieManager.
    // If Bearer token header is required in future hardening, attach it here:
    // options.headers['Authorization'] = 'Bearer $token';
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      debugPrint('AuthInterceptor: Received 401 Unauthorized. Clearing cookies.');
      try {
        await cookieJar.deleteAll();
      } catch (e) {
        debugPrint('Error clearing cookies on 401: $e');
      }

      onUnauthorized?.call();
    }
    super.onError(err, handler);
  }
}
