import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vehicle_app/core/config/app_config.dart';
import 'package:vehicle_app/core/services/app_update_service.dart';
import 'package:vehicle_app/core/services/toast_service.dart';

class MockDio extends Mock implements Dio {}
class MockToastService extends Mock implements ToastService {}

void main() {
  group('AppUpdateService Unit Tests', () {
    late MockDio mockDio;
    late MockToastService mockToastService;
    late AppUpdateService service;

    setUp(() {
      mockDio = MockDio();
      mockToastService = MockToastService();
      service = AppUpdateService(
        dio: mockDio,
        toastService: mockToastService,
      );
    });

    test('AppUpdateInfo.fromJson parses correctly with sensible fallbacks', () {
      final json = {
        'version': '1.3.0',
        'buildNumber': 4,
        'apkUrl': 'https://example.com/app.apk',
        'releaseNotes': 'New feature added',
        'releaseNotesNe': 'नयाँ सुविधा थपियो',
        'releaseDate': '2026-12-01',
      };

      final info = AppUpdateInfo.fromJson(json);
      expect(info.version, '1.3.0');
      expect(info.buildNumber, 4);
      expect(info.apkUrl, 'https://example.com/app.apk');
      expect(info.releaseNotes, 'New feature added');
      expect(info.releaseNotesNe, 'नयाँ सुविधा थपियो');
      expect(info.releaseDate, '2026-12-01');
    });

    test('checkForUpdate returns AppUpdateInfo when remote buildNumber is strictly greater', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/version.json'),
          statusCode: 200,
          data: {
            'version': '1.3.0',
            'buildNumber': AppConfig.currentBuildNumber + 1,
            'apkUrl': 'https://vehiclemgmt.vercel.app/bolero-attendance.apk',
            'releaseNotes': 'Important bugfix',
            'releaseNotesNe': 'महत्वपूर्ण सुधार',
          },
        ),
      );

      final update = await service.checkForUpdate();
      expect(update, isNotNull);
      expect(update!.buildNumber, AppConfig.currentBuildNumber + 1);
      expect(update.version, '1.3.0');
    });

    test('checkForUpdate returns null when remote buildNumber is equal or lower', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/version.json'),
          statusCode: 200,
          data: {
            'version': AppConfig.currentVersion,
            'buildNumber': AppConfig.currentBuildNumber,
          },
        ),
      );

      final update = await service.checkForUpdate();
      expect(update, isNull);
    });

    test('checkForUpdate returns null gracefully on network failure without throwing', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(),
            options: any(named: 'options'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/version.json'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final update = await service.checkForUpdate();
      expect(update, isNull);
    });
  });
}

