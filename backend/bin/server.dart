import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf_io.dart' as io;
import 'package:usta_top_backend/src/router.dart';
import 'package:usta_top_backend/src/store.dart';
import 'package:usta_top_backend/src/telegram_bot.dart';

Future<void> main() async {
  final String host = Platform.environment['HOST'] ?? '0.0.0.0';
  final int port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final String workshopLocationsFilePath =
      Platform.environment['WORKSHOP_LOCATIONS_FILE'] ??
          'data/workshop_locations.json';
  final String workshopsFilePath =
      Platform.environment['WORKSHOPS_FILE'] ?? 'data/workshops.json';
  final String reviewsFilePath =
      Platform.environment['REVIEWS_FILE'] ?? 'data/reviews.json';
  final String usersFilePath =
      Platform.environment['USERS_FILE'] ?? 'data/users.json';
  final String authSessionsFilePath =
      Platform.environment['AUTH_SESSIONS_FILE'] ?? 'data/auth_sessions.json';
  final String bookingsFilePath =
      Platform.environment['BOOKINGS_FILE'] ?? 'data/bookings.json';
  final String bookingMessagesFilePath =
      Platform.environment['BOOKING_MESSAGES_FILE'] ??
          'data/booking_messages.json';
  final String telegramSyncStateFilePath =
      Platform.environment['TELEGRAM_SYNC_STATE_FILE'] ??
          'data/telegram_state.json';
  final String adminUsername =
      Platform.environment['ADMIN_USERNAME'] ?? 'admin';
  final String adminPassword =
      Platform.environment['ADMIN_PASSWORD'] ?? 'admin123';
  final String telegramBotToken =
      Platform.environment['TELEGRAM_BOT_TOKEN'] ?? '';
  final String firebaseServiceAccountFilePath =
      Platform.environment['FIREBASE_SERVICE_ACCOUNT_FILE'] ?? '';

  final InMemoryStore store = InMemoryStore.withSeedData();
  await store.loadUsers(usersFilePath);
  await store.loadAuthSessions(authSessionsFilePath);
  await store.loadWorkshops(workshopsFilePath);
  await store.loadWorkshopLocations(workshopLocationsFilePath);
  await store.loadReviews(reviewsFilePath);
  await store.loadBookings(bookingsFilePath);
  await store.loadBookingMessages(bookingMessagesFilePath);

  final AppRuntime appRuntime = buildAppRuntime(
    store,
    workshopLocationsFilePath: workshopLocationsFilePath,
    workshopsFilePath: workshopsFilePath,
    reviewsFilePath: reviewsFilePath,
    usersFilePath: usersFilePath,
    authSessionsFilePath: authSessionsFilePath,
    bookingsFilePath: bookingsFilePath,
    bookingMessagesFilePath: bookingMessagesFilePath,
    telegramSyncStateFilePath: telegramSyncStateFilePath,
    adminUsername: adminUsername,
    adminPassword: adminPassword,
    telegramBotToken: telegramBotToken,
    firebaseServiceAccountFilePath: firebaseServiceAccountFilePath,
  );
  final server = await io.serve(
    appRuntime.handler,
    host,
    port,
  );

  stdout.writeln(
    'Usta Top backend ishga tushdi: http://${server.address.host}:${server.port}',
  );
  stdout.writeln(
    'Admin sahifa: http://${server.address.host}:${server.port}/admin/workshops',
  );
  stdout.writeln(
      'Admin login: http://${server.address.host}:${server.port}/admin/login');
  stdout.writeln('Admin username: $adminUsername');
  stdout.writeln(
    'Owner portal: http://${server.address.host}:${server.port}/owner/login',
  );
  final String ownerAccessCodes = store
      .workshops()
      .map(
        (workshop) => '${workshop.id}=${workshop.ownerAccessCode}',
      )
      .join(', ');
  stdout.writeln(
    ownerAccessCodes.isEmpty
        ? 'Owner access codes: topilmadi'
        : 'Owner access codes: $ownerAccessCodes',
  );
  stdout.writeln(
    firebaseServiceAccountFilePath.trim().isEmpty
        ? 'Firebase push: o‘chiq (FIREBASE_SERVICE_ACCOUNT_FILE kiritilmagan)'
        : File(firebaseServiceAccountFilePath).existsSync()
            ? 'Firebase push: tayyor'
            : 'Firebase push: service account topilmadi ($firebaseServiceAccountFilePath)',
  );

  bool isReviewReminderSyncRunning = false;
  bool isBookingReminderSyncRunning = false;

  Future<void> syncBookingRemindersSafely() async {
    if (isBookingReminderSyncRunning) {
      return;
    }

    isBookingReminderSyncRunning = true;
    try {
      final result = await appRuntime.bookingReminderService.sendDueReminders();
      if (result.totalSent > 0) {
        stdout.writeln(
          'Booking reminder yuborildi: mijoz=${result.customerSent}, ustaxona=${result.workshopSent}',
        );
      }
    } on Exception catch (error) {
      stderr.writeln('Booking reminder xatoligi: $error');
    } finally {
      isBookingReminderSyncRunning = false;
    }
  }

  Future<void> syncReviewRemindersSafely() async {
    if (isReviewReminderSyncRunning) {
      return;
    }

    isReviewReminderSyncRunning = true;
    try {
      final int sentCount = await appRuntime.reviewReminderService
          .sendDueReminders();
      if (sentCount > 0) {
        stdout.writeln('Review reminder yuborildi: $sentCount');
      }
    } on Exception catch (error) {
      stderr.writeln('Review reminder xatoligi: $error');
    } finally {
      isReviewReminderSyncRunning = false;
    }
  }

  unawaited(syncBookingRemindersSafely());
  Timer.periodic(const Duration(minutes: 5), (_) {
    unawaited(syncBookingRemindersSafely());
  });

  unawaited(syncReviewRemindersSafely());
  Timer.periodic(const Duration(minutes: 5), (_) {
    unawaited(syncReviewRemindersSafely());
  });

  if (telegramBotToken.trim().isEmpty) {
    stdout.writeln('Telegram bot: o‘chiq (TELEGRAM_BOT_TOKEN kiritilmagan)');
    return;
  }

  final TelegramBotService telegramBotService = TelegramBotService(
    botToken: telegramBotToken,
  );
  bool isTelegramSyncRunning = false;

  Future<void> syncTelegramUpdatesSafely() async {
    if (isTelegramSyncRunning) {
      return;
    }

    isTelegramSyncRunning = true;
    try {
      await appRuntime.ownerController.syncTelegramUpdates();
    } on Exception catch (error) {
      stderr.writeln('Telegram sync xatoligi: $error');
    } finally {
      isTelegramSyncRunning = false;
    }
  }

  try {
    final Map<String, dynamic> bot = await telegramBotService.getMe();
    final String username = (bot['username'] ?? '').toString();
    final String botName = (bot['first_name'] ?? '').toString();
    stdout.writeln(
      'Telegram bot: ulangan${username.isEmpty ? '' : ' (@$username)'}${botName.isEmpty ? '' : ' - $botName'}',
    );
    unawaited(syncTelegramUpdatesSafely());
    Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(syncTelegramUpdatesSafely());
    });
  } on Exception catch (error) {
    stdout.writeln('Telegram bot: xatolik - $error');
  }
}
