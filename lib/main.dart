import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'app/auto_master_app.dart';
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
  await backendEndpointStorage.clearBaseUrl();
  final String? startupErrorMessage = BackendConfig.productionBaseUrl.isEmpty
      ? BackendConfig.releaseBaseUrlRequiredMessage
      : null;

  runApp(
    MyApp(
      backendEndpointStorage: backendEndpointStorage,
      startupErrorMessage: startupErrorMessage,
      initialBackendBaseUrl: BackendConfig.resolveBaseUrl(),
      backendBaseUrlLocked: true,
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
    required this.startupErrorMessage,
    required this.initialBackendBaseUrl,
    required this.backendBaseUrlLocked,
  });

  final BackendEndpointStorage backendEndpointStorage;
  final String? startupErrorMessage;
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
    final String? startupErrorMessage = widget.startupErrorMessage;
    if (startupErrorMessage != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _StartupConfigurationErrorView(message: startupErrorMessage),
      );
    }

    // Real app hamma ma'lumotni VPS backenddan oladi.
    const bool useBackend = !isFlutterTest;
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
      child: AutoMasterApp(
        currentBackendBaseUrl: backendBaseUrl,
        backendBaseUrlLocked: widget.backendBaseUrlLocked,
        onUpdateBackendBaseUrl: _updateBackendBaseUrl,
      ),
    );
  }
}

class _StartupConfigurationErrorView extends StatelessWidget {
  const _StartupConfigurationErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.error_outline_rounded, size: 36),
                    const SizedBox(height: 16),
                    Text(
                      'Release configuration required',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(message),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
