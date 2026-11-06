import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/core/config/app_config.dart';

void main() {
  group('AppConfig Environment & Live Backend Tests', () {
    test('Default live production backend points to live Vercel deployment', () {
      expect(AppConfig.liveProductionBaseUrl, 'https://vehiclemgmt.vercel.app');
    });

    test('apiBaseUrl defaults to liveProductionBaseUrl in absence of env overrides', () {
      expect(AppConfig.apiBaseUrl, 'https://vehiclemgmt.vercel.app');
      expect(AppConfig.isProd, isTrue);
      expect(AppConfig.isDev, isFalse);
    });

    test('Supabase URL and Anon Key default to live project configuration', () {
      expect(AppConfig.supabaseUrl, 'https://jozvtiijteygfcbbbzgs.supabase.co');
      expect(AppConfig.supabaseAnonKey, contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'));
    });

    test('Timeouts are set to resilient production defaults', () {
      expect(AppConfig.connectTimeout, const Duration(seconds: 15));
      expect(AppConfig.receiveTimeout, const Duration(seconds: 15));
    });
  });
}

