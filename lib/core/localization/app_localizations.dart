import 'package:flutter/material.dart';

import 'app_language.dart';
import '../theme/app_theme_preference.dart';

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
      'bookingAcceptedNotice': 'Your booking at {workshop} was accepted',
      'bookingCompletedNotice':
          'Your booking at {workshop} was marked completed',
      'bookingCancelledNotice':
          'Your booking at {workshop} was cancelled: {reason}',
      'bookingRescheduledNotice':
          'Your booking at {workshop} was moved to {time}',
      'telegramCancellationNotice':
          'Your request at {workshop} was cancelled in Telegram: {reason}',
      'savedSalonsConnectedHome':
          'Saved workshops are currently linked to Home list',
      'savedWorkshopsTitle': 'Saved workshops',
      'savedWorkshopsEmptyTitle': 'No saved workshops yet',
      'savedWorkshopsEmptyHint':
          'Tap the heart on a workshop card to save it here.',
      'saveWorkshop': 'Save workshop',
      'removeSavedWorkshop': 'Remove from saved',
      'savedWorkshopAdded': '{workshop} was added to saved',
      'savedWorkshopRemoved': '{workshop} was removed from saved',
      'savedWorkshopUpdateFailed': 'Saved workshops could not be updated',
      'notificationsEnabled': 'Notifications enabled',
      'notificationsDisabled': 'Notifications disabled',
      'languageSwitched': 'Language switched to {language}',
      'findTrustedMasters':
          'Find trusted auto masters and book service in minutes',
      'mapTitle': 'Workshops on map',
      'mapHint': 'Tap a marker to open workshop details',
      'mapNoCoordinates': 'Workshop coordinates are not available yet.',
      'mapNoMatches': 'No workshops match this filter.',
      'openOnMap': 'Open workshop',
      'routeToWorkshop': 'Route',
      'mapFilterAll': 'All',
      'mapFilterTopRated': 'Top rated',
      'mapFilterNearby': 'Nearby',
      'mapSelectedWorkshop': 'Selected workshop',
      'mapBrowseList': 'Browse workshops',
      'chooseNavigatorTitle': 'Choose navigator',
      'chooseNavigatorSubtitle': 'Open route to {workshop}',
      'navigatorGoogleMaps': 'Google Maps',
      'navigatorYandexNavigator': 'Yandex Navigator',
      'navigatorYandexMaps': 'Yandex Maps',
      'navigatorAppleMaps': 'Apple Maps',
      'navigatorWaze': 'Waze',
      'navigatorBrowserMaps': 'Browser maps',
      'navigatorNoApps': 'No navigator apps found.',
      'navigatorOpenFailed': 'Navigator app could not be opened.',
      'mapOpenInYandex': 'Open in Yandex Maps',
      'mapOpenYandexFailed': 'Yandex Maps could not be opened.',
      'mapZoomIn': 'Zoom in',
      'mapZoomOut': 'Zoom out',
      'mapMyLocation': 'My location',
      'mapLocationDisabled': 'Turn on location service to continue.',
      'mapLocationDenied': 'Location permission was denied.',
      'mapLocationError': 'Current location could not be determined.',
      'searchHint': 'Search workshop, district, or auto service',
      'salonsNearby': '{count} workshops nearby',
      'workshopsMetricLabel': 'Workshops',
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
      'availableTimesLoadFailed': 'Available times could not be loaded.',
      'availableCalendarLoadFailed':
          'Calendar availability could not be loaded.',
      'availableTimesRetryHint':
          'Please try another date or refresh the screen.',
      'availableTimesClosedDay': 'Workshop is closed on this day',
      'availableTimesClosedDayHint':
          'Choose another day to see free appointment times.',
      'availableTimesEmpty': 'No free times left for this day',
      'availableTimesEmptyHint':
          'Try another date or choose a different service.',
      'nearestAvailableTitle': 'Closest free time',
      'nearestAvailableSubtitle': '{date} at {time} is the nearest open slot.',
      'selectNearestAvailable': 'Use this slot',
      'noAvailableDates': 'No available dates were found in the next 45 days.',
      'summary': 'Request summary',
      'serviceLabel': 'Service type: {service}',
      'vehicleSelectionTitle': 'Vehicle selection',
      'savedVehiclesTitle': 'Saved vehicles',
      'uzbekistanGmVehiclesTitle': 'GM Uzbekistan models',
      'otherPopularVehiclesTitle': 'Other common cars',
      'popularVehiclesTitle': 'Popular models',
      'vehicleCatalogMode': 'Choose from list',
      'vehicleOtherOption': 'Other',
      'vehicleBrandField': 'Car brand',
      'vehicleBrandHint': 'For example, Chevrolet',
      'vehicleBrandRequired': 'Enter the car brand',
      'vehicleCatalogModelField': 'Model from list',
      'vehicleCatalogRequired': 'Choose a model from the list',
      'vehicleModelField': 'Car model',
      'vehicleModelHint': 'For example, Chevrolet Cobalt',
      'vehicleModelRequired': 'Enter the car model',
      'vehicleModelPending': 'Not entered yet',
      'vehicleModelLabel': 'Car: {vehicle}',
      'vehicleTypeField': 'Vehicle type',
      'vehicleTypeLabel': 'Vehicle type: {type}',
      'durationLabel': 'Duration: {duration}',
      'dateLabel': 'Date: {date}',
      'timeLabel': 'Time: {time}',
      'bookingTimePending': 'Choose a free time',
      'basePriceLabel': 'Base price: {price}',
      'prepaymentSummaryLabel': 'Prepayment ({percent}%): {price}',
      'remainingPaymentLabel': 'Remaining at workshop: {price}',
      'paymentMethodLabel': 'Payment method',
      'paymentMethodHint':
          'This payment step is currently in demo mode. Choose cash or a test card.',
      'paymentMethodCash': 'Cash',
      'paymentMethodTestCard': 'Test card',
      'paymentMethodClick': 'Click',
      'paymentMethodPayme': 'Payme',
      'paymentMethodUzum': 'Uzum Bank',
      'paymentMethodBankCard': 'Bank card',
      'vehiclePriceRuleLabel': 'Configured vehicle price: {vehicle}',
      'vehiclePriceLoadFailed': 'Vehicle-specific price could not be loaded.',
      'vehiclePriceAdjustmentLabel': 'Vehicle adjustment: {adjustment}',
      'totalLabel': 'Total: {total}',
      'confirmBooking': 'Confirm request',
      'payDepositAndBook': 'Pay deposit and book',
      'bookWithCash': 'Book with cash',
      'payWithTestCardAndBook': 'Open test payment',
      'testPaymentTitle': 'Test payment window',
      'testPaymentSubtitle':
          'A real payment contract is not connected yet. This screen only simulates a successful card payment.',
      'testPaymentAmountLabel': 'Amount for confirmation: {price}',
      'testPaymentHint':
          'No real money is charged. Press the button below to continue in test mode.',
      'testPaymentConfirm': 'Confirm test payment',
      'bookingTimeRequired': 'Choose one of the available times',
      'chatWithWorkshop': 'Chat with workshop',
      'chatOpen': 'Chat',
      'chatInputHint': 'Write a message about this booking',
      'chatSend': 'Send',
      'chatSendFailed': 'Message could not be sent',
      'chatEmptyTitle': 'No messages yet',
      'chatEmptySubtitle':
          'The conversation is attached to this booking. You can start it here.',
      'chatReplyHint':
          'Write only about this booking so the technician can respond faster.',
      'chatSenderYou': 'You',
      'chatSenderWorkshop': 'Workshop',
      'chatNewReplyNotice': '{workshop} sent you a new message',
      'chatUnreadCount': '{count} unread',
      'writeReview': 'Write review',
      'sendReview': 'Send review',
      'reviewsTitle': 'Customer reviews',
      'reviewsCount': '{count} reviews',
      'allServicesLabel': 'All services',
      'reviewAnalyticsTitle': 'Review snapshot',
      'reviewAnalyticsSubtitle':
          'See the rating mix and which services get mentioned most.',
      'reviewAverageLabel': 'Average rating',
      'reviewTopServicesTitle': 'Most reviewed services',
      'reviewTopServicesEmpty': 'Service review stats will appear here.',
      'reviewStarsLabel': '{stars} stars',
      'reviewsEmptyTitle': 'No reviews yet',
      'reviewsEmptySubtitle':
          'Be the first to leave a review about a service in this workshop.',
      'reviewSheetSubtitle':
          'Choose the service, rate it, and write a short honest review.',
      'serviceSelectLabel': 'Service',
      'ratingLabel': 'Rating: {rating}/5',
      'commentLabel': 'Comment',
      'reviewHint': 'Describe what you liked or what should improve',
      'reviewCommentValidation': 'Review must be at least 3 characters long',
      'reviewSubmitFailed': 'Review could not be sent',
      'reviewSubmitSuccess': 'Your review was published',
      'completedReviewTitle': 'Service completed',
      'completedReviewSubtitle':
          'Your {service} at {workshop} is done. Leave a short review for the technician.',
      'reviewReminderTitle': 'How was the service?',
      'reviewReminderSubtitle':
          'You have not rated {service} at {workshop} yet. Leave a quick review for the technician.',
      'reviewSubmittedLabel': 'Review sent',
      'workshopReplyLabel': 'Workshop reply',
      'priceLabel': 'Price: {price}',
      'prepaymentAmountLabel': 'Prepayment amount: {price}',
      'prepaymentPaidLabel': 'Prepayment paid: {price}',
      'paymentStatusLabel': 'Payment status: {status}',
      'paymentMethodValueLabel': 'Payment method: {method}',
      'paymentStatusPending': 'Pending',
      'paymentStatusPaid': 'Paid',
      'paymentStatusRefunded': 'Refunded',
      'paymentStatusNotRequired': 'Not required',
      'cancelBooking': 'Cancel request',
      'rescheduleBooking': 'Reschedule request',
      'rescheduleBookingTitle': 'Move appointment',
      'rescheduleBookingSubtitle':
          'Choose a new date and time for {service} at {workshop}.',
      'rescheduleCurrentTimeLabel': 'Current time: {time}',
      'rescheduleConfirm': 'Save new time',
      'acceptRescheduledBooking': 'Accept new time',
      'acceptRescheduledSuccess': 'The new booking time was accepted',
      'acceptRescheduledFailed': 'The new booking time could not be accepted',
      'bookingRescheduled': 'Request moved to a new time',
      'rescheduledByLabel': 'Moved by: {actor}',
      'rescheduledAtLabel': 'Moved at: {time}',
      'acceptedAtLabel': 'Accepted at: {time}',
      'completedAtLabel': 'Completed at: {time}',
      'cancelledByLabel': 'Cancelled by: {actor}',
      'cancelledAtLabel': 'Cancelled at: {time}',
      'rescheduledFromLabel': 'Previous time: {time}',
      'cancellationReasonLabel': 'Reason: {reason}',
      'cancellationUnknown': 'Not specified',
      'cancellationReasonWorkshopBusy': 'Schedule is full',
      'cancellationReasonMasterUnavailable': 'Technician unavailable',
      'cancellationReasonWorkshopClosed': 'Workshop closed',
      'cancellationReasonMissingParts': 'Parts unavailable',
      'cancellationReasonCustomerRequest': 'Customer request',
      'cancellationActorCustomer': 'Customer',
      'cancellationActorAdmin': 'Admin',
      'cancellationActorOwnerPanel': 'Workshop owner',
      'cancellationActorOwnerTelegram': 'Owner via Telegram',
      'noBookingsYet': 'No requests yet',
      'bookingsEmptyHint':
          'Open Home, choose a workshop, and create your first request.',
      'statusUpcoming': 'Upcoming',
      'statusRescheduled': 'Rescheduled',
      'statusAccepted': 'Accepted',
      'statusCompleted': 'Completed',
      'statusCancelled': 'Cancelled',
      'totalBookings': 'Total requests',
      'upcoming': 'Upcoming',
      'completedMetricLabel': 'Finished',
      'bookingHistory': 'Request history',
      'bookingHistorySubtitle': 'Review your completed and cancelled requests',
      'savedSalons': 'Saved workshops',
      'savedSalonsSubtitle': 'Quick access to your trusted workshops',
      'notifications': 'Notifications',
      'testPushNotification': 'Send test push',
      'pushReady': 'Push is ready',
      'pushNotReady': 'Push is not ready yet',
      'testPushSent': 'Test push was sent',
      'testPushFailed': 'Test push could not be sent',
      'enabled': 'Enabled',
      'disabled': 'Disabled',
      'language': 'Language',
      'theme': 'Theme',
      'systemTheme': 'System',
      'lightTheme': 'Light',
      'darkTheme': 'Dark',
      'themeChanged': 'Theme switched to {theme}',
      'profileUnknownName': 'User',
      'profileUnknownPhone': 'Phone not available',
      'editProfile': 'Edit profile',
      'editProfileName': 'Edit name',
      'profileNameField': 'Full name',
      'profileNameHint': 'Enter your full name',
      'profileNameRequired': 'Full name is required',
      'profileNameTooShort': 'Full name must be at least 2 characters',
      'profileUpdated': 'Profile updated successfully',
      'profileUpdateFailed': 'Profile could not be updated',
      'profileNameUpdated': 'Name updated successfully',
      'profileNameUpdateFailed': 'Name could not be updated',
      'changePassword': 'Change password',
      'currentPassword': 'Current password',
      'newPassword': 'New password',
      'confirmPassword': 'Confirm password',
      'confirmPasswordRequired': 'Please confirm the new password',
      'passwordsDoNotMatch': 'Passwords do not match',
      'passwordUpdated': 'Password updated successfully',
      'passwordUpdateFailed': 'Password could not be updated',
      'saveChanges': 'Save changes',
      'refresh': 'Refresh',
      'view': 'View',
      'signOut': 'Sign out',
      'signOutTitle': 'Sign out',
      'signOutConfirm': 'Are you sure you want to sign out?',
      'cancel': 'Cancel',
      'login': 'Login',
      'welcomeBack': 'Welcome back',
      'signInDescription':
          'Sign in to manage your service requests and profile.',
      'fullName': 'Full name',
      'signUp': 'Sign up',
      'signUpDescription': 'Create a new account with your phone number.',
      'noAccountYet': 'Do not have an account yet?',
      'createAccount': 'Create account',
      'forgotPassword': 'Forgot password?',
      'forgotPasswordDescription':
          'Enter your phone number and set a new password.',
      'resetPassword': 'Reset password',
      'passwordResetSuccess':
          'Password updated. You can now sign in with the new password.',
      'passwordResetFailed': 'Password could not be reset',
      'signUpFailed': 'Account could not be created',
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
      'bookingAcceptedNotice': '{workshop} buyurtmangiz qabul qilindi',
      'bookingCompletedNotice':
          '{workshop} buyurtmangiz yakunlangan deb belgilandi',
      'bookingCancelledNotice':
          '{workshop} buyurtmangiz bekor qilindi: {reason}',
      'bookingRescheduledNotice':
          '{workshop}dagi broningiz {time} ga ko‘chirildi',
      'telegramCancellationNotice':
          '{workshop} buyurtmangiz Telegram orqali bekor qilindi: {reason}',
      'savedSalonsConnectedHome':
          'Saqlangan servislar bo\'limi hozircha Asosiy ro\'yxatga ulangan',
      'savedWorkshopsTitle': 'Saqlangan servislar',
      'savedWorkshopsEmptyTitle': 'Hali saqlangan servis yo\'q',
      'savedWorkshopsEmptyHint':
          'Servis kartasidagi yurakcha tugmasi orqali bu ro\'yxatni to\'ldiring.',
      'saveWorkshop': 'Servisni saqlash',
      'removeSavedWorkshop': 'Saqlangandan olib tashlash',
      'savedWorkshopAdded': '{workshop} saqlandi',
      'savedWorkshopRemoved': '{workshop} saqlangandan olib tashlandi',
      'savedWorkshopUpdateFailed': 'Saqlangan servislarni yangilab bo\'lmadi',
      'notificationsEnabled': 'Bildirishnomalar yoqildi',
      'notificationsDisabled': 'Bildirishnomalar o\'chirildi',
      'languageSwitched': 'Til {language} ga o\'zgartirildi',
      'findTrustedMasters': 'Ishonchli avto ustalarni toping va tez yoziling',
      'mapTitle': 'Servislar xaritada',
      'mapHint': 'Servis tafsilotini ochish uchun markerga bosing',
      'mapNoCoordinates': 'Servislar uchun koordinatalar hali kiritilmagan.',
      'mapNoMatches': 'Bu filter bo‘yicha ustaxona topilmadi.',
      'openOnMap': 'Servisni ochish',
      'routeToWorkshop': 'Marshrut',
      'mapFilterAll': 'Barchasi',
      'mapFilterTopRated': 'Yuqori baho',
      'mapFilterNearby': 'Yaqin',
      'mapSelectedWorkshop': 'Tanlangan ustaxona',
      'mapBrowseList': 'Xaritadagi ustaxonalar',
      'chooseNavigatorTitle': 'Navigatorni tanlang',
      'chooseNavigatorSubtitle': '{workshop} ga yo\'l ochish',
      'navigatorGoogleMaps': 'Google Maps',
      'navigatorYandexNavigator': 'Yandex Navigator',
      'navigatorYandexMaps': 'Yandex Maps',
      'navigatorAppleMaps': 'Apple Maps',
      'navigatorWaze': 'Waze',
      'navigatorBrowserMaps': 'Brauzer xaritasi',
      'navigatorNoApps': 'Hech qanday navigator topilmadi.',
      'navigatorOpenFailed': 'Navigator ilovasini ochib bo\'lmadi.',
      'mapOpenInYandex': 'Yandex Mapsda ochish',
      'mapOpenYandexFailed': 'Yandex Mapsni ochib bo\'lmadi.',
      'mapZoomIn': 'Yaqinlashtirish',
      'mapZoomOut': 'Uzoqlashtirish',
      'mapMyLocation': 'Mening joylashuvim',
      'mapLocationDisabled':
          'Davom etish uchun qurilma joylashuv xizmatini yoqing.',
      'mapLocationDenied': 'Joylashuv ruxsati berilmadi.',
      'mapLocationError': 'Joriy joylashuvni aniqlab bo\'lmadi.',
      'searchHint': 'Servis markazi, tuman yoki xizmatni qidiring',
      'salonsNearby': 'Yaqin atrofda {count} ta servis',
      'workshopsMetricLabel': 'Ustaxonalar',
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
      'availableTimesLoadFailed': 'Bo‘sh vaqtlarni yuklab bo‘lmadi.',
      'availableCalendarLoadFailed':
          'Kalendar bo‘sh vaqtlarini yuklab bo‘lmadi.',
      'availableTimesRetryHint':
          'Boshqa sana tanlang yoki ekranni qayta urinib ko‘ring.',
      'availableTimesClosedDay': 'Bu kunda ustaxona ishlamaydi',
      'availableTimesClosedDayHint':
          'Bo‘sh vaqtlarni ko‘rish uchun boshqa kunni tanlang.',
      'availableTimesEmpty': 'Bu kun uchun bo‘sh vaqt qolmagan',
      'availableTimesEmptyHint':
          'Boshqa sana yoki boshqa xizmatni tanlab ko‘ring.',
      'nearestAvailableTitle': 'Eng yaqin bo‘sh vaqt',
      'nearestAvailableSubtitle':
          '{date} kuni {time} siz uchun eng yaqin bo‘sh slot.',
      'selectNearestAvailable': 'Shu vaqtni tanlash',
      'noAvailableDates': 'Keyingi 45 kun ichida bo‘sh sana topilmadi.',
      'summary': 'Buyurtma xulosasi',
      'serviceLabel': 'Xizmat turi: {service}',
      'vehicleSelectionTitle': 'Mashina tanlash',
      'savedVehiclesTitle': 'Saqlangan mashinalar',
      'uzbekistanGmVehiclesTitle': 'GM Uzbekistan modellari',
      'otherPopularVehiclesTitle': 'Boshqa ko\'p uchraydigan mashinalar',
      'popularVehiclesTitle': 'Ko\'p ishlatiladigan modellar',
      'vehicleCatalogMode': 'Ro\'yxatdan tanlash',
      'vehicleOtherOption': 'Boshqa',
      'vehicleBrandField': 'Mashina brendi',
      'vehicleBrandHint': 'Masalan, Chevrolet',
      'vehicleBrandRequired': 'Mashina brendini kiriting',
      'vehicleCatalogModelField': 'Ro\'yxatdagi model',
      'vehicleCatalogRequired': 'Ro\'yxatdan model tanlang',
      'vehicleModelField': 'Mashina modeli',
      'vehicleModelHint': 'Masalan, Chevrolet Cobalt',
      'vehicleModelRequired': 'Mashina modelini kiriting',
      'vehicleModelPending': 'Hali kiritilmagan',
      'vehicleModelLabel': 'Mashina: {vehicle}',
      'vehicleTypeField': 'Mashina turi',
      'vehicleTypeLabel': 'Mashina turi: {type}',
      'durationLabel': 'Davomiyligi: {duration}',
      'dateLabel': 'Sana: {date}',
      'timeLabel': 'Vaqt: {time}',
      'bookingTimePending': 'Bo‘sh vaqtni tanlang',
      'basePriceLabel': 'Bazaviy narx: {price}',
      'prepaymentSummaryLabel': 'Avans ({percent}%): {price}',
      'remainingPaymentLabel': 'Qolgani ustaxonada: {price}',
      'paymentMethodLabel': 'To‘lov usuli',
      'paymentMethodHint':
          'Hozircha bu test rejimdagi to‘lov bosqichi. Naqd yoki test kartani tanlang.',
      'paymentMethodCash': 'Naqd',
      'paymentMethodTestCard': 'Test karta',
      'paymentMethodClick': 'Click',
      'paymentMethodPayme': 'Payme',
      'paymentMethodUzum': 'Uzum Bank',
      'paymentMethodBankCard': 'Bank karta',
      'vehiclePriceRuleLabel': 'Belgilangan model narxi: {vehicle}',
      'vehiclePriceLoadFailed':
          'Mashina modeli bo‘yicha narxni yuklab bo‘lmadi.',
      'vehiclePriceAdjustmentLabel':
          'Mashina turi bo\'yicha o\'zgarish: {adjustment}',
      'totalLabel': 'Jami: {total}',
      'confirmBooking': 'Buyurtmani tasdiqlash',
      'payDepositAndBook': 'Avans to‘lab bron qilish',
      'bookWithCash': 'Naqd bilan bron qilish',
      'payWithTestCardAndBook': 'Test to‘lov oynasini ochish',
      'testPaymentTitle': 'Test to‘lov oynasi',
      'testPaymentSubtitle':
          'Haqiqiy to‘lov shartnomasi hali ulanmagan. Bu ekran karta to‘lovini faqat test tarzida tasdiqlaydi.',
      'testPaymentAmountLabel': 'Tasdiqlanadigan summa: {price}',
      'testPaymentHint':
          'Bu yerda haqiqiy pul yechilmaydi. Pastdagi tugma orqali test rejimda davom eting.',
      'testPaymentConfirm': 'Test to‘lovni tasdiqlash',
      'bookingTimeRequired': 'Mavjud vaqtlarning birini tanlang',
      'chatWithWorkshop': 'Usta bilan chat',
      'chatOpen': 'Chat',
      'chatInputHint': 'Shu zakaz bo\'yicha xabar yozing',
      'chatSend': 'Yuborish',
      'chatSendFailed': 'Xabar yuborilmadi',
      'chatEmptyTitle': 'Hali xabarlar yo\'q',
      'chatEmptySubtitle':
          'Suhbat aynan shu zakazga biriktirilgan. Uni shu yerdan boshlashingiz mumkin.',
      'chatReplyHint':
          'Faqat shu zakaz bo\'yicha yozing, shunda usta tezroq javob beradi.',
      'chatSenderYou': 'Siz',
      'chatSenderWorkshop': 'Usta',
      'chatNewReplyNotice': '{workshop} sizga yangi xabar yozdi',
      'chatUnreadCount': '{count} ta o\'qilmagan',
      'writeReview': 'Sharh yozish',
      'sendReview': 'Sharh yuborish',
      'reviewsTitle': 'Mijozlar fikri',
      'reviewsCount': '{count} ta sharh',
      'allServicesLabel': 'Barcha xizmatlar',
      'reviewAnalyticsTitle': 'Sharh statistikasi',
      'reviewAnalyticsSubtitle':
          'Baholar taqsimoti va eng ko‘p tilga olinayotgan xizmatlarni ko‘ring.',
      'reviewAverageLabel': 'O‘rtacha baho',
      'reviewTopServicesTitle': 'Eng ko‘p sharhlangan xizmatlar',
      'reviewTopServicesEmpty':
          'Xizmatlar bo‘yicha statistika shu yerda chiqadi.',
      'reviewStarsLabel': '{stars} yulduz',
      'reviewsEmptyTitle': 'Hali sharhlar yo\'q',
      'reviewsEmptySubtitle':
          'Bu servis bo\'yicha birinchi bo\'lib fikr qoldiring.',
      'reviewSheetSubtitle':
          'Xizmatni tanlang, baho bering va qisqa halol fikr yozing.',
      'serviceSelectLabel': 'Xizmat',
      'ratingLabel': 'Baho: {rating}/5',
      'commentLabel': 'Sharh',
      'reviewHint': 'Nima yoqqani yoki nimani yaxshilash kerakligini yozing',
      'reviewCommentValidation': 'Sharh kamida 3 ta belgidan iborat bo\'lsin',
      'reviewSubmitFailed': 'Sharh yuborilmadi',
      'reviewSubmitSuccess': 'Sharhingiz joylandi',
      'completedReviewTitle': 'Servis yakunlandi',
      'completedReviewSubtitle':
          '{workshop} dagi {service} xizmati bajarildi. Usta ishi haqida qisqa sharh qoldiring.',
      'reviewReminderTitle': 'Servis qanday o‘tdi?',
      'reviewReminderSubtitle':
          '{workshop} dagi {service} xizmati uchun hali baho qoldirmadingiz. Usta uchun qisqa sharh yozing.',
      'reviewSubmittedLabel': 'Sharhingiz yuborilgan',
      'workshopReplyLabel': 'Servis javobi',
      'priceLabel': 'Narx: {price}',
      'prepaymentAmountLabel': 'Avans summasi: {price}',
      'prepaymentPaidLabel': 'To‘langan avans: {price}',
      'paymentStatusLabel': 'To‘lov holati: {status}',
      'paymentMethodValueLabel': 'To‘lov usuli: {method}',
      'paymentStatusPending': 'Kutilmoqda',
      'paymentStatusPaid': 'To‘langan',
      'paymentStatusRefunded': 'Qaytarilgan',
      'paymentStatusNotRequired': 'Talab qilinmaydi',
      'cancelBooking': 'Buyurtmani bekor qilish',
      'rescheduleBooking': 'Buyurtmani ko‘chirish',
      'rescheduleBookingTitle': 'Bron vaqtini o‘zgartirish',
      'rescheduleBookingSubtitle':
          '{workshop} dagi {service} uchun yangi sana va vaqtni tanlang.',
      'rescheduleCurrentTimeLabel': 'Joriy vaqt: {time}',
      'rescheduleConfirm': 'Yangi vaqtni saqlash',
      'acceptRescheduledBooking': 'Yangi vaqtni qabul qilish',
      'acceptRescheduledSuccess': 'Ko‘chirilgan vaqt qabul qilindi',
      'acceptRescheduledFailed': 'Ko‘chirilgan vaqtni qabul qilib bo‘lmadi',
      'bookingRescheduled': 'Buyurtma yangi vaqtga ko‘chirildi',
      'rescheduledByLabel': 'Ko‘chirdi: {actor}',
      'rescheduledAtLabel': 'Ko‘chirilgan vaqt: {time}',
      'acceptedAtLabel': 'Qabul qilingan vaqt: {time}',
      'completedAtLabel': 'Yakunlangan vaqt: {time}',
      'cancelledByLabel': 'Bekor qildi: {actor}',
      'cancelledAtLabel': 'Bekor qilingan vaqt: {time}',
      'rescheduledFromLabel': 'Oldingi vaqt: {time}',
      'cancellationReasonLabel': 'Sabab: {reason}',
      'cancellationUnknown': 'Ko\'rsatilmagan',
      'cancellationReasonWorkshopBusy': 'Jadval band',
      'cancellationReasonMasterUnavailable': 'Usta mavjud emas',
      'cancellationReasonWorkshopClosed': 'Ustaxona yopiq',
      'cancellationReasonMissingParts': 'Ehtiyot qism yo\'q',
      'cancellationReasonCustomerRequest': 'Mijoz so\'rovi',
      'cancellationActorCustomer': 'Mijoz',
      'cancellationActorAdmin': 'Admin',
      'cancellationActorOwnerPanel': 'Ustaxona egasi',
      'cancellationActorOwnerTelegram': 'Telegram orqali usta',
      'noBookingsYet': 'Hali buyurtmalar yo\'q',
      'bookingsEmptyHint':
          'Asosiy sahifadan servis tanlab birinchi buyurtmangizni yarating.',
      'statusUpcoming': 'Kutilmoqda',
      'statusRescheduled': 'Ko‘chirildi',
      'statusAccepted': 'Qabul qilindi',
      'statusCompleted': 'Yakunlangan',
      'statusCancelled': 'Bekor qilingan',
      'totalBookings': 'Jami buyurtmalar',
      'upcoming': 'Kutilmoqda',
      'completedMetricLabel': 'Bajarilganlar',
      'bookingHistory': 'Buyurtmalar tarixi',
      'bookingHistorySubtitle':
          'Yakunlangan va bekor qilingan buyurtmalarni ko\'ring',
      'savedSalons': 'Saqlangan servislar',
      'savedSalonsSubtitle': 'Ishonchli ustaxonalarga tez kirish',
      'notifications': 'Bildirishnomalar',
      'testPushNotification': 'Test push yuborish',
      'pushReady': 'Push tayyor',
      'pushNotReady': 'Push hali tayyor emas',
      'testPushSent': 'Test push yuborildi',
      'testPushFailed': 'Test push yuborilmadi',
      'enabled': 'Yoqilgan',
      'disabled': 'O\'chirilgan',
      'language': 'Til',
      'theme': 'Mavzu',
      'systemTheme': 'Qurilma bo\'yicha',
      'lightTheme': 'Yorug\' rejim',
      'darkTheme': 'Tungi rejim',
      'themeChanged': 'Mavzu {theme} ga o\'zgartirildi',
      'profileUnknownName': 'Foydalanuvchi',
      'profileUnknownPhone': 'Telefon ko\'rsatilmagan',
      'editProfile': 'Profilni tahrirlash',
      'editProfileName': 'Ismni o\'zgartirish',
      'profileNameField': 'To\'liq ism',
      'profileNameHint': 'To\'liq ismingizni kiriting',
      'profileNameRequired': 'Ism majburiy',
      'profileNameTooShort': 'Ism kamida 2 ta belgidan iborat bo\'lsin',
      'profileUpdated': 'Profil muvaffaqiyatli yangilandi',
      'profileUpdateFailed': 'Profilni yangilab bo\'lmadi',
      'profileNameUpdated': 'Ism muvaffaqiyatli yangilandi',
      'profileNameUpdateFailed': 'Ismni yangilab bo\'lmadi',
      'changePassword': 'Parolni o\'zgartirish',
      'currentPassword': 'Joriy parol',
      'newPassword': 'Yangi parol',
      'confirmPassword': 'Yangi parolni tasdiqlang',
      'confirmPasswordRequired': 'Yangi parolni tasdiqlang',
      'passwordsDoNotMatch': 'Parollar mos kelmadi',
      'passwordUpdated': 'Parol muvaffaqiyatli yangilandi',
      'passwordUpdateFailed': 'Parolni yangilab bo\'lmadi',
      'saveChanges': 'Saqlash',
      'refresh': 'Yangilash',
      'view': 'Ko\'rish',
      'signOut': 'Chiqish',
      'signOutTitle': 'Chiqish',
      'signOutConfirm': 'Rostdan ham akkauntdan chiqmoqchimisiz?',
      'cancel': 'Bekor qilish',
      'login': 'Kirish',
      'welcomeBack': 'Xush kelibsiz',
      'signInDescription':
          'Buyurtmalar va profilingizni boshqarish uchun tizimga kiring.',
      'fullName': 'To\'liq ism',
      'signUp': 'Ro\'yxatdan o\'tish',
      'signUpDescription': 'Telefon raqamingiz orqali yangi akkaunt yarating.',
      'noAccountYet': 'Akkauntingiz yo\'qmi?',
      'createAccount': 'Akkaunt yaratish',
      'forgotPassword': 'Parolni unutdingizmi?',
      'forgotPasswordDescription':
          'Telefon raqamingizni kiriting va yangi parol o\'rnating.',
      'resetPassword': 'Parolni tiklash',
      'passwordResetSuccess':
          'Parol yangilandi. Endi yangi parol bilan kirishingiz mumkin.',
      'passwordResetFailed': 'Parolni tiklab bo\'lmadi',
      'signUpFailed': 'Ro\'yxatdan o\'tib bo\'lmadi',
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
      'bookingAcceptedNotice': 'Ваша бронь в {workshop} принята',
      'bookingCompletedNotice':
          'Ваша бронь в {workshop} отмечена как завершенная',
      'bookingCancelledNotice': 'Ваша бронь в {workshop} отменена: {reason}',
      'bookingRescheduledNotice':
          'Ваша бронь в {workshop} перенесена на {time}',
      'telegramCancellationNotice':
          'Заявка в {workshop} была отменена через Telegram: {reason}',
      'savedSalonsConnectedHome':
          'Раздел сохраненных сервисов пока связан со списком на Главной',
      'savedWorkshopsTitle': 'Сохраненные сервисы',
      'savedWorkshopsEmptyTitle': 'Пока нет сохраненных сервисов',
      'savedWorkshopsEmptyHint':
          'Нажмите на сердечко в карточке сервиса, чтобы сохранить его здесь.',
      'saveWorkshop': 'Сохранить сервис',
      'removeSavedWorkshop': 'Убрать из сохраненных',
      'savedWorkshopAdded': '{workshop} добавлен в сохраненные',
      'savedWorkshopRemoved': '{workshop} удален из сохраненных',
      'savedWorkshopUpdateFailed': 'Не удалось обновить сохраненные сервисы',
      'notificationsEnabled': 'Уведомления включены',
      'notificationsDisabled': 'Уведомления отключены',
      'languageSwitched': 'Язык переключен на {language}',
      'findTrustedMasters':
          'Найдите надежных авто-мастеров и запишитесь за пару минут',
      'mapTitle': 'Сервисы на карте',
      'mapHint': 'Нажмите на маркер, чтобы открыть детали сервиса',
      'mapNoCoordinates': 'Координаты сервисов пока не заполнены.',
      'mapNoMatches': 'По этому фильтру сервисы не найдены.',
      'openOnMap': 'Открыть сервис',
      'routeToWorkshop': 'Маршрут',
      'mapFilterAll': 'Все',
      'mapFilterTopRated': 'Высокий рейтинг',
      'mapFilterNearby': 'Рядом',
      'mapSelectedWorkshop': 'Выбранный автосервис',
      'mapBrowseList': 'Автосервисы на карте',
      'chooseNavigatorTitle': 'Выберите навигатор',
      'chooseNavigatorSubtitle': 'Построить маршрут до {workshop}',
      'navigatorGoogleMaps': 'Google Maps',
      'navigatorYandexNavigator': 'Yandex Navigator',
      'navigatorYandexMaps': 'Yandex Maps',
      'navigatorAppleMaps': 'Apple Maps',
      'navigatorWaze': 'Waze',
      'navigatorBrowserMaps': 'Браузерная карта',
      'navigatorNoApps': 'Навигаторы не найдены.',
      'navigatorOpenFailed': 'Не удалось открыть навигатор.',
      'mapOpenInYandex': 'Открыть в Yandex Maps',
      'mapOpenYandexFailed': 'Не удалось открыть Yandex Maps.',
      'mapZoomIn': 'Приблизить',
      'mapZoomOut': 'Отдалить',
      'mapMyLocation': 'Моё местоположение',
      'mapLocationDisabled': 'Включите службу геолокации для продолжения.',
      'mapLocationDenied': 'Доступ к геолокации не предоставлен.',
      'mapLocationError': 'Не удалось определить текущее местоположение.',
      'searchHint': 'Поиск сервиса, района или услуги',
      'salonsNearby': 'Сервисов рядом: {count}',
      'workshopsMetricLabel': 'Автосервисы',
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
      'availableTimesLoadFailed': 'Не удалось загрузить свободное время.',
      'availableCalendarLoadFailed':
          'Не удалось загрузить календарь свободного времени.',
      'availableTimesRetryHint':
          'Выберите другую дату или попробуйте обновить экран.',
      'availableTimesClosedDay': 'В этот день сервис не работает',
      'availableTimesClosedDayHint':
          'Выберите другой день, чтобы увидеть свободные слоты.',
      'availableTimesEmpty': 'На этот день свободных слотов не осталось',
      'availableTimesEmptyHint':
          'Попробуйте другую дату или выберите другую услугу.',
      'nearestAvailableTitle': 'Ближайшее свободное время',
      'nearestAvailableSubtitle':
          '{date} в {time} доступен ближайший свободный слот.',
      'selectNearestAvailable': 'Выбрать этот слот',
      'noAvailableDates': 'В ближайшие 45 дней не найдено доступных дат.',
      'summary': 'Сводка заявки',
      'serviceLabel': 'Тип услуги: {service}',
      'vehicleSelectionTitle': 'Выбор автомобиля',
      'savedVehiclesTitle': 'Сохранённые машины',
      'uzbekistanGmVehiclesTitle': 'Модели GM Uzbekistan',
      'otherPopularVehiclesTitle': 'Другие распространённые машины',
      'popularVehiclesTitle': 'Популярные модели',
      'vehicleCatalogMode': 'Выбрать из списка',
      'vehicleOtherOption': 'Другое',
      'vehicleBrandField': 'Марка автомобиля',
      'vehicleBrandHint': 'Например, Chevrolet',
      'vehicleBrandRequired': 'Введите марку автомобиля',
      'vehicleCatalogModelField': 'Модель из списка',
      'vehicleCatalogRequired': 'Выберите модель из списка',
      'vehicleModelField': 'Модель автомобиля',
      'vehicleModelHint': 'Например, Chevrolet Cobalt',
      'vehicleModelRequired': 'Введите модель автомобиля',
      'vehicleModelPending': 'Пока не указана',
      'vehicleModelLabel': 'Автомобиль: {vehicle}',
      'vehicleTypeField': 'Тип автомобиля',
      'vehicleTypeLabel': 'Тип автомобиля: {type}',
      'durationLabel': 'Длительность: {duration}',
      'dateLabel': 'Дата: {date}',
      'timeLabel': 'Время: {time}',
      'bookingTimePending': 'Выберите свободное время',
      'basePriceLabel': 'Базовая цена: {price}',
      'prepaymentSummaryLabel': 'Аванс ({percent}%): {price}',
      'remainingPaymentLabel': 'Остаток в автосервисе: {price}',
      'paymentMethodLabel': 'Способ оплаты',
      'paymentMethodHint':
          'Сейчас это демо-этап оплаты. Выберите наличные или тестовую карту.',
      'paymentMethodCash': 'Наличные',
      'paymentMethodTestCard': 'Тестовая карта',
      'paymentMethodClick': 'Click',
      'paymentMethodPayme': 'Payme',
      'paymentMethodUzum': 'Uzum Bank',
      'paymentMethodBankCard': 'Банковская карта',
      'vehiclePriceRuleLabel': 'Настроенная цена для авто: {vehicle}',
      'vehiclePriceLoadFailed':
          'Не удалось загрузить цену для выбранной модели авто.',
      'vehiclePriceAdjustmentLabel': 'Корректировка по типу авто: {adjustment}',
      'totalLabel': 'Итого: {total}',
      'confirmBooking': 'Подтвердить заявку',
      'payDepositAndBook': 'Оплатить аванс и забронировать',
      'bookWithCash': 'Забронировать с наличной оплатой',
      'payWithTestCardAndBook': 'Открыть тестовую оплату',
      'testPaymentTitle': 'Тестовое окно оплаты',
      'testPaymentSubtitle':
          'Реальный платежный договор пока не подключен. Этот экран только имитирует успешную оплату картой.',
      'testPaymentAmountLabel': 'Сумма для подтверждения: {price}',
      'testPaymentHint':
          'Реальные деньги не списываются. Нажмите кнопку ниже, чтобы продолжить в тестовом режиме.',
      'testPaymentConfirm': 'Подтвердить тестовую оплату',
      'bookingTimeRequired': 'Выберите один из доступных слотов',
      'chatWithWorkshop': 'Чат с мастером',
      'chatOpen': 'Чат',
      'chatInputHint': 'Напишите сообщение по этому заказу',
      'chatSend': 'Отправить',
      'chatSendFailed': 'Сообщение не отправилось',
      'chatEmptyTitle': 'Сообщений пока нет',
      'chatEmptySubtitle':
          'Диалог привязан именно к этому заказу. Вы можете начать его здесь.',
      'chatReplyHint':
          'Пишите только по этому заказу, чтобы мастер ответил быстрее.',
      'chatSenderYou': 'Вы',
      'chatSenderWorkshop': 'Мастер',
      'chatNewReplyNotice': '{workshop} отправил вам новое сообщение',
      'chatUnreadCount': '{count} непрочитанных',
      'writeReview': 'Оставить отзыв',
      'sendReview': 'Отправить отзыв',
      'reviewsTitle': 'Отзывы клиентов',
      'reviewsCount': '{count} отзывов',
      'allServicesLabel': 'Все услуги',
      'reviewAnalyticsTitle': 'Статистика отзывов',
      'reviewAnalyticsSubtitle':
          'Посмотрите распределение оценок и услуги, о которых пишут чаще всего.',
      'reviewAverageLabel': 'Средняя оценка',
      'reviewTopServicesTitle': 'Самые обсуждаемые услуги',
      'reviewTopServicesEmpty':
          'Статистика по услугам появится здесь, когда накопятся отзывы.',
      'reviewStarsLabel': '{stars} звезды',
      'reviewsEmptyTitle': 'Отзывов пока нет',
      'reviewsEmptySubtitle':
          'Станьте первым, кто оставит отзыв об услуге в этом сервисе.',
      'reviewSheetSubtitle':
          'Выберите услугу, поставьте оценку и оставьте короткий честный отзыв.',
      'serviceSelectLabel': 'Услуга',
      'ratingLabel': 'Оценка: {rating}/5',
      'commentLabel': 'Отзыв',
      'reviewHint': 'Напишите, что понравилось и что можно улучшить',
      'reviewCommentValidation': 'Отзыв должен быть не короче 3 символов',
      'reviewSubmitFailed': 'Не удалось отправить отзыв',
      'reviewSubmitSuccess': 'Ваш отзыв опубликован',
      'completedReviewTitle': 'Услуга завершена',
      'completedReviewSubtitle':
          'Услуга {service} в {workshop} выполнена. Оставьте короткий отзыв о работе мастера.',
      'reviewReminderTitle': 'Как прошёл сервис?',
      'reviewReminderSubtitle':
          'Вы ещё не оценили услугу {service} в {workshop}. Оставьте короткий отзыв мастеру.',
      'reviewSubmittedLabel': 'Отзыв отправлен',
      'workshopReplyLabel': 'Ответ сервиса',
      'priceLabel': 'Цена: {price}',
      'prepaymentAmountLabel': 'Сумма аванса: {price}',
      'prepaymentPaidLabel': 'Оплаченный аванс: {price}',
      'paymentStatusLabel': 'Статус оплаты: {status}',
      'paymentMethodValueLabel': 'Способ оплаты: {method}',
      'paymentStatusPending': 'Ожидает',
      'paymentStatusPaid': 'Оплачено',
      'paymentStatusRefunded': 'Возвращено',
      'paymentStatusNotRequired': 'Не требуется',
      'cancelBooking': 'Отменить заявку',
      'rescheduleBooking': 'Перенести заявку',
      'rescheduleBookingTitle': 'Изменить время записи',
      'rescheduleBookingSubtitle':
          'Выберите новую дату и время для {service} в {workshop}.',
      'rescheduleCurrentTimeLabel': 'Текущее время: {time}',
      'rescheduleConfirm': 'Сохранить новое время',
      'acceptRescheduledBooking': 'Принять новое время',
      'acceptRescheduledSuccess': 'Новое время брони подтверждено',
      'acceptRescheduledFailed': 'Не удалось подтвердить новое время',
      'bookingRescheduled': 'Заявка перенесена на новое время',
      'rescheduledByLabel': 'Перенес: {actor}',
      'rescheduledAtLabel': 'Перенесено в: {time}',
      'acceptedAtLabel': 'Принято в: {time}',
      'completedAtLabel': 'Завершено в: {time}',
      'cancelledByLabel': 'Отменил: {actor}',
      'cancelledAtLabel': 'Отменено в: {time}',
      'rescheduledFromLabel': 'Старое время: {time}',
      'cancellationReasonLabel': 'Причина: {reason}',
      'cancellationUnknown': 'Не указано',
      'cancellationReasonWorkshopBusy': 'График занят',
      'cancellationReasonMasterUnavailable': 'Мастер недоступен',
      'cancellationReasonWorkshopClosed': 'Сервис закрыт',
      'cancellationReasonMissingParts': 'Нет запчастей',
      'cancellationReasonCustomerRequest': 'По просьбе клиента',
      'cancellationActorCustomer': 'Клиент',
      'cancellationActorAdmin': 'Админ',
      'cancellationActorOwnerPanel': 'Владелец сервиса',
      'cancellationActorOwnerTelegram': 'Владелец через Telegram',
      'noBookingsYet': 'Заявок пока нет',
      'bookingsEmptyHint':
          'Откройте Главную, выберите сервис и создайте первую заявку.',
      'statusUpcoming': 'Предстоит',
      'statusRescheduled': 'Перенесено',
      'statusAccepted': 'Принят',
      'statusCompleted': 'Завершено',
      'statusCancelled': 'Отменено',
      'totalBookings': 'Всего заявок',
      'upcoming': 'Предстоит',
      'completedMetricLabel': 'Завершенные',
      'bookingHistory': 'История заявок',
      'bookingHistorySubtitle': 'Просмотр завершенных и отмененных заявок',
      'savedSalons': 'Сохраненные сервисы',
      'savedSalonsSubtitle': 'Быстрый доступ к вашим сервисам',
      'notifications': 'Уведомления',
      'testPushNotification': 'Отправить test push',
      'pushReady': 'Push готов',
      'pushNotReady': 'Push пока не готов',
      'testPushSent': 'Test push отправлен',
      'testPushFailed': 'Не удалось отправить test push',
      'enabled': 'Включено',
      'disabled': 'Выключено',
      'language': 'Язык',
      'theme': 'Тема',
      'systemTheme': 'Как в системе',
      'lightTheme': 'Светлая',
      'darkTheme': 'Темная',
      'themeChanged': 'Тема переключена на {theme}',
      'profileUnknownName': 'Пользователь',
      'profileUnknownPhone': 'Телефон не указан',
      'editProfile': 'Редактировать профиль',
      'editProfileName': 'Изменить имя',
      'profileNameField': 'Полное имя',
      'profileNameHint': 'Введите полное имя',
      'profileNameRequired': 'Введите имя',
      'profileNameTooShort': 'Имя должно быть не короче 2 символов',
      'profileUpdated': 'Профиль успешно обновлен',
      'profileUpdateFailed': 'Не удалось обновить профиль',
      'profileNameUpdated': 'Имя успешно обновлено',
      'profileNameUpdateFailed': 'Не удалось обновить имя',
      'changePassword': 'Изменить пароль',
      'currentPassword': 'Текущий пароль',
      'newPassword': 'Новый пароль',
      'confirmPassword': 'Подтвердите пароль',
      'confirmPasswordRequired': 'Подтвердите новый пароль',
      'passwordsDoNotMatch': 'Пароли не совпадают',
      'passwordUpdated': 'Пароль успешно обновлен',
      'passwordUpdateFailed': 'Не удалось обновить пароль',
      'saveChanges': 'Сохранить',
      'refresh': 'Обновить',
      'view': 'Открыть',
      'signOut': 'Выйти',
      'signOutTitle': 'Выход',
      'signOutConfirm': 'Вы уверены, что хотите выйти?',
      'cancel': 'Отмена',
      'login': 'Вход',
      'welcomeBack': 'С возвращением',
      'signInDescription': 'Войдите, чтобы управлять заявками и профилем.',
      'fullName': 'Полное имя',
      'signUp': 'Регистрация',
      'signUpDescription': 'Создайте новый аккаунт с помощью номера телефона.',
      'noAccountYet': 'Еще нет аккаунта?',
      'createAccount': 'Создать аккаунт',
      'forgotPassword': 'Забыли пароль?',
      'forgotPasswordDescription':
          'Введите номер телефона и задайте новый пароль.',
      'resetPassword': 'Сбросить пароль',
      'passwordResetSuccess':
          'Пароль обновлен. Теперь можно войти с новым паролем.',
      'passwordResetFailed': 'Не удалось сбросить пароль',
      'signUpFailed': 'Не удалось создать аккаунт',
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
  String bookingAcceptedNotice(String workshop) => _fmt(
        'bookingAcceptedNotice',
        <String, Object>{'workshop': workshop},
      );
  String bookingCompletedNotice(String workshop) => _fmt(
        'bookingCompletedNotice',
        <String, Object>{'workshop': workshop},
      );
  String bookingCancelledNotice(String workshop, String reason) => _fmt(
        'bookingCancelledNotice',
        <String, Object>{'workshop': workshop, 'reason': reason},
      );
  String bookingRescheduledNotice(String workshop, String time) => _fmt(
        'bookingRescheduledNotice',
        <String, Object>{
          'workshop': workshop,
          'time': time,
        },
      );
  String telegramCancellationNotice(String workshop, String reason) => _fmt(
        'telegramCancellationNotice',
        <String, Object>{'workshop': workshop, 'reason': reason},
      );
  String get savedSalonsConnectedHome => _text('savedSalonsConnectedHome');
  String get savedWorkshopsTitle => _text('savedWorkshopsTitle');
  String get savedWorkshopsEmptyTitle => _text('savedWorkshopsEmptyTitle');
  String get savedWorkshopsEmptyHint => _text('savedWorkshopsEmptyHint');
  String get saveWorkshop => _text('saveWorkshop');
  String get removeSavedWorkshop => _text('removeSavedWorkshop');
  String savedWorkshopAdded(String workshop) =>
      _fmt('savedWorkshopAdded', <String, Object>{'workshop': workshop});
  String savedWorkshopRemoved(String workshop) =>
      _fmt('savedWorkshopRemoved', <String, Object>{'workshop': workshop});
  String get savedWorkshopUpdateFailed => _text('savedWorkshopUpdateFailed');
  String get notificationsEnabled => _text('notificationsEnabled');
  String get notificationsDisabled => _text('notificationsDisabled');

  String languageSwitched(String language) =>
      _fmt('languageSwitched', <String, Object>{'language': language});

  String get findTrustedMasters => _text('findTrustedMasters');
  String get mapTitle => _text('mapTitle');
  String get mapHint => _text('mapHint');
  String get mapNoCoordinates => _text('mapNoCoordinates');
  String get mapNoMatches => _text('mapNoMatches');
  String get openOnMap => _text('openOnMap');
  String get routeToWorkshop => _text('routeToWorkshop');
  String get mapFilterAll => _text('mapFilterAll');
  String get mapFilterTopRated => _text('mapFilterTopRated');
  String get mapFilterNearby => _text('mapFilterNearby');
  String get mapSelectedWorkshop => _text('mapSelectedWorkshop');
  String get mapBrowseList => _text('mapBrowseList');
  String get chooseNavigatorTitle => _text('chooseNavigatorTitle');
  String chooseNavigatorSubtitle(String workshop) =>
      _fmt('chooseNavigatorSubtitle', <String, Object>{'workshop': workshop});
  String get navigatorGoogleMaps => _text('navigatorGoogleMaps');
  String get navigatorYandexNavigator => _text('navigatorYandexNavigator');
  String get navigatorYandexMaps => _text('navigatorYandexMaps');
  String get navigatorAppleMaps => _text('navigatorAppleMaps');
  String get navigatorWaze => _text('navigatorWaze');
  String get navigatorBrowserMaps => _text('navigatorBrowserMaps');
  String get navigatorNoApps => _text('navigatorNoApps');
  String get navigatorOpenFailed => _text('navigatorOpenFailed');
  String get mapOpenInYandex => _text('mapOpenInYandex');
  String get mapOpenYandexFailed => _text('mapOpenYandexFailed');
  String get mapZoomIn => _text('mapZoomIn');
  String get mapZoomOut => _text('mapZoomOut');
  String get mapMyLocation => _text('mapMyLocation');
  String get mapLocationDisabled => _text('mapLocationDisabled');
  String get mapLocationDenied => _text('mapLocationDenied');
  String get mapLocationError => _text('mapLocationError');
  String get searchHint => _text('searchHint');
  String salonsNearby(int count) =>
      _fmt('salonsNearby', <String, Object>{'count': count});
  String get workshopsMetricLabel => _text('workshopsMetricLabel');
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
  String get availableTimesLoadFailed => _text('availableTimesLoadFailed');
  String get availableCalendarLoadFailed =>
      _text('availableCalendarLoadFailed');
  String get availableTimesRetryHint => _text('availableTimesRetryHint');
  String get availableTimesClosedDay => _text('availableTimesClosedDay');
  String get availableTimesClosedDayHint =>
      _text('availableTimesClosedDayHint');
  String get availableTimesEmpty => _text('availableTimesEmpty');
  String get availableTimesEmptyHint => _text('availableTimesEmptyHint');
  String get nearestAvailableTitle => _text('nearestAvailableTitle');
  String nearestAvailableSubtitle(String date, String time) => _fmt(
        'nearestAvailableSubtitle',
        <String, Object>{'date': date, 'time': time},
      );
  String get selectNearestAvailable => _text('selectNearestAvailable');
  String get noAvailableDates => _text('noAvailableDates');
  String get summary => _text('summary');
  String serviceLabel(String service) =>
      _fmt('serviceLabel', <String, Object>{'service': service});
  String get vehicleSelectionTitle => _text('vehicleSelectionTitle');
  String get savedVehiclesTitle => _text('savedVehiclesTitle');
  String get uzbekistanGmVehiclesTitle => _text('uzbekistanGmVehiclesTitle');
  String get otherPopularVehiclesTitle => _text('otherPopularVehiclesTitle');
  String get popularVehiclesTitle => _text('popularVehiclesTitle');
  String get vehicleCatalogMode => _text('vehicleCatalogMode');
  String get vehicleOtherOption => _text('vehicleOtherOption');
  String get vehicleBrandField => _text('vehicleBrandField');
  String get vehicleBrandHint => _text('vehicleBrandHint');
  String get vehicleBrandRequired => _text('vehicleBrandRequired');
  String get vehicleCatalogModelField => _text('vehicleCatalogModelField');
  String get vehicleCatalogRequired => _text('vehicleCatalogRequired');
  String get vehicleModelField => _text('vehicleModelField');
  String get vehicleModelHint => _text('vehicleModelHint');
  String get vehicleModelRequired => _text('vehicleModelRequired');
  String get vehicleModelPending => _text('vehicleModelPending');
  String vehicleModelLabel(String vehicle) =>
      _fmt('vehicleModelLabel', <String, Object>{'vehicle': vehicle});
  String get vehicleTypeField => _text('vehicleTypeField');
  String vehicleTypeLabel(String type) =>
      _fmt('vehicleTypeLabel', <String, Object>{'type': type});
  String durationLabel(String duration) =>
      _fmt('durationLabel', <String, Object>{'duration': duration});
  String dateLabel(String date) =>
      _fmt('dateLabel', <String, Object>{'date': date});
  String timeLabel(String time) =>
      _fmt('timeLabel', <String, Object>{'time': time});
  String get bookingTimePending => _text('bookingTimePending');
  String basePriceLabel(String price) =>
      _fmt('basePriceLabel', <String, Object>{'price': price});
  String prepaymentSummaryLabel(int percent, String price) => _fmt(
        'prepaymentSummaryLabel',
        <String, Object>{'percent': percent, 'price': price},
      );
  String remainingPaymentLabel(String price) =>
      _fmt('remainingPaymentLabel', <String, Object>{'price': price});
  String get paymentMethodLabel => _text('paymentMethodLabel');
  String get paymentMethodHint => _text('paymentMethodHint');
  String get paymentMethodCash => _text('paymentMethodCash');
  String get paymentMethodTestCard => _text('paymentMethodTestCard');
  String get paymentMethodClick => _text('paymentMethodClick');
  String get paymentMethodPayme => _text('paymentMethodPayme');
  String get paymentMethodUzum => _text('paymentMethodUzum');
  String get paymentMethodBankCard => _text('paymentMethodBankCard');
  String vehiclePriceRuleLabel(String vehicle) =>
      _fmt('vehiclePriceRuleLabel', <String, Object>{'vehicle': vehicle});
  String get vehiclePriceLoadFailed => _text('vehiclePriceLoadFailed');
  String vehiclePriceAdjustmentLabel(String adjustment) => _fmt(
        'vehiclePriceAdjustmentLabel',
        <String, Object>{'adjustment': adjustment},
      );
  String totalLabel(String total) =>
      _fmt('totalLabel', <String, Object>{'total': total});
  String get confirmBooking => _text('confirmBooking');
  String get payDepositAndBook => _text('payDepositAndBook');
  String get bookWithCash => _text('bookWithCash');
  String get payWithTestCardAndBook => _text('payWithTestCardAndBook');
  String get testPaymentTitle => _text('testPaymentTitle');
  String get testPaymentSubtitle => _text('testPaymentSubtitle');
  String testPaymentAmountLabel(String price) =>
      _fmt('testPaymentAmountLabel', <String, Object>{'price': price});
  String get testPaymentHint => _text('testPaymentHint');
  String get testPaymentConfirm => _text('testPaymentConfirm');
  String get bookingTimeRequired => _text('bookingTimeRequired');
  String get chatWithWorkshop => _text('chatWithWorkshop');
  String get chatOpen => _text('chatOpen');
  String get chatInputHint => _text('chatInputHint');
  String get chatSend => _text('chatSend');
  String get chatSendFailed => _text('chatSendFailed');
  String get chatEmptyTitle => _text('chatEmptyTitle');
  String get chatEmptySubtitle => _text('chatEmptySubtitle');
  String get chatReplyHint => _text('chatReplyHint');
  String get chatSenderYou => _text('chatSenderYou');
  String get chatSenderWorkshop => _text('chatSenderWorkshop');
  String chatNewReplyNotice(String workshop) =>
      _fmt('chatNewReplyNotice', <String, Object>{'workshop': workshop});
  String chatUnreadCount(int count) =>
      _fmt('chatUnreadCount', <String, Object>{'count': count});
  String get writeReview => _text('writeReview');
  String get sendReview => _text('sendReview');
  String get reviewsTitle => _text('reviewsTitle');
  String reviewsCount(int count) =>
      _fmt('reviewsCount', <String, Object>{'count': count});
  String get allServicesLabel => _text('allServicesLabel');
  String get reviewAnalyticsTitle => _text('reviewAnalyticsTitle');
  String get reviewAnalyticsSubtitle => _text('reviewAnalyticsSubtitle');
  String get reviewAverageLabel => _text('reviewAverageLabel');
  String get reviewTopServicesTitle => _text('reviewTopServicesTitle');
  String get reviewTopServicesEmpty => _text('reviewTopServicesEmpty');
  String reviewStarsLabel(int stars) =>
      _fmt('reviewStarsLabel', <String, Object>{'stars': stars});
  String get reviewsEmptyTitle => _text('reviewsEmptyTitle');
  String get reviewsEmptySubtitle => _text('reviewsEmptySubtitle');
  String get reviewSheetSubtitle => _text('reviewSheetSubtitle');
  String get serviceSelectLabel => _text('serviceSelectLabel');
  String ratingLabel(int rating) =>
      _fmt('ratingLabel', <String, Object>{'rating': rating});
  String get commentLabel => _text('commentLabel');
  String get reviewHint => _text('reviewHint');
  String get reviewCommentValidation => _text('reviewCommentValidation');
  String get reviewSubmitFailed => _text('reviewSubmitFailed');
  String get reviewSubmitSuccess => _text('reviewSubmitSuccess');
  String get completedReviewTitle => _text('completedReviewTitle');
  String completedReviewSubtitle(String service, String workshop) => _fmt(
        'completedReviewSubtitle',
        <String, Object>{
          'service': service,
          'workshop': workshop,
        },
      );
  String get reviewReminderTitle => _text('reviewReminderTitle');
  String reviewReminderSubtitle(String service, String workshop) => _fmt(
        'reviewReminderSubtitle',
        <String, Object>{
          'service': service,
          'workshop': workshop,
        },
      );
  String get reviewSubmittedLabel => _text('reviewSubmittedLabel');
  String get workshopReplyLabel => _text('workshopReplyLabel');
  String priceLabel(String price) =>
      _fmt('priceLabel', <String, Object>{'price': price});
  String prepaymentAmountLabel(String price) =>
      _fmt('prepaymentAmountLabel', <String, Object>{'price': price});
  String prepaymentPaidLabel(String price) =>
      _fmt('prepaymentPaidLabel', <String, Object>{'price': price});
  String paymentStatusLabel(String status) =>
      _fmt('paymentStatusLabel', <String, Object>{'status': status});
  String paymentMethodValueLabel(String method) =>
      _fmt('paymentMethodValueLabel', <String, Object>{'method': method});
  String get paymentStatusPending => _text('paymentStatusPending');
  String get paymentStatusPaid => _text('paymentStatusPaid');
  String get paymentStatusRefunded => _text('paymentStatusRefunded');
  String get paymentStatusNotRequired => _text('paymentStatusNotRequired');

  String get cancelBooking => _text('cancelBooking');
  String get rescheduleBooking => _text('rescheduleBooking');
  String get rescheduleBookingTitle => _text('rescheduleBookingTitle');
  String rescheduleBookingSubtitle(String service, String workshop) => _fmt(
        'rescheduleBookingSubtitle',
        <String, Object>{
          'service': service,
          'workshop': workshop,
        },
      );
  String rescheduleCurrentTimeLabel(String time) => _fmt(
        'rescheduleCurrentTimeLabel',
        <String, Object>{'time': time},
      );
  String get rescheduleConfirm => _text('rescheduleConfirm');
  String get acceptRescheduledBooking => _text('acceptRescheduledBooking');
  String get acceptRescheduledSuccess => _text('acceptRescheduledSuccess');
  String get acceptRescheduledFailed => _text('acceptRescheduledFailed');
  String get bookingRescheduled => _text('bookingRescheduled');
  String rescheduledByLabel(String actor) =>
      _fmt('rescheduledByLabel', <String, Object>{'actor': actor});
  String rescheduledAtLabel(String time) =>
      _fmt('rescheduledAtLabel', <String, Object>{'time': time});
  String acceptedAtLabel(String time) =>
      _fmt('acceptedAtLabel', <String, Object>{'time': time});
  String completedAtLabel(String time) =>
      _fmt('completedAtLabel', <String, Object>{'time': time});
  String cancelledByLabel(String actor) =>
      _fmt('cancelledByLabel', <String, Object>{'actor': actor});
  String cancelledAtLabel(String time) =>
      _fmt('cancelledAtLabel', <String, Object>{'time': time});
  String rescheduledFromLabel(String time) =>
      _fmt('rescheduledFromLabel', <String, Object>{'time': time});
  String cancellationReasonLabel(String reason) =>
      _fmt('cancellationReasonLabel', <String, Object>{'reason': reason});
  String get cancellationUnknown => _text('cancellationUnknown');
  String get cancellationReasonWorkshopBusy =>
      _text('cancellationReasonWorkshopBusy');
  String get cancellationReasonMasterUnavailable =>
      _text('cancellationReasonMasterUnavailable');
  String get cancellationReasonWorkshopClosed =>
      _text('cancellationReasonWorkshopClosed');
  String get cancellationReasonMissingParts =>
      _text('cancellationReasonMissingParts');
  String get cancellationReasonCustomerRequest =>
      _text('cancellationReasonCustomerRequest');
  String get cancellationActorCustomer => _text('cancellationActorCustomer');
  String get cancellationActorAdmin => _text('cancellationActorAdmin');
  String get cancellationActorOwnerPanel =>
      _text('cancellationActorOwnerPanel');
  String get cancellationActorOwnerTelegram =>
      _text('cancellationActorOwnerTelegram');
  String get noBookingsYet => _text('noBookingsYet');
  String get bookingsEmptyHint => _text('bookingsEmptyHint');
  String get statusUpcoming => _text('statusUpcoming');
  String get statusRescheduled => _text('statusRescheduled');
  String get statusAccepted => _text('statusAccepted');
  String get statusCompleted => _text('statusCompleted');
  String get statusCancelled => _text('statusCancelled');

  String get totalBookings => _text('totalBookings');
  String get upcoming => _text('upcoming');
  String get completedMetricLabel => _text('completedMetricLabel');
  String get bookingHistory => _text('bookingHistory');
  String get bookingHistorySubtitle => _text('bookingHistorySubtitle');
  String get savedSalons => _text('savedSalons');
  String get savedSalonsSubtitle => _text('savedSalonsSubtitle');
  String get notifications => _text('notifications');
  String get testPushNotification => _text('testPushNotification');
  String get pushReady => _text('pushReady');
  String get pushNotReady => _text('pushNotReady');
  String get testPushSent => _text('testPushSent');
  String get testPushFailed => _text('testPushFailed');
  String get enabled => _text('enabled');
  String get disabled => _text('disabled');
  String get language => _text('language');
  String get theme => _text('theme');
  String get systemTheme => _text('systemTheme');
  String get lightTheme => _text('lightTheme');
  String get darkTheme => _text('darkTheme');
  String themeChanged(String theme) =>
      _fmt('themeChanged', <String, Object>{'theme': theme});
  String get profileUnknownName => _text('profileUnknownName');
  String get profileUnknownPhone => _text('profileUnknownPhone');
  String get editProfile => _text('editProfile');
  String get editProfileName => _text('editProfileName');
  String get profileNameField => _text('profileNameField');
  String get profileNameHint => _text('profileNameHint');
  String get profileNameRequired => _text('profileNameRequired');
  String get profileNameTooShort => _text('profileNameTooShort');
  String get profileUpdated => _text('profileUpdated');
  String get profileUpdateFailed => _text('profileUpdateFailed');
  String get profileNameUpdated => _text('profileNameUpdated');
  String get profileNameUpdateFailed => _text('profileNameUpdateFailed');
  String get changePassword => _text('changePassword');
  String get currentPassword => _text('currentPassword');
  String get newPassword => _text('newPassword');
  String get confirmPassword => _text('confirmPassword');
  String get confirmPasswordRequired => _text('confirmPasswordRequired');
  String get passwordsDoNotMatch => _text('passwordsDoNotMatch');
  String get passwordUpdated => _text('passwordUpdated');
  String get passwordUpdateFailed => _text('passwordUpdateFailed');
  String get saveChanges => _text('saveChanges');
  String get refresh => _text('refresh');
  String get view => _text('view');
  String get signOut => _text('signOut');
  String get signOutTitle => _text('signOutTitle');
  String get signOutConfirm => _text('signOutConfirm');
  String get cancel => _text('cancel');

  String get login => _text('login');
  String get welcomeBack => _text('welcomeBack');
  String get signInDescription => _text('signInDescription');
  String get fullName => _text('fullName');
  String get signUp => _text('signUp');
  String get signUpDescription => _text('signUpDescription');
  String get noAccountYet => _text('noAccountYet');
  String get createAccount => _text('createAccount');
  String get forgotPassword => _text('forgotPassword');
  String get forgotPasswordDescription => _text('forgotPasswordDescription');
  String get resetPassword => _text('resetPassword');
  String get passwordResetSuccess => _text('passwordResetSuccess');
  String get passwordResetFailed => _text('passwordResetFailed');
  String get signUpFailed => _text('signUpFailed');
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

  String themeModeName(AppThemePreference preference) {
    switch (preference) {
      case AppThemePreference.system:
        return systemTheme;
      case AppThemePreference.light:
        return lightTheme;
      case AppThemePreference.dark:
        return darkTheme;
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
