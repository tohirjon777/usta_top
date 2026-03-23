import '../models/booking_item.dart';

abstract interface class BookingService {
  Future<List<BookingItem>> fetchBookings();

  Future<BookingItem> createBooking({
    required String workshopId,
    required String serviceId,
    required String vehicleModel,
    required String vehicleTypeId,
    required DateTime dateTime,
  });

  Future<BookingItem> cancelBooking({
    required String bookingId,
  });
}
