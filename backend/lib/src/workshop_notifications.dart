import 'booking_cancellation.dart';
import 'money.dart';
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
        includeStatus: true,
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
Asosiy narx: ${formatMoneyUzs(booking.basePrice)}
Yakuniy narx: ${formatMoneyUzs(booking.price)}
${_rescheduleMetaText(booking)}
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
${_rescheduleMetaText(booking)}
${booking.status == BookingStatus.cancelled ? 'Bekor qildi: ${_cancellationActor(booking)}\nBekor qilish sababi: ${_cancellationReason(booking)}\n' : ''}Yakuniy narx: ${formatMoneyUzs(booking.price)}
''',
    );
  }

  Future<void> sendUpcomingBookingReminder({
    required WorkshopModel workshop,
    required BookingModel booking,
    required Duration leadTime,
  }) {
    return _sendToWorkshop(
      workshop: workshop,
      text: '''
Usta Top: bron eslatmasi

Avtoservis: ${workshop.name}
Zakaz ID: ${booking.id}
Mijoz: ${_safeValue(booking.customerName)}
Telefon: ${_safeValue(booking.customerPhone)}
Xizmat: ${booking.serviceName}
Mashina: ${_vehicleSummary(booking)}
Vaqt: ${_formatDateTime(booking.dateTime)}
Boshlanishiga: ${_leadTimeLabel(leadTime)}
Holat: ${_statusLabel(booking.status)}
Yakuniy narx: ${formatMoneyUzs(booking.price)}
''',
      replyMarkup: bookingActionMarkup(
        workshop: workshop,
        booking: booking,
      ),
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

  Future<void> sendChatMessageNotification({
    required WorkshopModel workshop,
    required BookingModel booking,
    required BookingChatMessageModel message,
  }) {
    return _sendToWorkshop(
      workshop: workshop,
      text: '''
Usta Top: mijozdan yangi chat xabari

Avtoservis: ${workshop.name}
Zakaz ID: ${booking.id}
Mijoz: ${_safeValue(booking.customerName)}
Telefon: ${_safeValue(booking.customerPhone)}
Xizmat: ${booking.serviceName}
Xabar: ${bookingChatPreview(message.text, maxLength: 220)}
''',
    );
  }

  Future<void> sendNewReviewNotification({
    required WorkshopModel workshop,
    required WorkshopReviewModel review,
  }) {
    return _sendToWorkshop(
      workshop: workshop,
      text: '''
Usta Top: yangi sharh qoldirildi

Avtoservis: ${workshop.name}
Sharh ID: ${review.id}
Mijoz: ${_safeValue(review.customerName)}
Telefon: ${_safeValue(review.customerPhone)}
Xizmat: ${review.serviceName}
Baho: ${_ratingStars(review.rating)} (${review.rating}/5)
Sharh: ${workshopReviewPreview(review.comment, maxLength: 320)}

Telegramdan javob berish uchun shu xabarga reply qiling.
''',
    );
  }

  Future<void> sendReviewReplyReminder({
    required WorkshopModel workshop,
    required WorkshopReviewModel review,
  }) {
    return _sendToWorkshop(
      workshop: workshop,
      text: '''
Usta Top: admin eslatmasi

Avtoservis: ${workshop.name}
Sharh ID: ${review.id}
Mijoz: ${_safeValue(review.customerName)}
Telefon: ${_safeValue(review.customerPhone)}
Xizmat: ${review.serviceName}
Baho: ${_ratingStars(review.rating)} (${review.rating}/5)
Sharh: ${workshopReviewPreview(review.comment, maxLength: 320)}

Bu sharh hali javobsiz. Telegramda shu xabarga reply qiling yoki owner paneldan javob yozing.
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
    if (booking.status == BookingStatus.completed ||
        booking.status == BookingStatus.cancelled) {
      return null;
    }

    return <String, Object>{
      'inline_keyboard': <List<Map<String, String>>>[
        <Map<String, String>>[
          if (booking.status == BookingStatus.upcoming ||
              booking.status == BookingStatus.rescheduled)
            <String, String>{
              'text': 'Qabul qilindi',
              'callback_data': acceptedBookingCallbackData(
                workshopId: workshop.id,
                bookingId: booking.id,
              ),
            },
          <String, String>{
            'text': 'Ko‘chirish',
            'callback_data': rescheduleBookingCallbackData(
              workshopId: workshop.id,
              bookingId: booking.id,
            ),
          },
        ],
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

  Map<String, Object> bookingRescheduleOptionsMarkup({
    required WorkshopModel workshop,
    required BookingModel booking,
    required List<DateTime> suggestions,
  }) {
    final List<List<Map<String, String>>> rows = <List<Map<String, String>>>[];
    for (final DateTime slot in suggestions) {
      rows.add(<Map<String, String>>[
        <String, String>{
          'text': _formatSlotButton(slot),
          'callback_data': pickRescheduleBookingCallbackData(
            workshopId: workshop.id,
            bookingId: booking.id,
            slot: slot,
          ),
        },
      ]);
    }
    rows.add(<Map<String, String>>[
      <String, String>{
        'text': 'Ortga',
        'callback_data': restoreBookingActionsCallbackData(
          workshopId: workshop.id,
          bookingId: booking.id,
        ),
      },
    ]);
    return <String, Object>{'inline_keyboard': rows};
  }

  String bookingRescheduleSelectionText({
    required WorkshopModel workshop,
    required BookingModel booking,
    required List<DateTime> suggestions,
  }) {
    final String suggestionsText = suggestions
        .map((DateTime item) => '• ${_formatDateTime(item)}')
        .join('\n');
    return '''
Usta Top: yangi vaqtni tanlang

Avtoservis: ${workshop.name}
Zakaz ID: ${booking.id}
Mijoz: ${_safeValue(booking.customerName)}
Xizmat: ${booking.serviceName}
Joriy vaqt: ${_formatDateTime(booking.dateTime)}

$suggestionsText
''';
  }

  static String acceptedBookingCallbackData({
    required String workshopId,
    required String bookingId,
  }) {
    return 'a:${bookingId.trim()}';
  }

  static String completedBookingCallbackData({
    required String workshopId,
    required String bookingId,
  }) {
    return 'd:${bookingId.trim()}';
  }

  static String rescheduleBookingCallbackData({
    required String workshopId,
    required String bookingId,
  }) {
    return 'r:${bookingId.trim()}';
  }

  static String restoreBookingActionsCallbackData({
    required String workshopId,
    required String bookingId,
  }) {
    return 'b:${bookingId.trim()}';
  }

  static String pickRescheduleBookingCallbackData({
    required String workshopId,
    required String bookingId,
    required DateTime slot,
  }) {
    final DateTime local = slot.toLocal();
    final String code =
        '${local.year.toString().padLeft(4, '0')}${local.month.toString().padLeft(2, '0')}${local.day.toString().padLeft(2, '0')}${local.hour.toString().padLeft(2, '0')}${local.minute.toString().padLeft(2, '0')}';
    return 's:$code:${bookingId.trim()}';
  }

  static String cancelledBookingCallbackData({
    required String reasonId,
    required String workshopId,
    required String bookingId,
  }) {
    final String normalizedReason =
        normalizeBookingCancellationReasonId(reasonId);
    return 'c:${_cancellationReasonShortCode(normalizedReason)}:${bookingId.trim()}';
  }

  static String _cancellationReasonShortCode(String reasonId) {
    switch (normalizeBookingCancellationReasonId(reasonId)) {
      case 'workshop_busy':
        return 'wb';
      case 'master_unavailable':
        return 'mu';
      case 'workshop_closed':
        return 'wc';
      case 'missing_parts':
        return 'mp';
      case 'customer_request':
        return 'cr';
    }
    return 'uk';
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return 'Kutilmoqda';
      case BookingStatus.accepted:
        return 'Qabul qilindi';
      case BookingStatus.rescheduled:
        return 'Ko‘chirildi';
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
    final String vehicleType =
        vehicleTypePricingById(booking.vehicleTypeId).label(
      'uz',
    );
    final String model = booking.vehicleModel.trim();
    if (model.isEmpty) {
      return vehicleType;
    }
    return '$model • $vehicleType';
  }

  String _ratingStars(int rating) {
    final int normalized = rating.clamp(1, 5);
    return List<String>.filled(normalized, '★').join();
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

  String _rescheduleMetaText(BookingModel booking) {
    if (booking.previousDateTime == null || booking.status != BookingStatus.rescheduled) {
      return '';
    }
    return 'Oldingi vaqt: ${_formatDateTime(booking.previousDateTime!)}\n';
  }

  String _leadTimeLabel(Duration value) {
    if (value.inHours >= 1 && value.inMinutes % 60 == 0) {
      return '${value.inHours} soat qoldi';
    }
    return '${value.inMinutes} daqiqa qoldi';
  }

  String _formatSlotButton(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month $hour:$minute';
  }
}
