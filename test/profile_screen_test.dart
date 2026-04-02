import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:usta_top/core/localization/app_language.dart';
import 'package:usta_top/core/localization/app_localizations.dart';
import 'package:usta_top/core/storage/auth_token_storage.dart';
import 'package:usta_top/core/storage/notification_settings_storage.dart';
import 'package:usta_top/core/storage/theme_mode_storage.dart';
import 'package:usta_top/models/booking_item.dart';
import 'package:usta_top/models/saved_payment_card.dart';
import 'package:usta_top/providers/app_navigation_provider.dart';
import 'package:usta_top/providers/auth_provider.dart';
import 'package:usta_top/providers/booking_provider.dart';
import 'package:usta_top/providers/language_provider.dart';
import 'package:usta_top/providers/notification_settings_provider.dart';
import 'package:usta_top/providers/push_notifications_provider.dart';
import 'package:usta_top/providers/theme_provider.dart';
import 'package:usta_top/screens/profile_screen.dart';
import 'package:usta_top/services/auth_service.dart';

void main() {
  Future<AuthProvider> buildAuthProvider(
    FakeAuthService authService,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final AuthProvider provider = AuthProvider(
      authService: authService,
      tokenStorage: const AuthTokenStorage(),
    );
    final bool signedIn = await provider.signIn(
      phone: authService.user.phone,
      password: authService.password,
    );
    expect(signedIn, isTrue);
    return provider;
  }

  Widget buildTestApp(AuthProvider authProvider, AuthService authService) {
    final NotificationSettingsProvider notificationSettingsProvider =
        NotificationSettingsProvider(
          storage: const NotificationSettingsStorage(),
        )..restorePreference();
    final AppNavigationProvider appNavigationProvider =
        AppNavigationProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<BookingProvider>(
          create: (_) => BookingProvider(seed: const <BookingItem>[]),
        ),
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(initialLanguage: AppLanguage.uzbek),
        ),
        ChangeNotifierProvider<NotificationSettingsProvider>.value(
          value: notificationSettingsProvider,
        ),
        ChangeNotifierProvider<AppNavigationProvider>.value(
          value: appNavigationProvider,
        ),
        ChangeNotifierProvider<PushNotificationsProvider>(
          create: (_) => PushNotificationsProvider(
            authProvider: authProvider,
            appNavigationProvider: appNavigationProvider,
            notificationSettingsProvider: notificationSettingsProvider,
            authService: authService,
          ),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(storage: const ThemeModeStorage()),
        ),
      ],
      child: MaterialApp(
        locale: AppLanguage.uzbek.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: ProfileScreen(
            onOpenBookingHistory: () {},
            onOpenSavedSalons: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('profile save closes sheet and updates the header name', (
    WidgetTester tester,
  ) async {
    final FakeAuthService authService = FakeAuthService();
    final AuthProvider authProvider = await buildAuthProvider(authService);

    await tester.pumpWidget(buildTestApp(authProvider, authService));
    await tester.pumpAndSettle();

    expect(find.text('Test User'), findsOneWidget);

    await tester.tap(find.text('Profilni tahrirlash'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Usta Test');
    await tester.tap(find.text('Saqlash'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Usta Test'), findsOneWidget);
    expect(find.text('Profil muvaffaqiyatli yangilandi'), findsOneWidget);
    expect(find.text('To\'liq ism'), findsNothing);
  });

  testWidgets('profile save failure resets loading state and keeps sheet open',
      (
    WidgetTester tester,
  ) async {
    final FakeAuthService authService = FakeAuthService(
      updateError: const AuthException('Server test xatosi'),
    );
    final AuthProvider authProvider = await buildAuthProvider(authService);

    await tester.pumpWidget(buildTestApp(authProvider, authService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profilni tahrirlash'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Yangi Ism');
    await tester.tap(find.text('Saqlash'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Server test xatosi'), findsOneWidget);
    expect(find.text('To\'liq ism'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Saqlash'), findsOneWidget);
  });

}

class FakeAuthService implements AuthService {
  FakeAuthService({
    this.updateError,
    AuthUser? user,
    this.password = '123456',
  }) : user = user ??
            const AuthUser(
              id: 'u-test',
              fullName: 'Test User',
              phone: '+998 90 123 45 67',
            );

  AuthUser user;
  final AuthException? updateError;
  final String password;

  @override
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<AuthUser> addPaymentCard({
    required String accessToken,
    required String holderName,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required bool isDefault,
  }) async {
    final String digits = SavedPaymentCard.normalizeDigits(cardNumber);
    final SavedPaymentCard nextCard = SavedPaymentCard(
      id: 'card-1',
      holderName: holderName.trim(),
      brand: SavedPaymentCard.detectBrand(digits),
      maskedNumber: SavedPaymentCard.maskDigits(digits),
      last4: digits.substring(digits.length - 4),
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      isDefault: isDefault || user.savedPaymentCards.isEmpty,
      updatedAt: DateTime.now(),
    );
    user = user.copyWith(
      savedPaymentCards: <SavedPaymentCard>[nextCard],
    );
    return user;
  }

  @override
  Future<AuthUser> updatePaymentCard({
    required String accessToken,
    required String cardId,
    required String holderName,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required bool isDefault,
  }) async {
    final SavedPaymentCard existing = user.savedPaymentCards.firstWhere(
      (SavedPaymentCard card) => card.id == cardId,
    );
    final String digits = SavedPaymentCard.normalizeDigits(cardNumber);
    final SavedPaymentCard updatedCard = existing.copyWith(
      holderName: holderName.trim(),
      brand: digits.isEmpty ? existing.brand : SavedPaymentCard.detectBrand(digits),
      maskedNumber: digits.isEmpty ? existing.maskedNumber : SavedPaymentCard.maskDigits(digits),
      last4: digits.isEmpty ? existing.last4 : digits.substring(digits.length - 4),
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      isDefault: isDefault,
      updatedAt: DateTime.now(),
    );
    user = user.copyWith(savedPaymentCards: <SavedPaymentCard>[updatedCard]);
    return user;
  }

  @override
  Future<AuthUser> deletePaymentCard({
    required String accessToken,
    required String cardId,
  }) async {
    user = user.copyWith(
      savedPaymentCards: user.savedPaymentCards
          .where((SavedPaymentCard card) => card.id != cardId)
          .toList(growable: false),
    );
    return user;
  }

  @override
  Future<void> registerPushToken({
    required String accessToken,
    required String token,
    required String platform,
  }) async {}

  @override
  Future<void> unregisterPushToken({
    required String accessToken,
    required String token,
  }) async {}

  @override
  Future<void> sendTestPush({
    required String accessToken,
  }) async {}

  @override
  Future<AuthUser> getCurrentUser({
    required String accessToken,
  }) async {
    return user;
  }

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
  }) async {
    if (phone != user.phone || password != this.password) {
      throw const AuthException('Telefon raqam yoki parol noto\'g\'ri');
    }
    return AuthSession(
      accessToken: 'token-1',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  @override
  Future<AuthOtpChallenge> sendSignUpCode({
    required String phone,
  }) async {
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
    return AuthSession(
      accessToken: 'token-1',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  @override
  Future<void> resetPassword({
    required String phone,
    required String newPassword,
  }) async {}

  @override
  Future<AuthOtpChallenge> sendPasswordResetCode({
    required String phone,
  }) async {
    return const AuthOtpChallenge(
      expiresAt: null,
      resendAvailableAt: null,
      channel: 'sms',
      debugCode: '123456',
    );
  }

  @override
  Future<void> verifyPasswordResetCode({
    required String phone,
    required String newPassword,
    required String code,
  }) async {}

  @override
  Future<AuthSession> signUp({
    required String fullName,
    required String phone,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser> updateCurrentUserProfile({
    required String accessToken,
    required String fullName,
    required String phone,
  }) async {
    if (updateError != null) {
      throw updateError!;
    }

    user = user.copyWith(
      fullName: fullName.trim(),
      phone: phone.trim(),
    );
    return user;
  }

  @override
  Future<AuthUser> uploadCurrentUserAvatar({
    required String accessToken,
    required List<int> bytes,
    required String fileName,
  }) async {
    user = user.copyWith(
      avatarUrl: 'data:image/png;base64,test-avatar',
    );
    return user;
  }
}
