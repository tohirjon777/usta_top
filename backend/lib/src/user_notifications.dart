import 'booking_cancellation.dart';
import 'firebase_push.dart';
import 'models.dart';

class UserNotificationsService {
  const UserNotificationsService(this._firebasePushService);

  final FirebasePushService _firebasePushService;

  bool get isConfigured => _firebasePushService.isConfigured;

  Future<void> sendBookingStatusNotification({
    required UserModel user,
    required BookingModel booking,
    required String actor,
  }) async {
    final List<String> tokens = user.pushTokens
        .map((PushTokenModel item) => item.token.trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (tokens.isEmpty) {
      throw const FirebasePushException(
        'Foydalanuvchi uchun push token topilmadi',
      );
    }

    await _firebasePushService.sendToTokens(
      tokens: tokens,
      title: _titleForBookingStatus(booking),
      body: _bodyForBookingStatus(
        booking: booking,
        actor: actor,
      ),
      data: <String, String>{
        'type': 'booking_status',
        'screen': 'bookings',
        'bookingId': booking.id,
        'workshopId': booking.workshopId,
        'status': booking.status.name,
        'cancelReasonId': booking.cancelReasonId,
      },
    );
  }

  Future<void> sendBookingChatNotification({
    required UserModel user,
    required BookingModel booking,
    required BookingChatMessageModel message,
  }) async {
    final List<String> tokens = user.pushTokens
        .map((PushTokenModel item) => item.token.trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (tokens.isEmpty) {
      throw const FirebasePushException(
        'Foydalanuvchi uchun push token topilmadi',
      );
    }

    await _firebasePushService.sendToTokens(
      tokens: tokens,
      title: 'Usta Top: ustadan yangi xabar',
      body:
          '${booking.workshopName} sizning ${booking.serviceName} zakazingiz bo‘yicha yozdi: ${bookingChatPreview(message.text)}',
      data: <String, String>{
        'type': 'booking_chat',
        'screen': 'bookings',
        'bookingId': booking.id,
        'workshopId': booking.workshopId,
      },
    );
  }

  Future<void> sendWorkshopReviewReplyNotification({
    required UserModel user,
    required WorkshopModel workshop,
    required WorkshopReviewModel review,
  }) async {
    final List<String> tokens = user.pushTokens
        .map((PushTokenModel item) => item.token.trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (tokens.isEmpty) {
      throw const FirebasePushException(
        'Foydalanuvchi uchun push token topilmadi',
      );
    }

    await _firebasePushService.sendToTokens(
      tokens: tokens,
      title: 'Usta Top: sharhingizga javob keldi',
      body:
          '${workshop.name} sizning ${review.serviceName} bo‘yicha sharhingizga javob berdi: ${workshopReviewPreview(review.ownerReply)}',
      data: <String, String>{
        'type': 'workshop_review_reply',
        'screen': 'workshop',
        'workshopId': workshop.id,
        'reviewId': review.id,
        'serviceId': review.serviceId,
      },
    );
  }

  String _titleForBookingStatus(BookingModel booking) {
    switch (booking.status) {
      case BookingStatus.completed:
        return 'Usta Top: zakaz bajarildi';
      case BookingStatus.cancelled:
        return 'Usta Top: zakaz bekor qilindi';
      case BookingStatus.upcoming:
        return 'Usta Top: zakaz yangilandi';
    }
  }

  String _bodyForBookingStatus({
    required BookingModel booking,
    required String actor,
  }) {
    switch (booking.status) {
      case BookingStatus.completed:
        return '${booking.workshopName} sizning ${booking.serviceName} zakazingizni yakunladi.';
      case BookingStatus.cancelled:
        final String reason = booking.cancelReasonId.isEmpty
            ? 'sababi ko‘rsatilmagan'
            : bookingCancellationReasonById(booking.cancelReasonId).label('uz');
        return '$actor ${booking.workshopName} zakazini bekor qildi: $reason.';
      case BookingStatus.upcoming:
        return '${booking.workshopName} sizning zakazingiz holatini yangiladi.';
    }
  }
}
