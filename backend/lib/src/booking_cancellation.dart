class BookingCancellationReason {
  const BookingCancellationReason({
    required this.id,
    required this.labels,
  });

  final String id;
  final Map<String, String> labels;

  String label(String lang) => labels[lang] ?? labels['uz'] ?? id;
}

const Duration workshopCancellationLeadTime = Duration(minutes: 30);

const List<BookingCancellationReason> bookingCancellationReasons =
    <BookingCancellationReason>[
  BookingCancellationReason(
    id: 'workshop_busy',
    labels: <String, String>{
      'uz': 'Jadval band',
      'ru': 'График занят',
      'en': 'Schedule is full',
    },
  ),
  BookingCancellationReason(
    id: 'master_unavailable',
    labels: <String, String>{
      'uz': 'Usta mavjud emas',
      'ru': 'Мастер недоступен',
      'en': 'Technician unavailable',
    },
  ),
  BookingCancellationReason(
    id: 'workshop_closed',
    labels: <String, String>{
      'uz': 'Ustaxona yopiq',
      'ru': 'Сервис закрыт',
      'en': 'Workshop closed',
    },
  ),
  BookingCancellationReason(
    id: 'missing_parts',
    labels: <String, String>{
      'uz': 'Ehtiyot qism yo‘q',
      'ru': 'Нет запчастей',
      'en': 'Parts unavailable',
    },
  ),
  BookingCancellationReason(
    id: 'customer_request',
    labels: <String, String>{
      'uz': 'Mijoz so‘rovi',
      'ru': 'По просьбе клиента',
      'en': 'Customer request',
    },
  ),
];

BookingCancellationReason bookingCancellationReasonById(String raw) {
  final String normalized = raw.trim().toLowerCase();
  for (final BookingCancellationReason item in bookingCancellationReasons) {
    if (item.id == normalized) {
      return item;
    }
  }
  return bookingCancellationReasons.first;
}

String normalizeBookingCancellationReasonId(String raw) {
  final String normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) {
    return '';
  }
  return bookingCancellationReasonById(normalized).id;
}

String normalizeBookingCancellationActor(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'customer':
      return 'customer';
    case 'admin':
      return 'admin';
    case 'owner_panel':
      return 'owner_panel';
    case 'owner_telegram':
      return 'owner_telegram';
    default:
      return '';
  }
}

String bookingCancellationActorLabel(String raw, String lang) {
  switch (normalizeBookingCancellationActor(raw)) {
    case 'customer':
      return switch (lang) {
        'ru' => 'Клиент',
        'en' => 'Customer',
        _ => 'Mijoz',
      };
    case 'admin':
      return switch (lang) {
        'ru' => 'Админ',
        'en' => 'Admin',
        _ => 'Admin',
      };
    case 'owner_panel':
      return switch (lang) {
        'ru' => 'Владелец сервиса',
        'en' => 'Workshop owner',
        _ => 'Ustaxona egasi',
      };
    case 'owner_telegram':
      return switch (lang) {
        'ru' => 'Владелец через Telegram',
        'en' => 'Owner via Telegram',
        _ => 'Telegram orqali usta',
      };
    default:
      return switch (lang) {
        'ru' => 'Не указано',
        'en' => 'Unknown',
        _ => 'Ko‘rsatilmagan',
      };
  }
}
