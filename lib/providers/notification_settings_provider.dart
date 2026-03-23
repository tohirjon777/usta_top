import 'package:flutter/foundation.dart';

import '../core/storage/notification_settings_storage.dart';

class NotificationSettingsProvider extends ChangeNotifier {
  NotificationSettingsProvider({
    required NotificationSettingsStorage storage,
  }) : _storage = storage;

  final NotificationSettingsStorage _storage;

  bool _isEnabled = true;
  bool _isLoaded = false;

  bool get isEnabled => _isEnabled;
  bool get isLoaded => _isLoaded;

  Future<void> restorePreference() async {
    _isEnabled = await _storage.loadEnabled();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_isEnabled == value && _isLoaded) {
      return;
    }
    _isEnabled = value;
    _isLoaded = true;
    notifyListeners();
    await _storage.saveEnabled(value);
  }

  Future<void> toggle() => setEnabled(!_isEnabled);
}
