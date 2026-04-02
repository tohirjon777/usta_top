abstract final class ApiEndpoints {
  // TODO(API): POST /auth/login
  // Request sample:
  // {
  //   "phone": "+998901234567",
  //   "password": "secret123"
  // }
  // Success response sample:
  // {
  //   "data": {
  //     "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  //     "refreshToken": "refresh-token-value",
  //     "expiresAt": "2026-04-20T08:30:00.000Z"
  //   }
  // }
  // Error response sample:
  // {
  //   "error": "Telefon yoki parol noto'g'ri"
  // }
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authRegisterSendCode = '/auth/register/send-code';
  static const String authRegisterVerifyCode = '/auth/register/verify-code';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authPasswordSendCode = '/auth/password/send-code';
  static const String authPasswordVerifyCode = '/auth/password/verify-code';
  static const String authPushToken = '/auth/push-token';
  static const String authPushTokenRemove = '/auth/push-token/remove';
  static const String authPushTokenTest = '/auth/push-token/test';

  // TODO(API): GET /auth/me
  // Header: Authorization: Bearer <accessToken>
  // Success response sample:
  // {
  //   "data": {
  //     "id": "u-1",
  //     "fullName": "Ali Valiyev",
  //     "phone": "+998901234567"
  //   }
  // }
  static const String authMe = '/auth/me';
  static const String authMeAvatar = '/auth/me/avatar';
  static const String authMeCards = '/auth/me/cards';
  static String authMeCard(String cardId) => '/auth/me/cards/$cardId';
  // TODO(API): PATCH /auth/me
  // Header: Authorization: Bearer <accessToken>
  // Request sample:
  // {
  //   "fullName": "Ali Valiyev",
  //   "phone": "+998901234567"
  // }
  // Success response sample:
  // {
  //   "data": {
  //     "id": "u-1",
  //     "fullName": "Ali Valiyev",
  //     "phone": "+998901234567"
  //   }
  // }
  static const String authMePassword = '/auth/me/password';

  // TODO(API): GET /workshops
  // Header: Authorization: Bearer <accessToken>
  // Success response sample:
  // {
  //   "data": [
  //     {
  //       "id": "w-1",
  //       "name": "Turbo Usta Servis",
  //       "master": "Aziz Usta",
  //       "rating": 4.8,
  //       "reviewCount": 124,
  //       "address": "Toshkent, Chilonzor 12-kvartal",
  //       "description": "Yengil va tijorat mashinalariga xizmat",
  //       "distanceKm": 2.4,
  //       "latitude": 41.2756,
  //       "longitude": 69.2034,
  //       "isOpen": true,
  //       "badge": "Top tanlov",
  //       "services": [
  //         {
  //           "id": "srv-1",
  //           "name": "Kompyuter diagnostika",
  //           "price": 120,
  //           "durationMinutes": 45
  //         }
  //       ]
  //     }
  //   ]
  // }
  static const String workshops = '/workshops';

  // TODO(API): GET /workshops/:id
  // Success response sample: { "data": { ...workshop object... } }
  static String workshopById(String id) => '/workshops/$id';
  static String workshopAvailability(
    String id, {
    required String serviceId,
    required String date,
  }) {
    return Uri(
      path: '/workshops/$id/availability',
      queryParameters: <String, String>{
        'serviceId': serviceId,
        'date': date,
      },
    ).toString();
  }
  static String workshopAvailabilityCalendar(
    String id, {
    required String serviceId,
    required String from,
    required int days,
  }) {
    return Uri(
      path: '/workshops/$id/availability/calendar',
      queryParameters: <String, String>{
        'serviceId': serviceId,
        'from': from,
        'days': '$days',
      },
    ).toString();
  }
  static String workshopPriceQuote(
    String id, {
    required String serviceId,
    required String catalogVehicleId,
    required String vehicleBrand,
    required String vehicleModelName,
    required String vehicleTypeId,
  }) {
    return Uri(
      path: '/workshops/$id/price-quote',
      queryParameters: <String, String>{
        'serviceId': serviceId,
        if (catalogVehicleId.trim().isNotEmpty)
          'catalogVehicleId': catalogVehicleId.trim(),
        if (vehicleBrand.trim().isNotEmpty) 'vehicleBrand': vehicleBrand.trim(),
        if (vehicleModelName.trim().isNotEmpty)
          'vehicleModelName': vehicleModelName.trim(),
        if (vehicleTypeId.trim().isNotEmpty)
          'vehicleTypeId': vehicleTypeId.trim(),
      },
    ).toString();
  }
  static String workshopReviews(String id) => '/workshops/$id/reviews';

  // TODO(API): GET /bookings
  // Success response sample:
  // {
  //   "data": [
  //     {
  //       "id": "b-100",
  //       "workshopId": "w-1",
  //       "workshopName": "Turbo Usta Servis",
  //       "masterName": "Aziz Usta",
  //       "serviceId": "srv-1",
  //       "serviceName": "Kompyuter diagnostika",
  //       "dateTime": "2026-03-22T10:00:00.000Z",
  //       "price": 120,
  //       "status": "upcoming"
  //     }
  //   ]
  // }
  // TODO(API): POST /bookings
  // Request sample:
  // {
  //   "workshopId": "w-1",
  //   "serviceId": "srv-1",
  //   "dateTime": "2026-03-22T10:00:00.000Z"
  // }
  // Success response sample: { "data": { ...booking object... } }
  static const String bookings = '/bookings';
  static String bookingMessages(String bookingId) =>
      '/bookings/$bookingId/messages';
  static String markBookingMessagesRead(String bookingId) =>
      '/bookings/$bookingId/messages/read';

  // TODO(API): PATCH /bookings/:id/cancel
  // Request body sample:
  // {}
  // Success response sample:
  // {
  //   "data": {
  //     "id": "b-100",
  //     "status": "cancelled"
  //   }
  // }
  static String cancelBooking(String bookingId) =>
      '/bookings/$bookingId/cancel';

  static String rescheduleBooking(String bookingId) =>
      '/bookings/$bookingId/reschedule';

  static String acceptRescheduledBooking(String bookingId) =>
      '/bookings/$bookingId/accept-reschedule';
}
