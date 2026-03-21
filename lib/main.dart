import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/usta_top_app.dart';
import 'core/config/backend_config.dart';
import 'core/localization/app_language.dart';
import 'core/storage/auth_token_storage.dart';
import 'core/storage/saved_workshops_storage.dart';
import 'data/repositories/mock_salon_repository.dart';
import 'models/booking_item.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/language_provider.dart';
import 'providers/saved_workshops_provider.dart';
import 'providers/workshop_provider.dart';
import 'services/auth_service.dart';
import 'services/booking_service.dart';
import 'services/local_auth_service.dart';
import 'services/mock_workshop_service.dart';
import 'services/remote_auth_service.dart';
import 'services/remote_booking_service.dart';
import 'services/remote_workshop_service.dart';
import 'services/workshop_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      price: 120,
    ),
  ];
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO(API): Real backendga ulash uchun ishga tushirishda
    // `--dart-define=USE_BACKEND=true` bering.
    const bool useBackend = bool.fromEnvironment(
      'USE_BACKEND',
      defaultValue: false,
    );
    // TODO(API): Server manzilini `--dart-define=API_BASE_URL=https://...` bilan bering.
    final String backendBaseUrl = BackendConfig.resolveBaseUrl();
    const AuthTokenStorage tokenStorage = AuthTokenStorage();
    const SavedWorkshopsStorage savedWorkshopsStorage = SavedWorkshopsStorage();

    return MultiProvider(
      providers: [
        Provider<AuthTokenStorage>.value(value: tokenStorage),
        Provider<SavedWorkshopsStorage>.value(value: savedWorkshopsStorage),
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
      child: const UstaTopApp(),
    );
  }
}
