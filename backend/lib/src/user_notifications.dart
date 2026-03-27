import 'booking_cancellation.dart';
import 'firebase_push.dart';
import 'models.dart';

class UserNotificationsService {
  const UserNotificationsService(this._firebasePushService);

  final FirebasePushService _firebasePushService;

  bool get isConfigured => _firebasePushService.isConfigured;

  List<String> _tokensForUser(UserModel user) {
    return user.pushTokens
        .map((PushTokenModel item) => item.token.trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  Future<void> sendBookingStatusNotification({
    required UserModel user,
    required BookingModel booking,
    required String actor,
  }) async {
    final List<String> tokens = _tokensForUser(user);
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
        if (booking.previousDateTime != null)
          'previousDateTime': booking.previousDateTime!.toUtc().toIso8601String(),
        'dateTime': booking.dateTime.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> sendBookingChatNotification({
    required UserModel user,
    required BookingModel booking,
    required BookingChatMessageModel message,
  }) async {
    final List<String> tokens = _tokensForUser(user);
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
    final List<String> tokens = _tokensForUser(user);
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

  Future<void> sendReviewReminderNotification({
    required UserModel user,
    required BookingModel booking,
    required WorkshopModel workshop,
  }) async {
    final List<String> tokens = _tokensForUser(user);
    if (tokens.isEmpty) {
      throw const FirebasePushException(
        'Foydalanuvchi uchun push token topilmadi',
      );
    }

    await _firebasePushService.sendToTokens(
      tokens: tokens,
      title: 'Usta Top: sharh qoldirish vaqti bo‘ldi',
      body:
          '${workshop.name} dagi ${booking.serviceName} xizmati yakunlandi. Qisqa sharh yozib qo‘ying.',
      data: <String, String>{
        'type': 'review_reminder',
        'screen': 'workshop_review',
        'workshopId': workshop.id,
        'serviceId': booking.serviceId,
        'bookingId': booking.id,
      },
    );
  }

  Future<void> sendUpcomingBookingReminderNotification({
    required UserModel user,
    required BookingModel booking,
    required WorkshopModel workshop,
    required Duration leadTime,
  }) async {
    final List<String> tokens = _tokensForUser(user);
    if (tokens.isEmpty) {
      throw const FirebasePushException(
        'Foydalanuvchi uchun push token topilmadi',
      );
    }

    await _firebasePushService.sendToTokens(
      tokens: tokens,
      title: 'Usta Top: broningiz yaqinlashdi',
      body:
          '${workshop.name} dagi ${booking.serviceName} ${_formatDateTime(booking.dateTime)} da boshlanadi. ${_leadTimeLabel(leadTime)} qoldi.',
      data: <String, String>{
        'type': 'booking_reminder',
        'screen': 'bookings',
        'bookingId': booking.id,
        'workshopId': booking.workshopId,
        'status': booking.status.name,
        'dateTime': booking.dateTime.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> sendTestNotification({
    required UserModel user,
  }) async {
    final List<String> tokens = _tokensForUser(user);
    if (tokens.isEmpty) {
      throw const FirebasePushException(
        'Foydalanuvchi uchun push token topilmadi',
      );
    }

    await _firebasePushService.sendToTokens(
      tokens: tokens,
      title: 'Usta Top: test push',
      body: 'Push notification ishlayapti. Ilova yopiq bo‘lsa ham shu xabar chiqishi kerak.',
      data: <String, String>{
        'type': 'push_test',
      },
    );
  }

  String _titleForBookingStatus(BookingModel booking) {
    switch (booking.status) {
      case BookingStatus.accepted:
        return 'Usta Top: zakaz qabul qilindi';
      case BookingStatus.rescheduled:
        return 'Usta Top: zakaz vaqti ko‘chirildi';
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
      case BookingStatus.accepted:
        return '${booking.workshopName} sizning ${booking.serviceName} zakazingizni qabul qildi.';
      case BookingStatus.rescheduled:
        final String previous = booking.previousDateTime == null
            ? 'oldingi vaqt ko‘rsatilmagan'
            : _formatDateTime(booking.previousDateTime!);
        return '$actor ${booking.workshopName} zakazingiz vaqtini $previous dan ${_formatDateTime(booking.dateTime)} ga ko‘chirdi.';
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

  String _formatDateTime(DateTime value) {
    final DateTime local = value.toLocal();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  String _leadTimeLabel(Duration value) {
    if (value.inHours >= 1 && value.inMinutes % 60 == 0) {
      return '${value.inHours} soat';
    }
    return '${value.inMinutes} daqiqa';
  }
}
