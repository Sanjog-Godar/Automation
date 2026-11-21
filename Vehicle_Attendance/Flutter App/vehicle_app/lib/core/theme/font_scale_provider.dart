import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/locale_provider.dart';

/// Predefined font scaling factors designed for senior accessibility.
enum AppFontScale {
  normal(1.0, 'normal'),
  large(1.18, 'large'),
  senior(1.35, 'senior');

  final double scaleFactor;
  final String key;
  const AppFontScale(this.scaleFactor, this.key);

  static AppFontScale fromKey(String? key) {
    if (key == 'large') return AppFontScale.large;
    if (key == 'senior') return AppFontScale.senior;
    return AppFontScale.normal;
  }
}

/// Provider managing the active font scaling factor and local persistence.
final fontScaleProvider =
    NotifierProvider<FontScaleNotifier, AppFontScale>(FontScaleNotifier.new);

class FontScaleNotifier extends Notifier<AppFontScale> {
  static const String prefsKey = 'app_font_scale';

  @override
  AppFontScale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    if (prefs != null) {
      final savedKey = prefs.getString(prefsKey);
      return AppFontScale.fromKey(savedKey);
    }
    return AppFontScale.normal;
  }

  /// Sets the application-wide font scale factor and persists the setting.
  Future<void> setScale(AppFontScale newScale) async {
    if (state == newScale) return;
    state = newScale;

    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs != null) {
      await prefs.setString(prefsKey, newScale.key);
    } else {
      final instance = await SharedPreferences.getInstance();
      await instance.setString(prefsKey, newScale.key);
    }
  }
}

