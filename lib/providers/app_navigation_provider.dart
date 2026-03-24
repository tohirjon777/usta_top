import 'package:flutter/foundation.dart';

import '../models/app_navigation_intent.dart';

class AppNavigationProvider extends ChangeNotifier {
  AppNavigationIntent? _pendingIntent;

  AppNavigationIntent? get pendingIntent => _pendingIntent;

  void queueIntent(AppNavigationIntent? intent) {
    if (intent == null) {
      return;
    }
    _pendingIntent = intent;
    notifyListeners();
  }

  AppNavigationIntent? consumePendingIntent() {
    final AppNavigationIntent? intent = _pendingIntent;
    _pendingIntent = null;
    return intent;
  }
}
