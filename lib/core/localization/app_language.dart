import 'package:flutter/material.dart';

enum AppLanguage {
  english('en'),
  uzbek('uz'),
  russian('ru');

  const AppLanguage(this.code);

  final String code;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (AppLanguage language) => language.code == code,
      orElse: () => AppLanguage.english,
    );
  }

  static AppLanguage fromLocale(Locale locale) {
    return fromCode(locale.languageCode);
  }
}
