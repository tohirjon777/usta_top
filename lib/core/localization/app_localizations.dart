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
      'navMap': 'Map',
      'navBookings': 'Requests',
      'navProfile': 'Profile',
      'bookingAdded': 'Request created for {salon}',
      'bookingCancelled': 'Request cancelled',
      'savedSalonsConnectedHome':
          'Saved workshops are currently linked to Home list',
      'notificationsEnabled': 'Notifications enabled',
      'notificationsDisabled': 'Notifications disabled',
      'languageSwitched': 'Language switched to {language}',
      'findTrustedMasters':
          'Find trusted auto masters and book service in minutes',
      'mapTitle': 'Workshops on map',
      'mapHint': 'Tap a marker to open workshop details',
      'mapNoCoordinates': 'Workshop coordinates are not available yet.',
      'openOnMap': 'Open workshop',
      'mapOpenInYandex': 'Open in Yandex Maps',
      'mapOpenYandexFailed': 'Yandex Maps could not be opened.',
      'mapMyLocation': 'My location',
      'mapLocationDisabled': 'Turn on location service to continue.',
      'mapLocationDenied': 'Location permission was denied.',
      'mapLocationError': 'Current location could not be determined.',
      'searchHint': 'Search workshop, district, or auto service',
      'salonsNearby': '{count} workshops nearby',
      'fastConfirmation': 'Quick approval',
      'verifiedMasters': 'Certified masters',
      'masterPrefix': 'Master: {name}',
      'openNow': 'Open now',
      'closed': 'Closed',
      'closedNow': 'Closed now',
      'fromPrice': 'From {price}',
      'noSalonsFound': 'No workshops found',
      'tryDifferentSearch': 'Try a different search keyword.',
      'services': 'Auto services',
      'durationMinutes': '{minutes} min',
      'book': 'Book service',
      'bookNowFrom': 'Book service from {price}',
      'currentlyClosed': 'Currently closed',
      'bookAppointment': 'Service appointment',
      'service': 'Service type',
      'date': 'Date',
      'availableTimes': 'Available times',
      'summary': 'Request summary',
      'serviceLabel': 'Service type: {service}',
      'durationLabel': 'Duration: {duration}',
      'dateLabel': 'Date: {date}',
      'timeLabel': 'Time: {time}',
      'totalLabel': 'Total: {total}',
      'confirmBooking': 'Confirm request',
      'priceLabel': 'Price: {price}',
      'cancelBooking': 'Cancel request',
      'noBookingsYet': 'No requests yet',
      'bookingsEmptyHint':
          'Open Home, choose a workshop, and create your first request.',
      'statusUpcoming': 'Upcoming',
      'statusCompleted': 'Completed',
      'statusCancelled': 'Cancelled',
      'totalBookings': 'Total requests',
      'upcoming': 'Upcoming',
      'bookingHistory': 'Request history',
      'bookingHistorySubtitle': 'Review your completed and cancelled requests',
      'savedSalons': 'Saved workshops',
      'savedSalonsSubtitle': 'Quick access to your trusted workshops',
      'notifications': 'Notifications',
      'enabled': 'Enabled',
      'disabled': 'Disabled',
      'language': 'Language',
      'profileUnknownName': 'User',
      'profileUnknownPhone': 'Phone not available',
      'refresh': 'Refresh',
      'signOut': 'Sign out',
      'signOutTitle': 'Sign out',
      'signOutConfirm': 'Are you sure you want to sign out?',
      'cancel': 'Cancel',
      'login': 'Login',
      'welcomeBack': 'Welcome back',
      'signInDescription':
          'Sign in to manage your service requests and profile.',
      'phoneNumber': 'Phone number',
      'phoneHint': '+998 90 123 45 67',
      'phoneRequired': 'Phone number is required',
      'phoneInvalid': 'Enter a valid phone number',
      'password': 'Password',
      'passwordRequired': 'Password is required',
      'passwordLength': 'Password must be at least 6 characters',
      'signIn': 'Sign in',
      'loginSuccessful': 'Login successful',
      'loginFailed': 'Login failed. Check phone or password.',
      'bookingCreateFailed': 'Request was not sent. Please try again.',
      'english': 'English',
      'uzbek': 'Uzbek',
      'russian': 'Russian',
    },
    'uz': <String, String>{
      'appTitle': 'Usta Top',
      'navHome': 'Asosiy',
      'navMap': 'Xarita',
      'navBookings': 'Buyurtmalar',
      'navProfile': 'Kabinet',
      'bookingAdded': '{salon} uchun buyurtma qo\'shildi',
      'bookingCancelled': 'Buyurtma bekor qilindi',
      'savedSalonsConnectedHome':
          'Saqlangan servislar bo\'limi hozircha Asosiy ro\'yxatga ulangan',
      'notificationsEnabled': 'Bildirishnomalar yoqildi',
      'notificationsDisabled': 'Bildirishnomalar o\'chirildi',
      'languageSwitched': 'Til {language} ga o\'zgartirildi',
      'findTrustedMasters': 'Ishonchli avto ustalarni toping va tez yoziling',
      'mapTitle': 'Servislar xaritada',
      'mapHint': 'Servis tafsilotini ochish uchun markerga bosing',
      'mapNoCoordinates': 'Servislar uchun koordinatalar hali kiritilmagan.',
      'openOnMap': 'Servisni ochish',
      'mapOpenInYandex': 'Yandex Mapsda ochish',
      'mapOpenYandexFailed': 'Yandex Mapsni ochib bo\'lmadi.',
      'mapMyLocation': 'Mening joylashuvim',
      'mapLocationDisabled':
          'Davom etish uchun qurilma joylashuv xizmatini yoqing.',
      'mapLocationDenied': 'Joylashuv ruxsati berilmadi.',
      'mapLocationError': 'Joriy joylashuvni aniqlab bo\'lmadi.',
      'searchHint': 'Servis markazi, tuman yoki xizmatni qidiring',
      'salonsNearby': 'Yaqin atrofda {count} ta servis',
      'fastConfirmation': 'Tez tasdiq',
      'verifiedMasters': 'Tasdiqlangan ustalar',
      'masterPrefix': 'Usta: {name}',
      'openNow': 'Hozir ochiq',
      'closed': 'Yopiq',
      'closedNow': 'Hozir yopiq',
      'fromPrice': '{price} dan',
      'noSalonsFound': 'Servis topilmadi',
      'tryDifferentSearch': 'Boshqa kalit so\'z bilan urinib ko\'ring.',
      'services': 'Avto xizmatlar',
      'durationMinutes': '{minutes} daqiqa',
      'book': 'Yozilish',
      'bookNowFrom': '{price} dan yozilish',
      'currentlyClosed': 'Hozir yopiq',
      'bookAppointment': 'Servisga yozilish',
      'service': 'Xizmat turi',
      'date': 'Sana',
      'availableTimes': 'Mavjud vaqtlar',
      'summary': 'Buyurtma xulosasi',
      'serviceLabel': 'Xizmat turi: {service}',
      'durationLabel': 'Davomiyligi: {duration}',
      'dateLabel': 'Sana: {date}',
      'timeLabel': 'Vaqt: {time}',
      'totalLabel': 'Jami: {total}',
      'confirmBooking': 'Buyurtmani tasdiqlash',
      'priceLabel': 'Narx: {price}',
      'cancelBooking': 'Buyurtmani bekor qilish',
      'noBookingsYet': 'Hali buyurtmalar yo\'q',
      'bookingsEmptyHint':
          'Asosiy sahifadan servis tanlab birinchi buyurtmangizni yarating.',
      'statusUpcoming': 'Kutilmoqda',
      'statusCompleted': 'Yakunlangan',
      'statusCancelled': 'Bekor qilingan',
      'totalBookings': 'Jami buyurtmalar',
      'upcoming': 'Kutilmoqda',
      'bookingHistory': 'Buyurtmalar tarixi',
      'bookingHistorySubtitle':
          'Yakunlangan va bekor qilingan buyurtmalarni ko\'ring',
      'savedSalons': 'Saqlangan servislar',
      'savedSalonsSubtitle': 'Ishonchli ustaxonalarga tez kirish',
      'notifications': 'Bildirishnomalar',
      'enabled': 'Yoqilgan',
      'disabled': 'O\'chirilgan',
      'language': 'Til',
      'profileUnknownName': 'Foydalanuvchi',
      'profileUnknownPhone': 'Telefon ko\'rsatilmagan',
      'refresh': 'Yangilash',
      'signOut': 'Chiqish',
      'signOutTitle': 'Chiqish',
      'signOutConfirm': 'Rostdan ham akkauntdan chiqmoqchimisiz?',
      'cancel': 'Bekor qilish',
      'login': 'Kirish',
      'welcomeBack': 'Xush kelibsiz',
      'signInDescription':
          'Buyurtmalar va profilingizni boshqarish uchun tizimga kiring.',
      'phoneNumber': 'Telefon raqam',
      'phoneHint': '+998 90 123 45 67',
      'phoneRequired': 'Telefon raqam majburiy',
      'phoneInvalid': 'To\'g\'ri telefon raqam kiriting',
      'password': 'Parol',
      'passwordRequired': 'Parol majburiy',
      'passwordLength': 'Parol kamida 6 ta belgidan iborat bo\'lsin',
      'signIn': 'Kirish',
      'loginSuccessful': 'Muvaffaqiyatli kirildi',
      'loginFailed': 'Kirish amalga oshmadi. Raqam yoki parolni tekshiring.',
      'bookingCreateFailed': 'Buyurtma yuborilmadi. Qayta urinib ko\'ring.',
      'english': 'Inglizcha',
      'uzbek': 'O\'zbekcha',
      'russian': 'Ruscha',
    },
    'ru': <String, String>{
      'appTitle': 'Usta Top',
      'navHome': 'Главная',
      'navMap': 'Карта',
      'navBookings': 'Заявки',
      'navProfile': 'Профиль',
      'bookingAdded': 'Заявка создана для {salon}',
      'bookingCancelled': 'Заявка отменена',
      'savedSalonsConnectedHome':
          'Раздел сохраненных сервисов пока связан со списком на Главной',
      'notificationsEnabled': 'Уведомления включены',
      'notificationsDisabled': 'Уведомления отключены',
      'languageSwitched': 'Язык переключен на {language}',
      'findTrustedMasters':
          'Найдите надежных авто-мастеров и запишитесь за пару минут',
      'mapTitle': 'Сервисы на карте',
      'mapHint': 'Нажмите на маркер, чтобы открыть детали сервиса',
      'mapNoCoordinates': 'Координаты сервисов пока не заполнены.',
      'openOnMap': 'Открыть сервис',
      'mapOpenInYandex': 'Открыть в Yandex Maps',
      'mapOpenYandexFailed': 'Не удалось открыть Yandex Maps.',
      'mapMyLocation': 'Моё местоположение',
      'mapLocationDisabled': 'Включите службу геолокации для продолжения.',
      'mapLocationDenied': 'Доступ к геолокации не предоставлен.',
      'mapLocationError': 'Не удалось определить текущее местоположение.',
      'searchHint': 'Поиск сервиса, района или услуги',
      'salonsNearby': 'Сервисов рядом: {count}',
      'fastConfirmation': 'Быстрое подтверждение',
      'verifiedMasters': 'Проверенные мастера',
      'masterPrefix': 'Мастер: {name}',
      'openNow': 'Открыто',
      'closed': 'Закрыто',
      'closedNow': 'Сейчас закрыто',
      'fromPrice': 'От {price}',
      'noSalonsFound': 'Сервисы не найдены',
      'tryDifferentSearch': 'Попробуйте другой поисковый запрос.',
      'services': 'Автоуслуги',
      'durationMinutes': '{minutes} мин',
      'book': 'Записаться',
      'bookNowFrom': 'Записаться от {price}',
      'currentlyClosed': 'Сейчас закрыто',
      'bookAppointment': 'Запись в сервис',
      'service': 'Тип услуги',
      'date': 'Дата',
      'availableTimes': 'Доступное время',
      'summary': 'Сводка заявки',
      'serviceLabel': 'Тип услуги: {service}',
      'durationLabel': 'Длительность: {duration}',
      'dateLabel': 'Дата: {date}',
      'timeLabel': 'Время: {time}',
      'totalLabel': 'Итого: {total}',
      'confirmBooking': 'Подтвердить заявку',
      'priceLabel': 'Цена: {price}',
      'cancelBooking': 'Отменить заявку',
      'noBookingsYet': 'Заявок пока нет',
      'bookingsEmptyHint':
          'Откройте Главную, выберите сервис и создайте первую заявку.',
      'statusUpcoming': 'Предстоит',
      'statusCompleted': 'Завершено',
      'statusCancelled': 'Отменено',
      'totalBookings': 'Всего заявок',
      'upcoming': 'Предстоит',
      'bookingHistory': 'История заявок',
      'bookingHistorySubtitle': 'Просмотр завершенных и отмененных заявок',
      'savedSalons': 'Сохраненные сервисы',
      'savedSalonsSubtitle': 'Быстрый доступ к вашим сервисам',
      'notifications': 'Уведомления',
      'enabled': 'Включено',
      'disabled': 'Выключено',
      'language': 'Язык',
      'profileUnknownName': 'Пользователь',
      'profileUnknownPhone': 'Телефон не указан',
      'refresh': 'Обновить',
      'signOut': 'Выйти',
      'signOutTitle': 'Выход',
      'signOutConfirm': 'Вы уверены, что хотите выйти?',
      'cancel': 'Отмена',
      'login': 'Вход',
      'welcomeBack': 'С возвращением',
      'signInDescription': 'Войдите, чтобы управлять заявками и профилем.',
      'phoneNumber': 'Номер телефона',
      'phoneHint': '+998 90 123 45 67',
      'phoneRequired': 'Введите номер телефона',
      'phoneInvalid': 'Введите корректный номер телефона',
      'password': 'Пароль',
      'passwordRequired': 'Введите пароль',
      'passwordLength': 'Пароль должен быть не менее 6 символов',
      'signIn': 'Войти',
      'loginSuccessful': 'Вход выполнен',
      'loginFailed': 'Ошибка входа. Проверьте номер или пароль.',
      'bookingCreateFailed': 'Заявка не отправлена. Попробуйте снова.',
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
  String get navMap => _text('navMap');
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
  String get mapTitle => _text('mapTitle');
  String get mapHint => _text('mapHint');
  String get mapNoCoordinates => _text('mapNoCoordinates');
  String get openOnMap => _text('openOnMap');
  String get mapOpenInYandex => _text('mapOpenInYandex');
  String get mapOpenYandexFailed => _text('mapOpenYandexFailed');
  String get mapMyLocation => _text('mapMyLocation');
  String get mapLocationDisabled => _text('mapLocationDisabled');
  String get mapLocationDenied => _text('mapLocationDenied');
  String get mapLocationError => _text('mapLocationError');
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
  String get profileUnknownName => _text('profileUnknownName');
  String get profileUnknownPhone => _text('profileUnknownPhone');
  String get refresh => _text('refresh');
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
  String get loginFailed => _text('loginFailed');
  String get bookingCreateFailed => _text('bookingCreateFailed');

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
