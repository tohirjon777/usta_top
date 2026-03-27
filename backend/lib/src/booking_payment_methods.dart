String normalizeBookingPaymentMethod(String raw) {
  final String value = raw.trim().toLowerCase();
  switch (value) {
    case 'cash':
      return 'cash';
    case 'card':
    case 'test_card':
    case 'bank_card':
    case 'click':
    case 'payme':
    case 'uzum':
      return 'test_card';
    default:
      return value;
  }
}

String bookingPaymentMethodLabel(
  String raw, {
  String lang = 'uz',
}) {
  final String method = normalizeBookingPaymentMethod(raw);
  switch (lang) {
    case 'ru':
      switch (method) {
        case 'cash':
          return 'Наличные';
        case 'test_card':
          return 'Тестовая карта';
        default:
          return raw.trim().isEmpty ? 'Не указано' : raw.trim();
      }
    case 'en':
      switch (method) {
        case 'cash':
          return 'Cash';
        case 'test_card':
          return 'Test card';
        default:
          return raw.trim().isEmpty ? 'Not specified' : raw.trim();
      }
    case 'uz':
    default:
      switch (method) {
        case 'cash':
          return 'Naqd';
        case 'test_card':
          return 'Test karta';
        default:
          return raw.trim().isEmpty ? 'Ko‘rsatilmagan' : raw.trim();
      }
  }
}
