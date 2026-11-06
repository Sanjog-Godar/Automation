import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicle_app/core/config/app_config.dart';
import 'package:vehicle_app/core/l10n/locale_provider.dart';

void main() {
  group('LocaleNotifier Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Defaults to Nepali (Locale("ne")) when no preference is saved', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final initialLocale = container.read(localeProvider);
      expect(initialLocale, equals(const Locale('ne')));
      expect(container.read(localeProvider.notifier).isNepali, isTrue);
    });

    test('Initializes to English when saved preference is "en"', () async {
      SharedPreferences.setMockInitialValues({
        AppConfig.languagePrefsKey: 'en',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final locale = container.read(localeProvider);
      expect(locale, equals(const Locale('en')));
      expect(container.read(localeProvider.notifier).isNepali, isFalse);
    });

    test('setLocale persists chosen language to SharedPreferences and updates state', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      expect(container.read(localeProvider), equals(const Locale('ne')));

      await container.read(localeProvider.notifier).setLocale(const Locale('en'));

      expect(container.read(localeProvider), equals(const Locale('en')));
      expect(prefs.getString(AppConfig.languagePrefsKey), equals('en'));

      await container.read(localeProvider.notifier).setLocale(const Locale('ne'));

      expect(container.read(localeProvider), equals(const Locale('ne')));
      expect(prefs.getString(AppConfig.languagePrefsKey), equals('ne'));
    });

    test('toggleLanguage alternates between Nepali and English', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      expect(container.read(localeProvider), equals(const Locale('ne')));

      await container.read(localeProvider.notifier).toggleLanguage();
      expect(container.read(localeProvider), equals(const Locale('en')));
      expect(prefs.getString(AppConfig.languagePrefsKey), equals('en'));

      await container.read(localeProvider.notifier).toggleLanguage();
      expect(container.read(localeProvider), equals(const Locale('ne')));
      expect(prefs.getString(AppConfig.languagePrefsKey), equals('ne'));
    });
  });
}
