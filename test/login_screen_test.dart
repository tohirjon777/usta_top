import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:automaster/core/localization/app_language.dart';
import 'package:automaster/core/localization/app_localizations.dart';
import 'package:automaster/core/storage/auth_token_storage.dart';
import 'package:automaster/providers/auth_provider.dart';
import 'package:automaster/screens/login_screen.dart';
import 'package:automaster/services/auth_service.dart';

void main() {
  testWidgets('registration OTP success closes the login sheet', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final _OtpAuthService authService = _OtpAuthService();
    final AuthProvider authProvider = AuthProvider(
      authService: authService,
      tokenStorage: const AuthTokenStorage(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp(
          locale: AppLanguage.uzbek.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Consumer<AuthProvider>(
            builder: (BuildContext context, AuthProvider provider, _) {
              if (provider.isLoggedIn) {
                return const Scaffold(body: Center(child: Text('HOME_READY')));
              }
              return LoginScreen(
                currentBackendBaseUrl: 'http://45.80.148.221',
                backendBaseUrlLocked: true,
                onUpdateBackendBaseUrl: (_) async {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Akkaunt yaratish'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'To\'liq ism'),
      'Test Mijoz',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Telefon raqam').last,
      '+998901234567',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Parol').last,
      '123456',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Yangi parolni tasdiqlang'),
      '123456',
    );
    await tester.tap(find.text('Kod yuborish'));
    await tester.pumpAndSettle();

    expect(find.text('Telefonni tasdiqlash'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'SMS kod'),
      '123456',
    );
    await tester.tap(find.text('Kodni tasdiqlash'));
    await tester.pumpAndSettle();

    expect(authService.verifyCalls, 1);
    expect(find.text('HOME_READY'), findsOneWidget);
    expect(find.text('Telefonni tasdiqlash'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'SMS kod'), findsNothing);
  });
}

class _OtpAuthService implements AuthService {
  int verifyCalls = 0;

  @override
  Future<AuthOtpChallenge> sendSignUpCode({required String phone}) async {
    return const AuthOtpChallenge(
      expiresAt: null,
      resendAvailableAt: null,
      channel: 'sms',
      debugCode: '123456',
    );
  }

  @override
  Future<AuthSession> verifySignUpCode({
    required String fullName,
    required String phone,
    required String password,
    required String code,
  }) async {
    verifyCalls += 1;
    return AuthSession(
      accessToken: 'token-registration',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  @override
  Future<AuthUser> getCurrentUser({required String accessToken}) async {
    return const AuthUser(
      id: 'u-registration',
      fullName: 'Test Mijoz',
      phone: '+998901234567',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
