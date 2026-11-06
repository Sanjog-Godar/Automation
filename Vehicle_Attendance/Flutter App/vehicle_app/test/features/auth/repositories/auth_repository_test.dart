import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vehicle_app/core/config/app_config.dart';
import 'package:vehicle_app/core/network/api_client.dart';
import 'package:vehicle_app/features/auth/repositories/auth_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late CookieJar cookieJar;
  late AuthRepository authRepository;

  setUp(() {
    mockApiClient = MockApiClient();
    cookieJar = CookieJar();
    authRepository = AuthRepository(
      apiClient: mockApiClient,
      cookieJar: cookieJar,
    );
  });

  group('AuthRepository Tests', () {
    test('login succeeds and parses UserModel when API returns 200', () async {
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

    test('logout calls /api/auth/logout and clears cookie jar', () async {
      // Seed a cookie
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
    });

    test('hasValidSession returns true when sb-access-token exists and is valid', () async {
      final uri = Uri.parse(AppConfig.apiBaseUrl);
      await cookieJar.saveFromResponse(uri, [
        Cookie('sb-access-token', 'valid-jwt-token'),
      ]);

      final hasSession = await authRepository.hasValidSession();
      expect(hasSession, isTrue);
    });

    test('hasValidSession returns false when no sb-access-token cookie exists', () async {
      final hasSession = await authRepository.hasValidSession();
      expect(hasSession, isFalse);
    });
  });
}

