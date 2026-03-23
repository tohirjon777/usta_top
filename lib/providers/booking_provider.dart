import '../models/booking_item.dart';
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
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
    required String vehicleModel,
    required String vehicleTypeId,
    required DateTime dateTime,
    required int basePrice,
  }) async {
    _errorMessage = null;

    try {
      if (_service == null) {
        final BookingItem localBooking = BookingItem(
          id: 'b-${DateTime.now().microsecondsSinceEpoch}',
          workshopId: workshopId,
          salonName: workshopName,
          masterName: masterName,
          serviceId: serviceId,
          serviceName: serviceName,
          vehicleModel: vehicleModel,
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
        vehicleModel: vehicleModel,
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
}
