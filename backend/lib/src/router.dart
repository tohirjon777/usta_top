import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'admin_auth.dart';
import 'auth_middleware.dart';
import 'controllers/admin_bookings_controller.dart';
import 'controllers/admin_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'controllers/health_controller.dart';
import 'controllers/owner_controller.dart';
import 'controllers/workshop_controller.dart';
import 'firebase_push.dart';
import 'http_helpers.dart';
import 'owner_auth.dart';
import 'store.dart';
import 'telegram_bot.dart';
import 'user_notifications.dart';
import 'workshop_notifications.dart';

class AppRuntime {
  const AppRuntime({
    required this.handler,
    required this.ownerController,
  });

  final Handler handler;
  final OwnerController ownerController;
}

AppRuntime buildAppRuntime(
  InMemoryStore store, {
  required String workshopLocationsFilePath,
  required String workshopsFilePath,
  required String usersFilePath,
  required String authSessionsFilePath,
  required String bookingsFilePath,
  required String telegramSyncStateFilePath,
  required String adminUsername,
  required String adminPassword,
  required String telegramBotToken,
  required String firebaseServiceAccountFilePath,
}) {
  final HealthController healthController = HealthController();
  final AuthController authController = AuthController(
    store,
    usersFilePath: usersFilePath,
    sessionsFilePath: authSessionsFilePath,
  );
  final WorkshopController workshopController = WorkshopController(store);
  final TelegramBotService telegramBotService = TelegramBotService(
    botToken: telegramBotToken,
  );
  final FirebasePushService firebasePushService = FirebasePushService(
    serviceAccountFilePath: firebaseServiceAccountFilePath,
  );
  final WorkshopNotificationsService notificationsService =
      WorkshopNotificationsService(telegramBotService);
  final UserNotificationsService userNotificationsService =
      UserNotificationsService(firebasePushService);
  final BookingController bookingController = BookingController(
    store,
    bookingsFilePath: bookingsFilePath,
    notificationsService: notificationsService,
  );
  final AdminAuthService adminAuthService = AdminAuthService(
    username: adminUsername,
    password: adminPassword,
  );
  final AdminController adminController = AdminController(
    store,
    adminAuthService: adminAuthService,
    locationsFilePath: workshopLocationsFilePath,
    workshopsFilePath: workshopsFilePath,
    notificationsService: notificationsService,
  );
  final AdminBookingsController adminBookingsController =
      AdminBookingsController(
    store,
    adminAuthService: adminAuthService,
    bookingsFilePath: bookingsFilePath,
    notificationsService: notificationsService,
    userNotificationsService: userNotificationsService,
  );
  final OwnerAuthService ownerAuthService = OwnerAuthService();
  final OwnerController ownerController = OwnerController(
    store,
    ownerAuthService: ownerAuthService,
    bookingsFilePath: bookingsFilePath,
    workshopsFilePath: workshopsFilePath,
    telegramSyncStateFilePath: telegramSyncStateFilePath,
    telegramBotService: telegramBotService,
    notificationsService: notificationsService,
    userNotificationsService: userNotificationsService,
  );

  final Router router = Router()
    ..options('/<ignored|.*>', optionsHandler)
    ..get('/health', healthController.health)
    ..get('/admin', adminController.entry)
    ..get('/admin/login', adminController.loginPage)
    ..post('/admin/login', adminController.login)
    ..post('/admin/logout', adminController.logout)
    ..get('/admin/workshops', adminController.workshopsPage)
    ..get('/admin/bookings', adminBookingsController.bookingsPage)
    ..post('/admin/bookings/<id>/status', adminBookingsController.updateStatus)
    ..get('/owner', ownerController.entry)
    ..get('/owner/login', ownerController.loginPage)
    ..post('/owner/login', ownerController.login)
    ..post('/owner/logout', ownerController.logout)
    ..get('/owner/bookings', ownerController.bookingsPage)
    ..post('/owner/telegram/generate', ownerController.generateTelegramLinkCode)
    ..post('/owner/telegram/check', ownerController.checkTelegramLink)
    ..post('/owner/telegram/disconnect', ownerController.disconnectTelegram)
    ..post('/owner/services/<id>/price', ownerController.updateServicePrice)
    ..post('/owner/bookings/<id>/status', ownerController.updateStatus)
    ..post('/admin/workshops', adminController.createWorkshop)
    ..post('/admin/workshops/<id>/update', adminController.updateWorkshop)
    ..post('/admin/workshops/<id>/delete', adminController.deleteWorkshop)
    ..post(
        '/admin/workshops/<id>/telegram/test', adminController.sendTelegramTest)
    ..post('/admin/workshops/<id>/location',
        adminController.updateWorkshopLocation)
    ..post('/auth/login', authController.login)
    ..post('/auth/register', authController.register)
    ..post('/auth/forgot-password', authController.forgotPassword)
    ..post('/auth/push-token', authController.registerPushToken)
    ..post('/auth/push-token/remove', authController.unregisterPushToken)
    ..get('/auth/me', authController.me)
    ..patch('/auth/me', authController.updateMe)
    ..patch('/auth/me/password', authController.updatePassword)
    ..get('/workshops', workshopController.list)
    ..get('/workshops/<id>', workshopController.byId)
    ..get('/bookings', bookingController.list)
    ..post('/bookings', bookingController.create)
    ..patch('/bookings/<id>/cancel', bookingController.cancel);

  final Handler handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())
      .addMiddleware(authMiddleware(store))
      .addHandler(router.call);

  return AppRuntime(
    handler: handler,
    ownerController: ownerController,
  );
}

Handler buildHandler(
  InMemoryStore store, {
  required String workshopLocationsFilePath,
  required String workshopsFilePath,
  required String usersFilePath,
  required String authSessionsFilePath,
  required String bookingsFilePath,
  required String telegramSyncStateFilePath,
  required String adminUsername,
  required String adminPassword,
  required String telegramBotToken,
  required String firebaseServiceAccountFilePath,
}) {
  return buildAppRuntime(
    store,
    workshopLocationsFilePath: workshopLocationsFilePath,
    workshopsFilePath: workshopsFilePath,
    usersFilePath: usersFilePath,
    authSessionsFilePath: authSessionsFilePath,
    bookingsFilePath: bookingsFilePath,
    telegramSyncStateFilePath: telegramSyncStateFilePath,
    adminUsername: adminUsername,
    adminPassword: adminPassword,
    telegramBotToken: telegramBotToken,
    firebaseServiceAccountFilePath: firebaseServiceAccountFilePath,
  ).handler;
}
