import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'admin_auth.dart';
import 'auth_middleware.dart';
import 'controllers/admin_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'controllers/health_controller.dart';
import 'controllers/workshop_controller.dart';
import 'http_helpers.dart';
import 'store.dart';

Handler buildHandler(
  InMemoryStore store, {
  required String workshopLocationsFilePath,
  required String workshopsFilePath,
  required String usersFilePath,
  required String adminUsername,
  required String adminPassword,
}) {
  final HealthController healthController = HealthController();
  final AuthController authController = AuthController(
    store,
    usersFilePath: usersFilePath,
  );
  final WorkshopController workshopController = WorkshopController(store);
  final BookingController bookingController = BookingController(store);
  final AdminAuthService adminAuthService = AdminAuthService(
    username: adminUsername,
    password: adminPassword,
  );
  final AdminController adminController = AdminController(
    store,
    adminAuthService: adminAuthService,
    locationsFilePath: workshopLocationsFilePath,
    workshopsFilePath: workshopsFilePath,
  );

  final Router router = Router()
    ..options('/<ignored|.*>', optionsHandler)
    ..get('/health', healthController.health)
    ..get('/admin', adminController.entry)
    ..get('/admin/login', adminController.loginPage)
    ..post('/admin/login', adminController.login)
    ..post('/admin/logout', adminController.logout)
    ..get('/admin/workshops', adminController.workshopsPage)
    ..post('/admin/workshops', adminController.createWorkshop)
    ..post('/admin/workshops/<id>/update', adminController.updateWorkshop)
    ..post('/admin/workshops/<id>/delete', adminController.deleteWorkshop)
    ..post('/admin/workshops/<id>/location',
        adminController.updateWorkshopLocation)
    ..post('/auth/login', authController.login)
    ..post('/auth/register', authController.register)
    ..post('/auth/forgot-password', authController.forgotPassword)
    ..get('/auth/me', authController.me)
    ..patch('/auth/me', authController.updateMe)
    ..patch('/auth/me/password', authController.updatePassword)
    ..get('/workshops', workshopController.list)
    ..get('/workshops/<id>', workshopController.byId)
    ..get('/bookings', bookingController.list)
    ..post('/bookings', bookingController.create)
    ..patch('/bookings/<id>/cancel', bookingController.cancel);

  return Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())
      .addMiddleware(authMiddleware(store))
      .addHandler(router.call);
}
