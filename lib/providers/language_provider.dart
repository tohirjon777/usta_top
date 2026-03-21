import 'package:flutter/foundation.dart';

import '../core/localization/app_language.dart';

class LanguageProvider extends ChangeNotifier {
  LanguageProvider({AppLanguage initialLanguage = AppLanguage.uzbek})
      : _language = initialLanguage;

  AppLanguage _language;

  AppLanguage get language => _language;

  void setLanguage(AppLanguage language) {
    if (_language == language) {
      return;
    }
    _language = language;
    notifyListeners();
  }
}
