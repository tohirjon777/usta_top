import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'app/usta_top_app.dart';
import 'core/config/backend_config.dart';
import 'core/localization/app_language.dart';
import 'core/storage/auth_token_storage.dart';
import 'core/storage/backend_endpoint_storage.dart';
import 'core/storage/notification_settings_storage.dart';
import 'core/storage/saved_workshops_storage.dart';
import 'core/storage/theme_mode_storage.dart';
import 'data/repositories/mock_salon_repository.dart';
import 'models/booking_item.dart';
import 'providers/auth_provider.dart';
import 'providers/app_navigation_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/language_provider.dart';
import 'providers/notification_settings_provider.dart';
import 'providers/push_notifications_provider.dart';
import 'providers/saved_workshops_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/workshop_provider.dart';
import 'services/auth_service.dart';
import 'services/booking_service.dart';
import 'services/local_auth_service.dart';
import 'services/mock_workshop_service.dart';
import 'services/remote_auth_service.dart';
import 'services/remote_booking_service.dart';
import 'services/remote_workshop_service.dart';
import 'services/workshop_service.dart';

Future<void> main() async {
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  final Stopwatch splashStopwatch = Stopwatch()..start();
  const BackendEndpointStorage backendEndpointStorage =
      BackendEndpointStorage();
  final String? storedBackendBaseUrl =
      await backendEndpointStorage.loadBaseUrl();

  runApp(
    MyApp(
      backendEndpointStorage: backendEndpointStorage,
      initialBackendBaseUrl: BackendConfig.resolveBaseUrl(
        overrideBaseUrl: storedBackendBaseUrl,
      ),
      backendBaseUrlLocked: false,
    ),
  );

  final int remainingMilliseconds = 2000 - splashStopwatch.elapsedMilliseconds;
  if (remainingMilliseconds > 0) {
    await Future<void>.delayed(
      Duration(milliseconds: remainingMilliseconds),
    );
  }

  FlutterNativeSplash.remove();
}

List<BookingItem> _seedBookings() {
  return <BookingItem>[
    BookingItem(
      id: 'seed-1',
      workshopId: 'w-1',
      salonName: 'Turbo Usta Servis',
      masterName: 'Aziz Usta',
      serviceId: 'srv-1',
      serviceName: 'Kompyuter diagnostika',
      vehicleModel: 'Chevrolet Cobalt',
      vehicleTypeId: 'sedan',
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      basePrice: 120,
      price: 120,
    ),
  ];
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.backendEndpointStorage,
    required this.initialBackendBaseUrl,
    required this.backendBaseUrlLocked,
  });

  final BackendEndpointStorage backendEndpointStorage;
  final String initialBackendBaseUrl;
  final bool backendBaseUrlLocked;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String _backendBaseUrl = widget.initialBackendBaseUrl;

  Future<void> _updateBackendBaseUrl(String? value) async {
    if (widget.backendBaseUrlLocked) {
      return;
    }

    if (value == null || value.trim().isEmpty) {
      await widget.backendEndpointStorage.clearBaseUrl();
      if (!mounted) {
        return;
      }
      setState(() {
        _backendBaseUrl = BackendConfig.resolveBaseUrl();
      });
      return;
    }

    final String normalized = BackendConfig.normalizeBaseUrl(value);
    await widget.backendEndpointStorage.saveBaseUrl(normalized);
    if (!mounted) {
      return;
    }
    setState(() {
      _backendBaseUrl = BackendConfig.resolveBaseUrl(
        overrideBaseUrl: normalized,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const bool isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
    // Odatdagi ishga tushirishda backend default bo'ladi.
    // Zarurat bo'lsa `--dart-define=USE_BACKEND=false` bilan local rejimga o'tish mumkin.
    const bool useBackend = bool.fromEnvironment(
      'USE_BACKEND',
      defaultValue: !isFlutterTest,
    );
    final bool enablePushNotifications = useBackend && !isFlutterTest;
    final String backendBaseUrl = _backendBaseUrl;
    const AuthTokenStorage tokenStorage = AuthTokenStorage();
    const NotificationSettingsStorage notificationSettingsStorage =
        NotificationSettingsStorage();
    const SavedWorkshopsStorage savedWorkshopsStorage = SavedWorkshopsStorage();
    const ThemeModeStorage themeModeStorage = ThemeModeStorage();

    return MultiProvider(
      key: ValueKey<String>('providers:$backendBaseUrl'),
      providers: [
        Provider<AuthTokenStorage>.value(value: tokenStorage),
        Provider<NotificationSettingsStorage>.value(
          value: notificationSettingsStorage,
        ),
        Provider<SavedWorkshopsStorage>.value(value: savedWorkshopsStorage),
        Provider<ThemeModeStorage>.value(value: themeModeStorage),
        Provider<AuthService>(
          // TODO(API): Login va /auth/me shu servisedan keladi.
          create: (_) => useBackend
              ? RemoteAuthService(baseUrl: backendBaseUrl)
              : LocalAuthService(),
        ),
        Provider<WorkshopService>(
          // TODO(API): Workshop/salonlar ro'yxati shu servisedan olinadi.
          create: (BuildContext context) => useBackend
              ? RemoteWorkshopService(
                  baseUrl: backendBaseUrl,
                  tokenStorage: context.read<AuthTokenStorage>(),
                )
              : MockWorkshopService(repository: const MockSalonRepository()),
        ),
        Provider<BookingService?>(
          // TODO(API): Booking yaratish/bekor qilish shu serviseda.
          create: (BuildContext context) => useBackend
              ? RemoteBookingService(
                  baseUrl: backendBaseUrl,
                  tokenStorage: context.read<AuthTokenStorage>(),
                )
              : null,
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (BuildContext context) => AuthProvider(
            authService: context.read<AuthService>(),
            tokenStorage: context.read<AuthTokenStorage>(),
          )..restoreSession(),
        ),
        ChangeNotifierProvider<SavedWorkshopsProvider>(
          create: (BuildContext context) => SavedWorkshopsProvider(
            storage: context.read<SavedWorkshopsStorage>(),
          )..restoreSaved(),
        ),
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(initialLanguage: AppLanguage.uzbek),
        ),
        ChangeNotifierProvider<NotificationSettingsProvider>(
          create: (BuildContext context) => NotificationSettingsProvider(
            storage: context.read<NotificationSettingsStorage>(),
          )..restorePreference(),
        ),
        ChangeNotifierProvider<AppNavigationProvider>(
          create: (_) => AppNavigationProvider(),
        ),
        if (enablePushNotifications)
          ChangeNotifierProvider<PushNotificationsProvider>(
            lazy: false,
            create: (BuildContext context) => PushNotificationsProvider(
              authProvider: context.read<AuthProvider>(),
              appNavigationProvider: context.read<AppNavigationProvider>(),
              notificationSettingsProvider:
                  context.read<NotificationSettingsProvider>(),
              authService: context.read<AuthService>(),
            )..initialize(),
          ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (BuildContext context) => ThemeProvider(
            storage: context.read<ThemeModeStorage>(),
          )..restorePreference(),
        ),
        ChangeNotifierProvider<BookingProvider>(
          create: (BuildContext context) => BookingProvider(
            service: context.read<BookingService?>(),
            seed: useBackend ? null : _seedBookings(),
          ),
        ),
        ChangeNotifierProvider<WorkshopProvider>(
          create: (BuildContext context) => WorkshopProvider(
            service: context.read<WorkshopService>(),
          ),
        ),
      ],
      child: UstaTopApp(
        currentBackendBaseUrl: backendBaseUrl,
        backendBaseUrlLocked: widget.backendBaseUrlLocked,
        onUpdateBackendBaseUrl: _updateBackendBaseUrl,
      ),
    );
  }
}
