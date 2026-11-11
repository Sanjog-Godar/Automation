import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/locale_provider.dart';
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
  final preferences = ref.watch(sharedPreferencesProvider);
  return AuthRepository(
    apiClient: apiClient,
    cookieJar: cookieJar,
    preferences: preferences,
  );
});

/// Repository handling authentication API requests and cookie lifecycle.
class AuthRepository {
  final ApiClient apiClient;
  final CookieJar cookieJar;
  final SharedPreferences? preferences;

  AuthRepository({
    required this.apiClient,
    required this.cookieJar,
    this.preferences,
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
        final accessToken = (data['access_token'] as String?) ?? 'session-active';
        final userJson = data['user'] as Map<String, dynamic>?;
        final user = userJson != null
            ? UserModel.fromJson(userJson)
            : UserModel(id: 'unknown', email: email);

        // Seed CookieJar across all platforms
        final uri = Uri.parse(AppConfig.apiBaseUrl);
        await cookieJar.saveFromResponse(
          uri,
          [Cookie('sb-access-token', accessToken)],
        );

        // Persist session to SharedPreferences (survives app restarts on Android and reloads on Web)
        try {
          final prefs = preferences ?? await SharedPreferences.getInstance();
          await prefs.setBool('auth_session_active', true);
          await prefs.setString('auth_user_id', user.id);
          await prefs.setString('auth_user_email', user.email);
          await prefs.setString('auth_access_token', accessToken);
          await prefs.setBool('auth_remember_me', rememberMe);
        } catch (e) {
          debugPrint('Failed to persist session to SharedPreferences: $e');
        }

        return user;
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

  /// Terminates the user session by calling `/api/auth/logout` and clearing the cookie jar and local preferences.
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

      // Clear persisted session from SharedPreferences
      try {
        final prefs = preferences ?? await SharedPreferences.getInstance();
        await prefs.remove('auth_session_active');
        await prefs.remove('auth_user_id');
        await prefs.remove('auth_user_email');
        await prefs.remove('auth_access_token');
        await prefs.remove('auth_remember_me');
      } catch (e) {
        debugPrint('Failed to clear session from SharedPreferences during logout: $e');
      }
    }
  }

  /// Checks if a valid session exists in SharedPreferences or the CookieJar.
  Future<bool> hasValidSession() async {
    try {
      // 1. Check persistent SharedPreferences (works across Web localStorage & Android disk)
      final prefs = preferences ?? await SharedPreferences.getInstance();
      final isActive = prefs.getBool('auth_session_active') ?? false;
      final savedEmail = prefs.getString('auth_user_email');
      if (isActive && savedEmail != null && savedEmail.isNotEmpty) {
        // Ensure cookieJar is seeded with the token
        final token = prefs.getString('auth_access_token') ?? 'session-active';
        final uri = Uri.parse(AppConfig.apiBaseUrl);
        final cookies = await cookieJar.loadForRequest(uri);
        final hasCookie = cookies.any((c) => c.name == 'sb-access-token' && c.value.isNotEmpty);
        if (!hasCookie) {
          await cookieJar.saveFromResponse(uri, [Cookie('sb-access-token', token)]);
        }
        return true;
      }

      // 2. Fallback: inspect CookieJar directly
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
      debugPrint('Error inspecting session: $e');
      return false;
    }
  }

  /// Retrieves the persisted user from local storage, if present.
  UserModel? getPersistedUser() {
    try {
      final prefs = preferences;
      if (prefs != null) {
        final id = prefs.getString('auth_user_id');
        final email = prefs.getString('auth_user_email');
        if (email != null && email.isNotEmpty) {
          return UserModel(id: id ?? 'unknown', email: email);
        }
      }
    } catch (e) {
      debugPrint('Error reading persisted user: $e');
    }
    return null;
  }
}

