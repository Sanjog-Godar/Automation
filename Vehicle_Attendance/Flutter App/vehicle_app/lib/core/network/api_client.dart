import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';
import 'cookie_manager_provider.dart';
import 'supabase_rest_interceptor.dart';

/// Provider for the ApiClient instance.
final apiClientProvider = Provider<ApiClient>((ref) {
  final cookieJar = ref.watch(cookieJarProvider);
  return ApiClient(
    cookieJar: cookieJar,
    baseUrl: AppConfig.apiBaseUrl,
  );
});

/// Centralized HTTP client configured with Dio, CookieJar session management,
/// timeout controls, and 401 handling.
class ApiClient {
  final Dio dio;
  final CookieJar cookieJar;
  final VoidCallback? onUnauthorized;

  ApiClient({
    required this.cookieJar,
    String? baseUrl,
    Dio? customDio,
    this.onUnauthorized,
  }) : dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
                connectTimeout: AppConfig.connectTimeout,
                receiveTimeout: AppConfig.receiveTimeout,
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                extra: kIsWeb ? const {'withCredentials': true} : null,
                validateStatus: (status) => status != null && status < 500,
              ),
            ) {
    if (customDio == null) {
      dio.interceptors.addAll([
        SupabaseRestInterceptor(),
        if (!kIsWeb) CookieManager(cookieJar),
        AuthInterceptor(
          cookieJar: cookieJar,
          onUnauthorized: onUnauthorized,
        ),
        if (kDebugMode)
          LogInterceptor(
            requestBody: true,
            responseBody: true,
            logPrint: (obj) => debugPrint('[API] $obj'),
          ),
      ]);
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

