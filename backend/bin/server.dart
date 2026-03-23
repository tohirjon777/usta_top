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
  final String usersFilePath =
      Platform.environment['USERS_FILE'] ?? 'data/users.json';
  final String bookingsFilePath =
      Platform.environment['BOOKINGS_FILE'] ?? 'data/bookings.json';
  final String telegramSyncStateFilePath =
      Platform.environment['TELEGRAM_SYNC_STATE_FILE'] ??
          'data/telegram_state.json';
  final String adminUsername =
      Platform.environment['ADMIN_USERNAME'] ?? 'admin';
  final String adminPassword =
      Platform.environment['ADMIN_PASSWORD'] ?? 'admin123';
  final String telegramBotToken =
      Platform.environment['TELEGRAM_BOT_TOKEN'] ?? '';

  final InMemoryStore store = InMemoryStore.withSeedData();
  await store.loadUsers(usersFilePath);
  await store.loadWorkshops(workshopsFilePath);
  await store.loadWorkshopLocations(workshopLocationsFilePath);
  await store.loadBookings(bookingsFilePath);

  final server = await io.serve(
    buildHandler(
      store,
      workshopLocationsFilePath: workshopLocationsFilePath,
      workshopsFilePath: workshopsFilePath,
      usersFilePath: usersFilePath,
      bookingsFilePath: bookingsFilePath,
      telegramSyncStateFilePath: telegramSyncStateFilePath,
      adminUsername: adminUsername,
      adminPassword: adminPassword,
      telegramBotToken: telegramBotToken,
    ),
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
  if (telegramBotToken.trim().isEmpty) {
    stdout.writeln('Telegram bot: o‘chiq (TELEGRAM_BOT_TOKEN kiritilmagan)');
    return;
  }

  final TelegramBotService telegramBotService = TelegramBotService(
    botToken: telegramBotToken,
  );
  try {
    final Map<String, dynamic> bot = await telegramBotService.getMe();
    final String username = (bot['username'] ?? '').toString();
    final String botName = (bot['first_name'] ?? '').toString();
    stdout.writeln(
      'Telegram bot: ulangan${username.isEmpty ? '' : ' (@$username)'}${botName.isEmpty ? '' : ' - $botName'}',
    );
  } on Exception catch (error) {
    stdout.writeln('Telegram bot: xatolik - $error');
  }
}
