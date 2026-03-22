import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme_preference.dart';

class ThemeModeStorage {
  const ThemeModeStorage();

  static const String _themeModeKey = 'theme_mode';

  Future<AppThemePreference> loadPreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return AppThemePreference.fromCode(prefs.getString(_themeModeKey));
  }

  Future<void> savePreference(AppThemePreference preference) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, preference.code);
  }
}
