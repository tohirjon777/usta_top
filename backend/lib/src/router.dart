import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

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
}) {
  final HealthController healthController = HealthController();
  final AuthController authController = AuthController(store);
  final WorkshopController workshopController = WorkshopController(store);
  final BookingController bookingController = BookingController(store);
  final AdminController adminController = AdminController(
    store,
    locationsFilePath: workshopLocationsFilePath,
  );

  final Router router = Router()
    ..options('/<ignored|.*>', optionsHandler)
    ..get('/health', healthController.health)
    ..get('/admin', (_) => Response.seeOther(Uri.parse('/admin/workshops')))
    ..get('/admin/workshops', adminController.workshopsPage)
    ..post('/admin/workshops/<id>/location',
        adminController.updateWorkshopLocation)
    ..post('/auth/login', authController.login)
    ..get('/auth/me', authController.me)
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
