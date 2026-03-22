import 'package:flutter/material.dart';

enum AppThemePreference {
  system('system', ThemeMode.system),
  light('light', ThemeMode.light),
  dark('dark', ThemeMode.dark);

  const AppThemePreference(this.code, this.themeMode);

  final String code;
  final ThemeMode themeMode;

  static AppThemePreference fromCode(String? code) {
    return AppThemePreference.values.firstWhere(
      (AppThemePreference item) => item.code == code,
      orElse: () => AppThemePreference.system,
    );
  }
}
