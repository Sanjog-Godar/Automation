import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicle_app/core/config/app_config.dart';
import 'package:vehicle_app/core/network/api_client.dart';
import 'package:vehicle_app/features/auth/repositories/auth_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late CookieJar cookieJar;
  late SharedPreferences prefs;
  late AuthRepository authRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockApiClient = MockApiClient();
    cookieJar = CookieJar();
    authRepository = AuthRepository(
      apiClient: mockApiClient,
      cookieJar: cookieJar,
      preferences: prefs,
    );
  });

  group('AuthRepository Tests', () {
    test('login succeeds, parses UserModel, and persists session to storage and cookieJar', () async {
      when(
        () => mockApiClient.post<Map<String, dynamic>>(
          '/api/auth/login',
          data: {
            'email': 'driver@example.com',
            'password': 'password123',
            'rememberMe': true,
          },
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 200,
          data: {
            'message': 'Login successful',
            'user': {
              'id': 'usr-123',
              'email': 'driver@example.com',
            },
            'access_token': 'jwt-access-token-xyz',
          },
        ),
      );

      final user = await authRepository.login(
        email: 'driver@example.com',
        password: 'password123',
        rememberMe: true,
      );

      expect(user.id, 'usr-123');
      expect(user.email, 'driver@example.com');

      // Verify persistent storage
      expect(prefs.getBool('auth_session_active'), isTrue);
      expect(prefs.getString('auth_user_id'), 'usr-123');
      expect(prefs.getString('auth_user_email'), 'driver@example.com');
      expect(prefs.getString('auth_access_token'), 'jwt-access-token-xyz');
      expect(prefs.getBool('auth_remember_me'), isTrue);

      // Verify CookieJar has the token
      final cookies = await cookieJar.loadForRequest(Uri.parse(AppConfig.apiBaseUrl));
      expect(cookies.any((c) => c.name == 'sb-access-token' && c.value == 'jwt-access-token-xyz'), isTrue);

      // Verify getPersistedUser
      final persisted = authRepository.getPersistedUser();
      expect(persisted?.id, 'usr-123');
      expect(persisted?.email, 'driver@example.com');
    });

    test('login throws AuthException when API returns 401 with error message', () async {
      when(
        () => mockApiClient.post<Map<String, dynamic>>(
          '/api/auth/login',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 401,
          data: {'error': 'Invalid email or password'},
        ),
      );

      expect(
        () => authRepository.login(
          email: 'wrong@example.com',
          password: 'wrongpassword',
          rememberMe: false,
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Invalid email or password',
          ),
        ),
      );
    });

    test('logout calls /api/auth/logout, clears cookie jar and clears SharedPreferences', () async {
      // Seed storage and cookie
      await prefs.setBool('auth_session_active', true);
      await prefs.setString('auth_user_id', 'usr-123');
      await prefs.setString('auth_user_email', 'driver@example.com');

      final uri = Uri.parse(AppConfig.apiBaseUrl);
      await cookieJar.saveFromResponse(uri, [
        Cookie('sb-access-token', 'token-abc'),
      ]);

      when(() => mockApiClient.post('/api/auth/logout')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/auth/logout'),
          statusCode: 200,
        ),
      );

      await authRepository.logout();

      final remaining = await cookieJar.loadForRequest(uri);
      expect(remaining.isEmpty, isTrue);

      expect(prefs.getBool('auth_session_active'), isNull);
      expect(prefs.getString('auth_user_id'), isNull);
      expect(prefs.getString('auth_user_email'), isNull);
    });

    test('hasValidSession returns true when active session exists in SharedPreferences', () async {
      await prefs.setBool('auth_session_active', true);
      await prefs.setString('auth_user_id', 'usr-123');
      await prefs.setString('auth_user_email', 'driver@example.com');
      await prefs.setString('auth_access_token', 'stored-token');

      final hasSession = await authRepository.hasValidSession();
      expect(hasSession, isTrue);

      // It also re-seeds the CookieJar
      final uri = Uri.parse(AppConfig.apiBaseUrl);
      final cookies = await cookieJar.loadForRequest(uri);
      expect(cookies.any((c) => c.name == 'sb-access-token' && c.value == 'stored-token'), isTrue);
    });

    test('hasValidSession returns true when fallback sb-access-token cookie exists in CookieJar', () async {
      final uri = Uri.parse(AppConfig.apiBaseUrl);
      await cookieJar.saveFromResponse(uri, [
        Cookie('sb-access-token', 'valid-jwt-token'),
      ]);

      final hasSession = await authRepository.hasValidSession();
      expect(hasSession, isTrue);
    });

    test('hasValidSession returns false when neither preferences nor cookie exists', () async {
      final hasSession = await authRepository.hasValidSession();
      expect(hasSession, isFalse);
    });
  });
}
