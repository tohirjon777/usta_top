import 'dart:collection';

import '../models/booking_chat_message.dart';
import '../models/booking_item.dart';
import '../models/saved_vehicle_profile.dart';
import '../models/vehicle_type.dart';
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
  }) async {
    _errorMessage = null;

    final String vehicleDisplayName = formatVehicleDisplayName(
      brand: vehicleBrand,
      model: vehicleModelName,
    );

    try {
      if (_service == null) {
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
          price: adjustedVehiclePrice(
            basePrice: basePrice,
            vehicleTypeId: vehicleTypeId,
          ),
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
