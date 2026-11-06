import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Provider holding pre-initialized [SharedPreferences] instance.
/// Overridden in [ProviderScope] at application launch to ensure synchronous
/// reading before the first frame with zero language-switch flash.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) {
  return null;
});

/// Riverpod controller managing current application locale and persistence.
final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    if (prefs != null) {
      final savedCode = prefs.getString(AppConfig.languagePrefsKey);
      if (savedCode == 'en' || savedCode == 'ne') {
        return Locale(savedCode!);
      }
    }
    return AppConfig.defaultLocale;
  }

  /// Changes the active application locale and persists the selection.
  Future<void> setLocale(Locale newLocale) async {
    if (state == newLocale) return;
    state = newLocale;

    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs != null) {
      await prefs.setString(AppConfig.languagePrefsKey, newLocale.languageCode);
    } else {
      final instance = await SharedPreferences.getInstance();
      await instance.setString(AppConfig.languagePrefsKey, newLocale.languageCode);
    }
  }

  /// Toggles between English and Nepali.
  Future<void> toggleLanguage() async {
    final next = state.languageCode == 'ne' ? const Locale('en') : const Locale('ne');
    await setLocale(next);
  }

  /// Convenience getter for whether current locale is Nepali.
  bool get isNepali => state.languageCode == 'ne';
}

