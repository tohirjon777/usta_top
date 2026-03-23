import 'booking_cancellation.dart';
import 'models.dart';
import 'telegram_bot.dart';
import 'vehicle_types.dart';

class WorkshopNotificationsService {
  const WorkshopNotificationsService(this._telegramBotService);

  final TelegramBotService _telegramBotService;

  bool get isConfigured => _telegramBotService.isConfigured;

  Future<void> sendNewBookingNotification({
    required WorkshopModel workshop,
    required BookingModel booking,
  }) {
    return _sendToWorkshop(
      workshop: workshop,
      text: newBookingText(
        workshop: workshop,
        booking: booking,
      ),
      replyMarkup: bookingActionMarkup(
        workshop: workshop,
        booking: booking,
      ),
    );
  }

  String newBookingText({
    required WorkshopModel workshop,
    required BookingModel booking,
    bool includeStatus = false,
  }) {
    return '''
Usta Top: yangi zakaz tushdi

Avtoservis: ${workshop.name}
Zakaz ID: ${booking.id}
Mijoz: ${_safeValue(booking.customerName)}
Telefon: ${_safeValue(booking.customerPhone)}
Xizmat: ${booking.serviceName}
Mashina: ${_vehicleSummary(booking)}
Vaqt: ${_formatDateTime(booking.dateTime)}
Asosiy narx: ${booking.basePrice}k
Yakuniy narx: ${booking.price}k
${includeStatus ? 'Holat: ${_statusLabel(booking.status)}\n' : ''}''';
  }

  Future<void> sendBookingStatusNotification({
    required WorkshopModel workshop,
    required BookingModel booking,
    required String actor,
  }) {
    return _sendToWorkshop(
      workshop: workshop,
      text: '''
Usta Top: zakaz statusi yangilandi

Avtoservis: ${workshop.name}
Zakaz ID: ${booking.id}
Holat: ${_statusLabel(booking.status)}
Kim o‘zgartirdi: $actor
Mijoz: ${_safeValue(booking.customerName)}
Telefon: ${_safeValue(booking.customerPhone)}
Xizmat: ${booking.serviceName}
Mashina: ${_vehicleSummary(booking)}
Vaqt: ${_formatDateTime(booking.dateTime)}
${booking.status == BookingStatus.cancelled ? 'Bekor qildi: ${_cancellationActor(booking)}\nBekor qilish sababi: ${_cancellationReason(booking)}\n' : ''}Yakuniy narx: ${booking.price}k
''',
    );
  }

  Future<void> sendTestNotification({
    required WorkshopModel workshop,
  }) {
    return _sendToWorkshop(
      workshop: workshop,
      text: '''
Usta Top Telegram ulanishi tayyor.

Avtoservis: ${workshop.name}
Workshop ID: ${workshop.id}

Bu test xabar. Endi yangi zakaz tushganda yoki status o‘zgarganda shu chatga bildirishnoma keladi.
''',
    );
  }

  Future<void> _sendToWorkshop({
    required WorkshopModel workshop,
    required String text,
    Map<String, Object>? replyMarkup,
  }) async {
    if (!_telegramBotService.isConfigured) {
      throw const TelegramBotException('Telegram bot token sozlanmagan');
    }

    final String chatId = workshop.telegramChatId.trim();
    if (chatId.isEmpty) {
      throw const TelegramBotException(
        'Workshop uchun Telegram chat ID kiritilmagan',
      );
    }

    await _telegramBotService.sendMessage(
      chatId: chatId,
      text: text.trim(),
      replyMarkup: replyMarkup,
    );
  }

  Map<String, Object>? bookingActionMarkup({
    required WorkshopModel workshop,
    required BookingModel booking,
  }) {
    if (booking.status != BookingStatus.upcoming) {
      return null;
    }

    return <String, Object>{
      'inline_keyboard': <List<Map<String, String>>>[
        <Map<String, String>>[
          <String, String>{
            'text': 'Bajardim',
            'callback_data': completedBookingCallbackData(
              workshopId: workshop.id,
              bookingId: booking.id,
            ),
          },
        ],
        <Map<String, String>>[
          <String, String>{
            'text': 'Bekor: jadval band',
            'callback_data': cancelledBookingCallbackData(
              reasonId: 'workshop_busy',
              workshopId: workshop.id,
              bookingId: booking.id,
            ),
          },
          <String, String>{
            'text': 'Bekor: usta yo‘q',
            'callback_data': cancelledBookingCallbackData(
              reasonId: 'master_unavailable',
              workshopId: workshop.id,
              bookingId: booking.id,
            ),
          },
        ],
        <Map<String, String>>[
          <String, String>{
            'text': 'Bekor: ustaxona yopiq',
            'callback_data': cancelledBookingCallbackData(
              reasonId: 'workshop_closed',
              workshopId: workshop.id,
              bookingId: booking.id,
            ),
          },
          <String, String>{
            'text': 'Bekor: qism yo‘q',
            'callback_data': cancelledBookingCallbackData(
              reasonId: 'missing_parts',
              workshopId: workshop.id,
              bookingId: booking.id,
            ),
          },
        ],
      ],
    };
  }

  static String completedBookingCallbackData({
    required String workshopId,
    required String bookingId,
  }) {
    return 'done:$workshopId:$bookingId';
  }

  static String cancelledBookingCallbackData({
    required String reasonId,
    required String workshopId,
    required String bookingId,
  }) {
    return 'cancel:${normalizeBookingCancellationReasonId(reasonId)}:$workshopId:$bookingId';
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return 'Kutilmoqda';
      case BookingStatus.completed:
        return 'Yakunlangan';
      case BookingStatus.cancelled:
        return 'Bekor qilingan';
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

  String _safeValue(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return 'Ko‘rsatilmagan';
    }
    return normalized;
  }

  String _vehicleSummary(BookingModel booking) {
    final String vehicleType = vehicleTypePricingById(booking.vehicleTypeId).label(
      'uz',
    );
    final String model = booking.vehicleModel.trim();
    if (model.isEmpty) {
      return vehicleType;
    }
    return '$model • $vehicleType';
  }

  String _cancellationReason(BookingModel booking) {
    final String reasonId = booking.cancelReasonId.trim();
    if (reasonId.isEmpty) {
      return 'Ko‘rsatilmagan';
    }
    return bookingCancellationReasonById(reasonId).label('uz');
  }

  String _cancellationActor(BookingModel booking) {
    return bookingCancellationActorLabel(booking.cancelledByRole, 'uz');
  }
}
