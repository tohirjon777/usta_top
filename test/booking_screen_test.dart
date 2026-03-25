import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:usta_top/core/localization/app_language.dart';
import 'package:usta_top/core/localization/app_localizations.dart';
import 'package:usta_top/core/storage/auth_token_storage.dart';
import 'package:usta_top/models/booking_availability.dart';
import 'package:usta_top/models/booking_availability_calendar.dart';
import 'package:usta_top/models/booking_chat_message.dart';
import 'package:usta_top/models/booking_item.dart';
import 'package:usta_top/models/salon.dart';
import 'package:usta_top/models/service_price_quote.dart';
import 'package:usta_top/providers/auth_provider.dart';
import 'package:usta_top/providers/booking_provider.dart';
import 'package:usta_top/screens/booking_screen.dart';
import 'package:usta_top/services/auth_service.dart';
import 'package:usta_top/services/booking_service.dart';

void main() {
  Widget buildTestApp({
    required AuthProvider authProvider,
    required BookingProvider bookingProvider,
    required Salon salon,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
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
        home: BookingScreen(salon: salon),
      ),
    );
  }

  testWidgets('nearest available button selects the suggested slot',
      (WidgetTester tester) async {
    final FakeBookingService bookingService = FakeBookingService();
    final AuthProvider authProvider = AuthProvider(
      authService: FakeAuthService(),
      tokenStorage: const AuthTokenStorage(),
    );
    final BookingProvider bookingProvider = BookingProvider(
      service: bookingService,
      seed: const <BookingItem>[],
    );

    await tester.pumpWidget(
      buildTestApp(
        authProvider: authProvider,
        bookingProvider: bookingProvider,
        salon: buildTestSalon(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shu vaqtni tanlash'), findsOneWidget);
    await tester.ensureVisible(find.text('Shu vaqtni tanlash'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shu vaqtni tanlash'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Shu vaqtni tanlash'), findsNothing);
  });
}

Salon buildTestSalon() {
  return const Salon(
    id: 'w-1',
    name: 'Turbo Usta Servis',
    master: 'Aziz Usta',
    rating: 4.9,
    reviewCount: 10,
    address: 'Sergeli, Toshkent',
    description: 'Test salon',
    distanceKm: 2.5,
    isOpen: true,
    badge: 'Top',
    services: <SalonService>[
      SalonService(
        id: 'srv-1',
        name: 'Diagnostika',
        price: 120,
        durationMinutes: 30,
      ),
    ],
  );
}

class FakeBookingService implements BookingService {
  late final DateTime nearestDate;

  FakeBookingService() {
    final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
    nearestDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
  }

  @override
  Future<BookingAvailability> fetchAvailability({
    required String workshopId,
    required String serviceId,
    required DateTime date,
  }) async {
    return BookingAvailability(
      date: date,
      slotTimes: const <String>['09:00', '10:30'],
      isClosedDay: false,
      serviceDurationMinutes: 30,
      openingTime: '09:00',
      closingTime: '18:00',
      breakStartTime: '',
      breakEndTime: '',
    );
  }

  @override
  Future<BookingAvailabilityCalendar> fetchAvailabilityCalendar({
    required String workshopId,
    required String serviceId,
    required DateTime fromDate,
    int days = 45,
  }) async {
    return BookingAvailabilityCalendar(
      days: <BookingAvailabilityDay>[
        BookingAvailabilityDay(
          date: nearestDate,
          isClosedDay: false,
          slotCount: 2,
          activeBookingCount: 0,
          isFullyBooked: false,
          firstSlot: '09:00',
        ),
      ],
      nearestAvailableDate: nearestDate,
      nearestAvailableTime: '10:30',
    );
  }

  @override
  Future<ServicePriceQuote> fetchPriceQuote({
    required String workshopId,
    required String serviceId,
    required String catalogVehicleId,
    required String vehicleBrand,
    required String vehicleModelName,
    required String vehicleTypeId,
  }) async {
    return const ServicePriceQuote(
      basePrice: 120,
      price: 120,
    );
  }

  @override
  Future<List<BookingItem>> fetchBookings() async => const <BookingItem>[];

  @override
  Future<BookingItem> createBooking({
    required String workshopId,
    required String serviceId,
    required String vehicleBrand,
    required String vehicleModelName,
    required String vehicleDisplayName,
    required String catalogVehicleId,
    required bool isCustomVehicle,
    required String vehicleTypeId,
    required DateTime dateTime,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BookingItem> cancelBooking({
    required String bookingId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<BookingChatMessage>> fetchBookingMessages({
    required String bookingId,
  }) async {
    return const <BookingChatMessage>[];
  }

  @override
  Future<BookingChatMessage> sendBookingMessage({
    required String bookingId,
    required String text,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markBookingMessagesRead({
    required String bookingId,
  }) async {}
}

class FakeAuthService implements AuthService {
  @override
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<AuthUser> getCurrentUser({
    required String accessToken,
  }) async {
    return const AuthUser(
      id: 'u-1',
      fullName: 'Test User',
      phone: '+998901234567',
    );
  }

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> registerPushToken({
    required String accessToken,
    required String token,
    required String platform,
  }) async {}

  @override
  Future<void> resetPassword({
    required String phone,
    required String newPassword,
  }) async {}

  @override
  Future<AuthSession> signUp({
    required String fullName,
    required String phone,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> unregisterPushToken({
    required String accessToken,
    required String token,
  }) async {}

  @override
  Future<AuthUser> updateCurrentUserProfile({
    required String accessToken,
    required String fullName,
    required String phone,
  }) async {
    return AuthUser(
      id: 'u-1',
      fullName: fullName,
      phone: phone,
    );
  }
}
