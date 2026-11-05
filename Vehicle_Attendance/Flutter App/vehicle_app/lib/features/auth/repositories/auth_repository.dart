import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/cookie_manager_provider.dart';
import '../models/user_model.dart';

/// Exception thrown when authentication operations fail.
class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Provider for AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final cookieJar = ref.watch(cookieJarProvider);
  return AuthRepository(
    apiClient: apiClient,
    cookieJar: cookieJar,
  );
});

/// Repository handling authentication API requests and cookie lifecycle.
class AuthRepository {
  final ApiClient apiClient;
  final CookieJar cookieJar;

  AuthRepository({
    required this.apiClient,
    required this.cookieJar,
  });

  /// Authenticates with email and password, mirroring Next.js `/api/auth/login`.
  /// Cookies are automatically intercepted and persisted by DioCookieManager.
  Future<UserModel> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
          'rememberMe': rememberMe,
        },
      );

      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        if (kIsWeb) {
          final uri = Uri.parse(AppConfig.apiBaseUrl);
          await cookieJar.saveFromResponse(
            uri,
            [Cookie('sb-access-token', 'web-session-active')],
          );
        }

        final userJson = data['user'] as Map<String, dynamic>?;
        if (userJson != null) {
          return UserModel.fromJson(userJson);
        }
        return UserModel(id: 'unknown', email: email);
      }

      final errorMsg = data?['error'] as String? ?? 'Login failed. Please check your credentials.';
      throw AuthException(errorMsg, response.statusCode);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final errorMsg = (e.response?.data as Map)['error'] as String?;
        if (errorMsg != null && errorMsg.isNotEmpty) {
          throw AuthException(errorMsg, e.response?.statusCode);
        }
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const AuthException('Unable to reach server. Please check your connection.');
      }
      throw AuthException(e.message ?? 'An unexpected network error occurred.');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString());
    }
  }

  /// Terminates the user session by calling `/api/auth/logout` and clearing the cookie jar.
  Future<void> logout() async {
    try {
      await apiClient.post('/api/auth/logout');
    } catch (e) {
      debugPrint('Logout API request returned an error: $e');
    } finally {
      // Regardless of whether the network call succeeded, clear local cookies
      try {
        await cookieJar.deleteAll();
      } catch (e) {
        debugPrint('Failed to delete cookies during logout: $e');
      }
    }
  }

  /// Checks if a valid `sb-access-token` session cookie exists in the CookieJar,
  /// mirroring the check in `middleware.ts`.
  Future<bool> hasValidSession() async {
    try {
      final uri = Uri.parse(AppConfig.apiBaseUrl);
      final cookies = await cookieJar.loadForRequest(uri);

      for (final cookie in cookies) {
        if (cookie.name == 'sb-access-token' && cookie.value.isNotEmpty) {
          // If cookie has an expiration date, verify it hasn't passed
          if (cookie.expires != null && cookie.expires!.isBefore(DateTime.now())) {
            continue;
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error inspecting session cookies: $e');
      return false;
    }
  }
}

