import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_language.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../screens/login_screen.dart';
import '../ui/app_loading_view.dart';
import 'main_navigation_shell.dart';

class UstaTopApp extends StatelessWidget {
  const UstaTopApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final LanguageProvider languageProvider = context.watch<LanguageProvider>();
    final AppLanguage currentLanguage = languageProvider.language;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context).appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: currentLanguage.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: authProvider.isLoadingSession
          ? const Scaffold(body: AppLoadingView())
          : authProvider.isLoggedIn
              ? const MainNavigationShell()
              : LoginScreen(
                  onLogin: (String phone, String password) {
                    return authProvider.signIn(
                      phone: phone,
                      password: password,
                    );
                  },
                ),
    );
  }
}
