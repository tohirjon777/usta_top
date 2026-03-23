import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsStorage {
  const NotificationSettingsStorage();

  static const String _notificationsEnabledKey = 'notifications_enabled';

  Future<bool> loadEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> saveEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
  }
}
