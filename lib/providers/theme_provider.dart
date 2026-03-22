import 'package:flutter/foundation.dart';

import '../core/storage/theme_mode_storage.dart';
import '../core/theme/app_theme_preference.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({
    required ThemeModeStorage storage,
    AppThemePreference initialPreference = AppThemePreference.system,
  })  : _storage = storage,
        _preference = initialPreference;

  final ThemeModeStorage _storage;
  AppThemePreference _preference;

  AppThemePreference get preference => _preference;

  Future<void> restorePreference() async {
    final AppThemePreference restored = await _storage.loadPreference();
    if (_preference == restored) {
      return;
    }
    _preference = restored;
    notifyListeners();
  }

  Future<void> setPreference(AppThemePreference preference) async {
    if (_preference == preference) {
      return;
    }
    _preference = preference;
    notifyListeners();
    await _storage.savePreference(preference);
  }
}
