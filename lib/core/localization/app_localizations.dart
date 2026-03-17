import 'package:flutter/material.dart';

import 'app_language.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? l10n = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(l10n != null, 'AppLocalizations is not found in widget tree');
    return l10n!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('uz'),
    Locale('ru'),
  ];

  static const Map<String, Map<String, String>> _strings =
      <String, Map<String, String>>{
    'en': <String, String>{
      'appTitle': 'Usta Top',
      'navHome': 'Home',
      'navBookings': 'Bookings',
      'navProfile': 'Profile',
      'bookingAdded': 'Booking added for {salon}',
      'bookingCancelled': 'Booking cancelled',
      'savedSalonsConnectedHome':
          'Saved salons section is connected to Home list for now',
      'notificationsEnabled': 'Notifications enabled',
      'notificationsDisabled': 'Notifications disabled',
      'languageSwitched': 'Language switched to {language}',
      'findTrustedMasters': 'Find trusted masters and book in under one minute',
      'searchHint': 'Search salon, district, or service',
      'salonsNearby': '{count} salons nearby',
      'fastConfirmation': 'Fast confirmation',
      'verifiedMasters': 'Verified masters',
      'masterPrefix': 'Master: {name}',
      'openNow': 'Open now',
      'closed': 'Closed',
      'closedNow': 'Closed now',
      'fromPrice': 'From {price}',
      'noSalonsFound': 'No salons found',
      'tryDifferentSearch': 'Try a different search keyword.',
      'services': 'Services',
      'durationMinutes': '{minutes} min',
      'book': 'Book',
      'bookNowFrom': 'Book now from {price}',
      'currentlyClosed': 'Currently closed',
      'bookAppointment': 'Book Appointment',
      'service': 'Service',
      'date': 'Date',
      'availableTimes': 'Available times',
      'summary': 'Summary',
      'serviceLabel': 'Service: {service}',
      'durationLabel': 'Duration: {duration}',
      'dateLabel': 'Date: {date}',
      'timeLabel': 'Time: {time}',
      'totalLabel': 'Total: {total}',
      'confirmBooking': 'Confirm Booking',
      'priceLabel': 'Price: {price}',
      'cancelBooking': 'Cancel booking',
      'noBookingsYet': 'No bookings yet',
      'bookingsEmptyHint':
          'Open Home, choose a salon, and create your first booking.',
      'statusUpcoming': 'Upcoming',
      'statusCompleted': 'Completed',
      'statusCancelled': 'Cancelled',
      'totalBookings': 'Total bookings',
      'upcoming': 'Upcoming',
      'bookingHistory': 'Booking history',
      'bookingHistorySubtitle': 'Review your completed and cancelled bookings',
      'savedSalons': 'Saved salons',
      'savedSalonsSubtitle': 'Quick access to your favorite places',
      'notifications': 'Notifications',
      'enabled': 'Enabled',
      'disabled': 'Disabled',
      'language': 'Language',
      'signOut': 'Sign out',
      'signOutTitle': 'Sign out',
      'signOutConfirm': 'Are you sure you want to sign out?',
      'cancel': 'Cancel',
      'login': 'Login',
      'welcomeBack': 'Welcome back',
      'signInDescription': 'Sign in to manage your bookings and profile.',
      'phoneNumber': 'Phone number',
      'phoneHint': '+998 90 123 45 67',
      'phoneRequired': 'Phone number is required',
      'phoneInvalid': 'Enter a valid phone number',
      'password': 'Password',
      'passwordRequired': 'Password is required',
      'passwordLength': 'Password must be at least 6 characters',
      'signIn': 'Sign in',
      'loginSuccessful': 'Login successful',
      'english': 'English',
      'uzbek': 'Uzbek',
      'russian': 'Russian',
    },
    'uz': <String, String>{
      'appTitle': 'Usta Top',
      'navHome': 'Asosiy',
      'navBookings': 'Bandlar',
      'navProfile': 'Profil',
      'bookingAdded': '{salon} uchun band qo\'shildi',
      'bookingCancelled': 'Band bekor qilindi',
      'savedSalonsConnectedHome':
          'Saqlangan salonlar bo\'limi hozircha Asosiy ro\'yxat bilan bog\'langan',
      'notificationsEnabled': 'Bildirishnomalar yoqildi',
      'notificationsDisabled': 'Bildirishnomalar o\'chirildi',
      'languageSwitched': 'Til {language} ga o\'zgartirildi',
      'findTrustedMasters':
          'Ishonchli ustalarni toping va bir daqiqada band qiling',
      'searchHint': 'Salon, tuman yoki xizmatni qidiring',
      'salonsNearby': 'Yaqinda {count} ta salon',
      'fastConfirmation': 'Tez tasdiqlash',
      'verifiedMasters': 'Tasdiqlangan ustalar',
      'masterPrefix': 'Usta: {name}',
      'openNow': 'Hozir ochiq',
      'closed': 'Yopiq',
      'closedNow': 'Hozir yopiq',
      'fromPrice': '{price} dan',
      'noSalonsFound': 'Salon topilmadi',
      'tryDifferentSearch': 'Boshqa kalit so\'z bilan urinib ko\'ring.',
      'services': 'Xizmatlar',
      'durationMinutes': '{minutes} daqiqa',
      'book': 'Band qilish',
      'bookNowFrom': '{price} dan band qilish',
      'currentlyClosed': 'Hozir yopiq',
      'bookAppointment': 'Qabulga yozilish',
      'service': 'Xizmat',
      'date': 'Sana',
      'availableTimes': 'Mavjud vaqtlar',
      'summary': 'Xulosa',
      'serviceLabel': 'Xizmat: {service}',
      'durationLabel': 'Davomiyligi: {duration}',
      'dateLabel': 'Sana: {date}',
      'timeLabel': 'Vaqt: {time}',
      'totalLabel': 'Jami: {total}',
      'confirmBooking': 'Bandni tasdiqlash',
      'priceLabel': 'Narx: {price}',
      'cancelBooking': 'Bandni bekor qilish',
      'noBookingsYet': 'Hali bandlar yo\'q',
      'bookingsEmptyHint':
          'Asosiy sahifadan salon tanlab birinchi bandingizni yarating.',
      'statusUpcoming': 'Kutilmoqda',
      'statusCompleted': 'Yakunlangan',
      'statusCancelled': 'Bekor qilingan',
      'totalBookings': 'Jami bandlar',
      'upcoming': 'Kutilmoqda',
      'bookingHistory': 'Bandlar tarixi',
      'bookingHistorySubtitle':
          'Yakunlangan va bekor qilingan bandlarni ko\'ring',
      'savedSalons': 'Saqlangan salonlar',
      'savedSalonsSubtitle': 'Yoqtirgan joylaringizga tez kirish',
      'notifications': 'Bildirishnomalar',
      'enabled': 'Yoqilgan',
      'disabled': 'O\'chirilgan',
      'language': 'Til',
      'signOut': 'Chiqish',
      'signOutTitle': 'Chiqish',
      'signOutConfirm': 'Rostdan ham akkauntdan chiqmoqchimisiz?',
      'cancel': 'Bekor qilish',
      'login': 'Kirish',
      'welcomeBack': 'Qaytganingiz bilan',
      'signInDescription':
          'Bandlaringiz va profilingizni boshqarish uchun kiring.',
      'phoneNumber': 'Telefon raqam',
      'phoneHint': '+998 90 123 45 67',
      'phoneRequired': 'Telefon raqam majburiy',
      'phoneInvalid': 'To\'g\'ri telefon raqam kiriting',
      'password': 'Parol',
      'passwordRequired': 'Parol majburiy',
      'passwordLength': 'Parol kamida 6 ta belgidan iborat bo\'lsin',
      'signIn': 'Kirish',
      'loginSuccessful': 'Muvaffaqiyatli kirildi',
      'english': 'Inglizcha',
      'uzbek': 'O\'zbekcha',
      'russian': 'Ruscha',
    },
    'ru': <String, String>{
      'appTitle': 'Usta Top',
      'navHome': 'Главная',
      'navBookings': 'Записи',
      'navProfile': 'Профиль',
      'bookingAdded': 'Запись добавлена в {salon}',
      'bookingCancelled': 'Запись отменена',
      'savedSalonsConnectedHome':
          'Раздел избранных салонов пока связан со списком на Главной',
      'notificationsEnabled': 'Уведомления включены',
      'notificationsDisabled': 'Уведомления отключены',
      'languageSwitched': 'Язык переключен на {language}',
      'findTrustedMasters': 'Найдите надежных мастеров и запишитесь за минуту',
      'searchHint': 'Поиск салона, района или услуги',
      'salonsNearby': 'Салонов рядом: {count}',
      'fastConfirmation': 'Быстрое подтверждение',
      'verifiedMasters': 'Проверенные мастера',
      'masterPrefix': 'Мастер: {name}',
      'openNow': 'Открыто',
      'closed': 'Закрыто',
      'closedNow': 'Сейчас закрыто',
      'fromPrice': 'От {price}',
      'noSalonsFound': 'Салоны не найдены',
      'tryDifferentSearch': 'Попробуйте другой поисковый запрос.',
      'services': 'Услуги',
      'durationMinutes': '{minutes} мин',
      'book': 'Записаться',
      'bookNowFrom': 'Записаться от {price}',
      'currentlyClosed': 'Сейчас закрыто',
      'bookAppointment': 'Запись',
      'service': 'Услуга',
      'date': 'Дата',
      'availableTimes': 'Доступное время',
      'summary': 'Сводка',
      'serviceLabel': 'Услуга: {service}',
      'durationLabel': 'Длительность: {duration}',
      'dateLabel': 'Дата: {date}',
      'timeLabel': 'Время: {time}',
      'totalLabel': 'Итого: {total}',
      'confirmBooking': 'Подтвердить запись',
      'priceLabel': 'Цена: {price}',
      'cancelBooking': 'Отменить запись',
      'noBookingsYet': 'Записей пока нет',
      'bookingsEmptyHint':
          'Откройте Главную, выберите салон и создайте первую запись.',
      'statusUpcoming': 'Предстоит',
      'statusCompleted': 'Завершено',
      'statusCancelled': 'Отменено',
      'totalBookings': 'Всего записей',
      'upcoming': 'Предстоит',
      'bookingHistory': 'История записей',
      'bookingHistorySubtitle': 'Просмотр завершенных и отмененных записей',
      'savedSalons': 'Избранные салоны',
      'savedSalonsSubtitle': 'Быстрый доступ к любимым местам',
      'notifications': 'Уведомления',
      'enabled': 'Включено',
      'disabled': 'Выключено',
      'language': 'Язык',
      'signOut': 'Выйти',
      'signOutTitle': 'Выход',
      'signOutConfirm': 'Вы уверены, что хотите выйти?',
      'cancel': 'Отмена',
      'login': 'Вход',
      'welcomeBack': 'С возвращением',
      'signInDescription': 'Войдите, чтобы управлять записями и профилем.',
      'phoneNumber': 'Номер телефона',
      'phoneHint': '+998 90 123 45 67',
      'phoneRequired': 'Введите номер телефона',
      'phoneInvalid': 'Введите корректный номер телефона',
      'password': 'Пароль',
      'passwordRequired': 'Введите пароль',
      'passwordLength': 'Пароль должен быть не менее 6 символов',
      'signIn': 'Войти',
      'loginSuccessful': 'Вход выполнен',
      'english': 'Английский',
      'uzbek': 'Узбекский',
      'russian': 'Русский',
    },
  };

  String _text(String key) {
    final String code = locale.languageCode;
    return _strings[code]?[key] ?? _strings['en']![key] ?? key;
  }

  String _fmt(String key, Map<String, Object> values) {
    String result = _text(key);
    for (final MapEntry<String, Object> entry in values.entries) {
      result = result.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return result;
  }

  String get appTitle => _text('appTitle');
  String get navHome => _text('navHome');
  String get navBookings => _text('navBookings');
  String get navProfile => _text('navProfile');

  String bookingAdded(String salon) =>
      _fmt('bookingAdded', <String, Object>{'salon': salon});

  String get bookingCancelled => _text('bookingCancelled');
  String get savedSalonsConnectedHome => _text('savedSalonsConnectedHome');
  String get notificationsEnabled => _text('notificationsEnabled');
  String get notificationsDisabled => _text('notificationsDisabled');

  String languageSwitched(String language) =>
      _fmt('languageSwitched', <String, Object>{'language': language});

  String get findTrustedMasters => _text('findTrustedMasters');
  String get searchHint => _text('searchHint');
  String salonsNearby(int count) =>
      _fmt('salonsNearby', <String, Object>{'count': count});
  String get fastConfirmation => _text('fastConfirmation');
  String get verifiedMasters => _text('verifiedMasters');
  String masterPrefix(String name) =>
      _fmt('masterPrefix', <String, Object>{'name': name});
  String get openNow => _text('openNow');
  String get closed => _text('closed');
  String get closedNow => _text('closedNow');
  String fromPrice(String price) =>
      _fmt('fromPrice', <String, Object>{'price': price});
  String get noSalonsFound => _text('noSalonsFound');
  String get tryDifferentSearch => _text('tryDifferentSearch');

  String get services => _text('services');
  String durationMinutes(int minutes) =>
      _fmt('durationMinutes', <String, Object>{'minutes': minutes});
  String get book => _text('book');
  String bookNowFrom(String price) =>
      _fmt('bookNowFrom', <String, Object>{'price': price});
  String get currentlyClosed => _text('currentlyClosed');

  String get bookAppointment => _text('bookAppointment');
  String get service => _text('service');
  String get date => _text('date');
  String get availableTimes => _text('availableTimes');
  String get summary => _text('summary');
  String serviceLabel(String service) =>
      _fmt('serviceLabel', <String, Object>{'service': service});
  String durationLabel(String duration) =>
      _fmt('durationLabel', <String, Object>{'duration': duration});
  String dateLabel(String date) =>
      _fmt('dateLabel', <String, Object>{'date': date});
  String timeLabel(String time) =>
      _fmt('timeLabel', <String, Object>{'time': time});
  String totalLabel(String total) =>
      _fmt('totalLabel', <String, Object>{'total': total});
  String get confirmBooking => _text('confirmBooking');
  String priceLabel(String price) =>
      _fmt('priceLabel', <String, Object>{'price': price});

  String get cancelBooking => _text('cancelBooking');
  String get noBookingsYet => _text('noBookingsYet');
  String get bookingsEmptyHint => _text('bookingsEmptyHint');
  String get statusUpcoming => _text('statusUpcoming');
  String get statusCompleted => _text('statusCompleted');
  String get statusCancelled => _text('statusCancelled');

  String get totalBookings => _text('totalBookings');
  String get upcoming => _text('upcoming');
  String get bookingHistory => _text('bookingHistory');
  String get bookingHistorySubtitle => _text('bookingHistorySubtitle');
  String get savedSalons => _text('savedSalons');
  String get savedSalonsSubtitle => _text('savedSalonsSubtitle');
  String get notifications => _text('notifications');
  String get enabled => _text('enabled');
  String get disabled => _text('disabled');
  String get language => _text('language');
  String get signOut => _text('signOut');
  String get signOutTitle => _text('signOutTitle');
  String get signOutConfirm => _text('signOutConfirm');
  String get cancel => _text('cancel');

  String get login => _text('login');
  String get welcomeBack => _text('welcomeBack');
  String get signInDescription => _text('signInDescription');
  String get phoneNumber => _text('phoneNumber');
  String get phoneHint => _text('phoneHint');
  String get phoneRequired => _text('phoneRequired');
  String get phoneInvalid => _text('phoneInvalid');
  String get password => _text('password');
  String get passwordRequired => _text('passwordRequired');
  String get passwordLength => _text('passwordLength');
  String get signIn => _text('signIn');
  String get loginSuccessful => _text('loginSuccessful');

  String languageName(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return _text('english');
      case AppLanguage.uzbek:
        return _text('uzbek');
      case AppLanguage.russian:
        return _text('russian');
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((Locale item) => item.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
