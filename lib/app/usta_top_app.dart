import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/localization/app_language.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/mock_salon_repository.dart';
import '../models/booking_item.dart';
import '../screens/login_screen.dart';
import '../state/booking_controller.dart';
import 'main_navigation_shell.dart';

class UstaTopApp extends StatefulWidget {
  const UstaTopApp({super.key});

  @override
  State<UstaTopApp> createState() => _UstaTopAppState();
}

class _UstaTopAppState extends State<UstaTopApp> {
  late final BookingController _bookingController;
  final MockSalonRepository _salonRepository = const MockSalonRepository();
  bool _isLoggedIn = true;
  late AppLanguage _language;

  @override
  void initState() {
    super.initState();
    _language = AppLanguage.fromLocale(
      WidgetsBinding.instance.platformDispatcher.locale,
    );
    _bookingController = BookingController(
      seed: <BookingItem>[
        BookingItem(
          id: 'seed-1',
          salonName: 'Prime Barber House',
          masterName: 'Aziz',
          serviceName: 'Haircut',
          dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          price: 120,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _bookingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context).appTitle,
      theme: AppTheme.light,
      locale: _language.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _isLoggedIn
          ? MainNavigationShell(
              bookingController: _bookingController,
              salonRepository: _salonRepository,
              currentLanguage: _language,
              onLanguageChanged: (AppLanguage language) {
                setState(() {
                  _language = language;
                });
              },
              onSignOut: () {
                setState(() {
                  _isLoggedIn = false;
                });
              },
            )
          : LoginScreen(
              onLoginSuccess: () {
                setState(() {
                  _isLoggedIn = true;
                });
              },
            ),
    );
  }
}
