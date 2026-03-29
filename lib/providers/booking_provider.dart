import 'dart:collection';

import '../models/booking_availability.dart';
import '../models/booking_availability_calendar.dart';
import '../models/booking_chat_message.dart';
import '../models/booking_item.dart';
import '../models/saved_vehicle_profile.dart';
import '../models/service_price_quote.dart';
import '../services/api_exception.dart';
import '../services/booking_service.dart';
import '../state/booking_controller.dart';

class BookingProvider extends BookingController {
  BookingProvider({
    BookingService? service,
    super.seed,
  }) : _service = service;

  final BookingService? _service;
  final Map<String, List<BookingChatMessage>> _messagesByBookingId =
      <String, List<BookingChatMessage>>{};
  final Set<String> _loadingMessageBookings = <String>{};
  final Set<String> _sendingMessageBookings = <String>{};
  final Map<String, String?> _messageErrors = <String, String?>{};
  final Map<String, BookingAvailability> _availabilityByKey =
      <String, BookingAvailability>{};
  final Set<String> _loadingAvailabilityKeys = <String>{};
  final Map<String, String?> _availabilityErrors = <String, String?>{};
  final Map<String, BookingAvailabilityCalendar> _availabilityCalendarsByKey =
      <String, BookingAvailabilityCalendar>{};
  final Set<String> _loadingCalendarKeys = <String>{};
  final Map<String, String?> _calendarErrors = <String, String?>{};
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UnmodifiableListView<BookingChatMessage> messagesForBooking(
      String bookingId) {
    return UnmodifiableListView<BookingChatMessage>(
      _messagesByBookingId[bookingId] ?? const <BookingChatMessage>[],
    );
  }

  bool isLoadingMessages(String bookingId) {
    return _loadingMessageBookings.contains(bookingId);
  }

  bool isSendingMessage(String bookingId) {
    return _sendingMessageBookings.contains(bookingId);
  }

  String? messageError(String bookingId) => _messageErrors[bookingId];

  BookingAvailability? availabilityFor({
    required String workshopId,
    required String serviceId,
    required DateTime date,
  }) {
    return _availabilityByKey[_availabilityKey(
      workshopId: workshopId,
      serviceId: serviceId,
      date: date,
    )];
  }

  bool isLoadingAvailability({
    required String workshopId,
    required String serviceId,
    required DateTime date,
  }) {
    return _loadingAvailabilityKeys.contains(
      _availabilityKey(
        workshopId: workshopId,
        serviceId: serviceId,
        date: date,
      ),
    );
  }

  String? availabilityError({
    required String workshopId,
    required String serviceId,
    required DateTime date,
  }) {
    return _availabilityErrors[_availabilityKey(
      workshopId: workshopId,
      serviceId: serviceId,
      date: date,
    )];
  }

  BookingAvailabilityCalendar? availabilityCalendarFor({
    required String workshopId,
    required String serviceId,
    required DateTime fromDate,
    int days = 45,
  }) {
    return _availabilityCalendarsByKey[_availabilityCalendarKey(
      workshopId: workshopId,
      serviceId: serviceId,
      fromDate: fromDate,
      days: days,
    )];
  }

  bool isLoadingAvailabilityCalendar({
    required String workshopId,
    required String serviceId,
    required DateTime fromDate,
    int days = 45,
  }) {
    return _loadingCalendarKeys.contains(
      _availabilityCalendarKey(
        workshopId: workshopId,
        serviceId: serviceId,
        fromDate: fromDate,
        days: days,
      ),
    );
  }

  String? availabilityCalendarError({
    required String workshopId,
    required String serviceId,
    required DateTime fromDate,
    int days = 45,
  }) {
    return _calendarErrors[_availabilityCalendarKey(
      workshopId: workshopId,
      serviceId: serviceId,
      fromDate: fromDate,
      days: days,
    )];
  }

  void seedIfEmpty(List<BookingItem> items) {
    if (bookings.isNotEmpty) {
      return;
    }
    for (final BookingItem item in items) {
      addBooking(item);
    }
  }

  Future<void> loadBookings({bool silent = false}) async {
    if (_service == null) {
      return;
    }

    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // TODO(API): Booking ro'yxati BookingService.fetchBookings orqali olinadi.
      final List<BookingItem> items = await _service.fetchBookings();
      replaceBookings(items);
    } on ApiException catch (error) {
      _errorMessage = error.message;
      if (!silent) {
        notifyListeners();
      }
    } catch (_) {
      _errorMessage = 'Buyurtmalarni yuklashda xatolik yuz berdi';
      if (!silent) {
        notifyListeners();
      }
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<BookingItem> createBooking({
    required String workshopId,
    required String workshopName,
    required String masterName,
    required String serviceId,
    required String serviceName,
    required String vehicleBrand,
    required String vehicleModelName,
    required String catalogVehicleId,
    required bool isCustomVehicle,
    required String vehicleTypeId,
    required DateTime dateTime,
    required int basePrice,
    required int totalPrice,
    required int prepaymentPercent,
    String paymentMethod = '',
  }) async {
    _errorMessage = null;

    final String vehicleDisplayName = formatVehicleDisplayName(
      brand: vehicleBrand,
      model: vehicleModelName,
    );

    try {
      if (_service == null) {
        final bool isTestCardPayment = paymentMethod.trim() == 'test_card';
        final BookingItem localBooking = BookingItem(
          id: 'b-${DateTime.now().microsecondsSinceEpoch}',
          workshopId: workshopId,
          salonName: workshopName,
          masterName: masterName,
          serviceId: serviceId,
          serviceName: serviceName,
          vehicleModel: vehicleDisplayName,
          vehicleTypeId: vehicleTypeId,
          dateTime: dateTime,
          basePrice: basePrice,
          price: totalPrice,
          prepaymentPercent: prepaymentPercent,
          prepaymentAmount: ((totalPrice * prepaymentPercent) / 100).ceil(),
          remainingAmount:
              totalPrice - (((totalPrice * prepaymentPercent) / 100).ceil()),
          paymentStatus: prepaymentPercent > 0
              ? (isTestCardPayment
                  ? BookingPaymentStatus.paid
                  : BookingPaymentStatus.pending)
              : BookingPaymentStatus.notRequired,
          paymentMethod: paymentMethod,
          paidAt:
              prepaymentPercent > 0 && isTestCardPayment ? DateTime.now() : null,
        );
        upsertBooking(localBooking);
        return localBooking;
      }

      // TODO(API): Booking yaratish BookingService.createBooking orqali backendga ketadi.
      final BookingItem created = await _service.createBooking(
        workshopId: workshopId,
        serviceId: serviceId,
        vehicleBrand: vehicleBrand,
        vehicleModelName: vehicleModelName,
        vehicleDisplayName: vehicleDisplayName,
        catalogVehicleId: catalogVehicleId,
        isCustomVehicle: isCustomVehicle,
        vehicleTypeId: vehicleTypeId,
        dateTime: dateTime,
        paymentMethod: paymentMethod,
      );
      _invalidateAvailability(
        workshopId: workshopId,
        serviceId: serviceId,
        date: dateTime,
      );
      _invalidateAvailabilityCalendars(
        workshopId: workshopId,
        serviceId: serviceId,
      );
      upsertBooking(created);
      return created;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      rethrow;
    } catch (_) {
      _errorMessage = 'Buyurtma yaratishda xatolik yuz berdi';
      notifyListeners();
      rethrow;
    }
  }

  Future<BookingAvailability> loadAvailability({
    required String workshopId,
    required String serviceId,
    required DateTime date,
  }) async {
    final String key = _availabilityKey(
      workshopId: workshopId,
      serviceId: serviceId,
      date: date,
    );
    _availabilityErrors.remove(key);
    _loadingAvailabilityKeys.add(key);
    notifyListeners();

    try {
      if (_service == null) {
        final BookingAvailability fallback = _localAvailability(date);
        _availabilityByKey[key] = fallback;
        return fallback;
      }

      final BookingAvailability availability = await _service.fetchAvailability(
        workshopId: workshopId,
        serviceId: serviceId,
        date: date,
      );
      _availabilityByKey[key] = availability;
      return availability;
    } on ApiException catch (error) {
      _availabilityErrors[key] = error.message;
      rethrow;
    } catch (_) {
      _availabilityErrors[key] = 'Bo‘sh vaqtlarni yuklab bo‘lmadi';
      rethrow;
    } finally {
      _loadingAvailabilityKeys.remove(key);
      notifyListeners();
    }
  }

  Future<BookingAvailabilityCalendar> loadAvailabilityCalendar({
    required String workshopId,
    required String serviceId,
    required DateTime fromDate,
    int days = 45,
  }) async {
    final String key = _availabilityCalendarKey(
      workshopId: workshopId,
      serviceId: serviceId,
      fromDate: fromDate,
      days: days,
    );
    _calendarErrors.remove(key);
    _loadingCalendarKeys.add(key);
    notifyListeners();

    try {
      if (_service == null) {
        final BookingAvailabilityCalendar fallback =
            _localAvailabilityCalendar(fromDate, days: days);
        _availabilityCalendarsByKey[key] = fallback;
        return fallback;
      }

      final BookingAvailabilityCalendar calendar =
          await _service.fetchAvailabilityCalendar(
        workshopId: workshopId,
        serviceId: serviceId,
        fromDate: fromDate,
        days: days,
      );
      _availabilityCalendarsByKey[key] = calendar;
      return calendar;
    } on ApiException catch (error) {
      _calendarErrors[key] = error.message;
      rethrow;
    } catch (_) {
      _calendarErrors[key] = 'Kalendar bo‘sh vaqtlarini yuklab bo‘lmadi';
      rethrow;
    } finally {
      _loadingCalendarKeys.remove(key);
      notifyListeners();
    }
  }

  Future<ServicePriceQuote> loadPriceQuote({
    required String workshopId,
    required String serviceId,
    required String catalogVehicleId,
    required String vehicleBrand,
    required String vehicleModelName,
    required String vehicleTypeId,
    required int fallbackBasePrice,
    int fallbackPrepaymentPercent = 0,
  }) async {
    if (_service == null) {
      final int prepaymentAmount =
          ((fallbackBasePrice * fallbackPrepaymentPercent) / 100).ceil();
      return ServicePriceQuote(
        basePrice: fallbackBasePrice,
        price: fallbackBasePrice,
        prepaymentPercent: fallbackPrepaymentPercent,
        prepaymentAmount: prepaymentAmount,
        remainingAmount: fallbackBasePrice - prepaymentAmount,
        requiresPrepayment: prepaymentAmount > 0,
      );
    }

    return _service.fetchPriceQuote(
      workshopId: workshopId,
      serviceId: serviceId,
      catalogVehicleId: catalogVehicleId,
      vehicleBrand: vehicleBrand,
      vehicleModelName: vehicleModelName,
      vehicleTypeId: vehicleTypeId,
    );
  }

  Future<void> loadBookingMessages(
    String bookingId, {
    bool markRead = true,
  }) async {
    _messageErrors.remove(bookingId);
    _loadingMessageBookings.add(bookingId);
    notifyListeners();

    try {
      if (_service == null) {
        final List<BookingChatMessage> localMessages =
            _messagesByBookingId[bookingId] ?? const <BookingChatMessage>[];
        _messagesByBookingId[bookingId] = List<BookingChatMessage>.unmodifiable(
          localMessages,
        );
        _markBookingMessagesReadLocally(bookingId);
        return;
      }

      final List<BookingChatMessage> messages =
          await _service.fetchBookingMessages(
        bookingId: bookingId,
      );
      _messagesByBookingId[bookingId] =
          List<BookingChatMessage>.unmodifiable(messages);

      if (markRead) {
        await _service.markBookingMessagesRead(bookingId: bookingId);
        _markBookingMessagesReadLocally(bookingId);
      } else {
        _syncBookingPreviewFromMessages(bookingId, messages);
      }
    } on ApiException catch (error) {
      _messageErrors[bookingId] = error.message;
    } catch (_) {
      _messageErrors[bookingId] = 'Chat xabarlarini yuklab bo\'lmadi';
    } finally {
      _loadingMessageBookings.remove(bookingId);
      notifyListeners();
    }
  }

  Future<bool> sendBookingMessage({
    required String bookingId,
    required String text,
  }) async {
    final String normalizedText = normalizeBookingChatText(text);
    if (normalizedText.isEmpty) {
      _messageErrors[bookingId] = 'Xabar matnini kiriting';
      notifyListeners();
      return false;
    }

    _messageErrors.remove(bookingId);
    _sendingMessageBookings.add(bookingId);
    notifyListeners();

    try {
      if (_service == null) {
        final BookingChatMessage localMessage = BookingChatMessage(
          id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
          bookingId: bookingId,
          senderRole: BookingChatSenderRole.customer,
          senderName: 'Siz',
          text: normalizedText,
          createdAt: DateTime.now(),
        );
        final List<BookingChatMessage> next = <BookingChatMessage>[
          ...(_messagesByBookingId[bookingId] ?? const <BookingChatMessage>[]),
          localMessage,
        ];
        _messagesByBookingId[bookingId] =
            List<BookingChatMessage>.unmodifiable(next);
        _syncBookingPreviewFromMessages(bookingId, next);
        return true;
      }

      final BookingChatMessage sent = await _service.sendBookingMessage(
        bookingId: bookingId,
        text: normalizedText,
      );
      final List<BookingChatMessage> next = <BookingChatMessage>[
        ...(_messagesByBookingId[bookingId] ?? const <BookingChatMessage>[]),
        sent,
      ];
      _messagesByBookingId[bookingId] =
          List<BookingChatMessage>.unmodifiable(next);
      _syncBookingPreviewFromMessages(bookingId, next);
      return true;
    } on ApiException catch (error) {
      _messageErrors[bookingId] = error.message;
      return false;
    } catch (_) {
      _messageErrors[bookingId] = 'Xabar yuborishda xatolik yuz berdi';
      return false;
    } finally {
      _sendingMessageBookings.remove(bookingId);
      notifyListeners();
    }
  }

  Future<bool> cancelBookingRequest(String bookingId) async {
    _errorMessage = null;

    if (_service == null) {
      return cancelBooking(bookingId);
    }

    try {
      // TODO(API): Booking bekor qilish BookingService.cancelBooking orqali backendga ketadi.
      final BookingItem cancelled = await _service.cancelBooking(
        bookingId: bookingId,
      );
      upsertBooking(cancelled);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Buyurtmani bekor qilishda xatolik yuz berdi';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rescheduleBookingRequest({
    required String bookingId,
    required DateTime dateTime,
  }) async {
    _errorMessage = null;
    final BookingItem? current = bookings.cast<BookingItem?>().firstWhere(
          (BookingItem? item) => item?.id == bookingId,
          orElse: () => null,
        );
    if (current == null) {
      _errorMessage = 'Buyurtma topilmadi';
      notifyListeners();
      return false;
    }

    if (_service == null) {
      final bool changed = rescheduleBooking(
        bookingId,
        dateTime: dateTime,
      );
      if (changed) {
        _invalidateAvailability(
          workshopId: current.workshopId,
          serviceId: current.serviceId,
          date: current.dateTime,
        );
        _invalidateAvailability(
          workshopId: current.workshopId,
          serviceId: current.serviceId,
          date: dateTime,
        );
        _invalidateAvailabilityCalendars(
          workshopId: current.workshopId,
          serviceId: current.serviceId,
        );
      }
      return changed;
    }

    try {
      final BookingItem updated = await _service.rescheduleBooking(
        bookingId: bookingId,
        dateTime: dateTime,
      );
      _invalidateAvailability(
        workshopId: current.workshopId,
        serviceId: current.serviceId,
        date: current.dateTime,
      );
      _invalidateAvailability(
        workshopId: current.workshopId,
        serviceId: current.serviceId,
        date: dateTime,
      );
      _invalidateAvailabilityCalendars(
        workshopId: current.workshopId,
        serviceId: current.serviceId,
      );
      upsertBooking(updated);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Buyurtmani ko‘chirishda xatolik yuz berdi';
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptRescheduledBookingRequest(String bookingId) async {
    _errorMessage = null;
    final BookingItem? current = bookings.cast<BookingItem?>().firstWhere(
          (BookingItem? item) => item?.id == bookingId,
          orElse: () => null,
        );
    if (current == null) {
      _errorMessage = 'Buyurtma topilmadi';
      notifyListeners();
      return false;
    }

    if (_service == null) {
      final bool changed = acceptRescheduledBooking(bookingId);
      if (!changed) {
        _errorMessage = 'Buyurtmani tasdiqlab bo‘lmadi';
        notifyListeners();
      }
      return changed;
    }

    try {
      final BookingItem updated = await _service.acceptRescheduledBooking(
        bookingId: bookingId,
      );
      upsertBooking(updated);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Buyurtmani tasdiqlashda xatolik yuz berdi';
      notifyListeners();
      return false;
    }
  }

  void markBookingReviewed(
    String bookingId, {
    String? reviewId,
    DateTime? submittedAt,
  }) {
    final int index = bookings
        .toList()
        .indexWhere((BookingItem item) => item.id == bookingId);
    if (index < 0) {
      return;
    }
    final BookingItem booking = bookings[index];
    upsertBooking(
      booking.copyWith(
        reviewId: (reviewId == null || reviewId.trim().isEmpty)
            ? booking.reviewId.isEmpty
                ? 'local-review-$bookingId'
                : booking.reviewId
            : reviewId.trim(),
        reviewSubmittedAt: submittedAt ?? DateTime.now(),
      ),
    );
  }

  void _markBookingMessagesReadLocally(String bookingId) {
    final int index = bookings
        .toList()
        .indexWhere((BookingItem item) => item.id == bookingId);
    if (index < 0) {
      return;
    }
    final BookingItem booking = bookings[index];
    upsertBooking(
      booking.copyWith(
        unreadForCustomerCount: 0,
      ),
    );
  }

  String _availabilityKey({
    required String workshopId,
    required String serviceId,
    required DateTime date,
  }) {
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    final String month = normalized.month.toString().padLeft(2, '0');
    final String day = normalized.day.toString().padLeft(2, '0');
    return '$workshopId|$serviceId|${normalized.year}-$month-$day';
  }

  String _availabilityCalendarKey({
    required String workshopId,
    required String serviceId,
    required DateTime fromDate,
    required int days,
  }) {
    final DateTime normalized = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final String month = normalized.month.toString().padLeft(2, '0');
    final String day = normalized.day.toString().padLeft(2, '0');
    return '$workshopId|$serviceId|calendar|${normalized.year}-$month-$day|$days';
  }

  void _invalidateAvailability({
    required String workshopId,
    required String serviceId,
    required DateTime date,
  }) {
    final String key = _availabilityKey(
      workshopId: workshopId,
      serviceId: serviceId,
      date: date,
    );
    _availabilityByKey.remove(key);
    _availabilityErrors.remove(key);
  }

  void _invalidateAvailabilityCalendars({
    required String workshopId,
    required String serviceId,
  }) {
    final String prefix = '$workshopId|$serviceId|calendar|';
    final List<String> keys = _availabilityCalendarsByKey.keys
        .where((String item) => item.startsWith(prefix))
        .toList(growable: false);
    for (final String key in keys) {
      _availabilityCalendarsByKey.remove(key);
      _calendarErrors.remove(key);
    }
  }

  BookingAvailability _localAvailability(DateTime date) {
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    if (normalized.weekday == DateTime.sunday) {
      return BookingAvailability(
        date: normalized,
        slots: const <BookingAvailabilitySlot>[],
        isClosedDay: true,
        serviceDurationMinutes: 30,
        openingTime: '10:00',
        closingTime: '19:00',
        breakStartTime: '13:00',
        breakEndTime: '14:00',
      );
    }

    const List<String> fallbackSlots = <String>[
      '10:00',
      '10:30',
      '11:00',
      '11:30',
      '12:00',
      '12:30',
      '14:00',
      '14:30',
      '15:00',
      '15:30',
      '16:00',
      '16:30',
      '17:00',
      '17:30',
      '18:00',
      '18:30',
    ];
    final DateTime now = DateTime.now();
    final List<BookingAvailabilitySlot> slots = fallbackSlots.map((String item) {
      final List<String> parts = item.split(':');
      final DateTime slotDate = DateTime(
        normalized.year,
        normalized.month,
        normalized.day,
        int.parse(parts.first),
        int.parse(parts.last),
      );
      final bool isAvailable = slotDate.isAfter(now);
      return BookingAvailabilitySlot(
        time: item,
        isAvailable: isAvailable,
        reason: isAvailable ? 'available' : 'past',
      );
    }).toList(growable: false);

    return BookingAvailability(
      date: normalized,
      slots: slots,
      isClosedDay: false,
      serviceDurationMinutes: 30,
      openingTime: '10:00',
      closingTime: '19:00',
      breakStartTime: '13:00',
      breakEndTime: '14:00',
    );
  }

  BookingAvailabilityCalendar _localAvailabilityCalendar(
    DateTime fromDate, {
    required int days,
  }) {
    final DateTime start = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final List<BookingAvailabilityDay> items = <BookingAvailabilityDay>[];
    DateTime? nearestDate;
    String nearestTime = '';
    for (int index = 0; index < days; index++) {
      final DateTime date = start.add(Duration(days: index));
      final BookingAvailability availability = _localAvailability(date);
      final BookingAvailabilityDay day = BookingAvailabilityDay(
        date: date,
        isClosedDay: availability.isClosedDay,
        slotCount: availability.slotTimes.length,
        activeBookingCount: 0,
        isFullyBooked: !availability.isClosedDay && availability.slotTimes.isEmpty,
        firstSlot:
            availability.slotTimes.isEmpty ? '' : availability.slotTimes.first,
      );
      items.add(day);
      if (nearestDate == null && day.firstSlot.isNotEmpty) {
        nearestDate = date;
        nearestTime = day.firstSlot;
      }
    }
    return BookingAvailabilityCalendar(
      days: List<BookingAvailabilityDay>.unmodifiable(items),
      nearestAvailableDate: nearestDate,
      nearestAvailableTime: nearestTime,
    );
  }

  void _syncBookingPreviewFromMessages(
    String bookingId,
    List<BookingChatMessage> messages,
  ) {
    final int index = bookings
        .toList()
        .indexWhere((BookingItem item) => item.id == bookingId);
    if (index < 0) {
      return;
    }
    final BookingItem booking = bookings[index];
    final BookingChatMessage? latest = messages.isEmpty ? null : messages.last;
    upsertBooking(
      booking.copyWith(
        messageCount: messages.length,
        unreadForCustomerCount: 0,
        lastMessagePreview: latest?.text ?? booking.lastMessagePreview,
        lastMessageSenderRole: latest == null
            ? booking.lastMessageSenderRole
            : bookingChatSenderRoleName(latest.senderRole),
        lastMessageAt: latest?.createdAt ?? booking.lastMessageAt,
      ),
    );
  }
}
