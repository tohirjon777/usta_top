import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth_middleware.dart';
import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'controllers/health_controller.dart';
import 'controllers/workshop_controller.dart';
import 'http_helpers.dart';
import 'store.dart';

Handler buildHandler(InMemoryStore store) {
  final HealthController healthController = HealthController();
  final AuthController authController = AuthController(store);
  final WorkshopController workshopController = WorkshopController(store);
  final BookingController bookingController = BookingController(store);

  final Router router = Router()
    ..options('/<ignored|.*>', optionsHandler)
    ..get('/health', healthController.health)
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
