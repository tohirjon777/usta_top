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
      text: '''
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
''',
    );
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
Yakuniy narx: ${booking.price}k
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
    );
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
}
