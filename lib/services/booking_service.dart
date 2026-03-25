import '../models/booking_item.dart';
import '../models/booking_availability.dart';
import '../models/booking_chat_message.dart';

abstract interface class BookingService {
  Future<List<BookingItem>> fetchBookings();

  Future<BookingItem> createBooking({
    required String workshopId,
    required String serviceId,
    required String vehicleBrand,
    required String vehicleModelName,
    required String vehicleDisplayName,
    required String catalogVehicleId,
    required bool isCustomVehicle,
    required String vehicleTypeId,
    required DateTime dateTime,
  });

  Future<BookingAvailability> fetchAvailability({
    required String workshopId,
    required String serviceId,
    required DateTime date,
  });

  Future<BookingItem> cancelBooking({
    required String bookingId,
  });

  Future<List<BookingChatMessage>> fetchBookingMessages({
    required String bookingId,
  });

  Future<BookingChatMessage> sendBookingMessage({
    required String bookingId,
    required String text,
  });

  Future<void> markBookingMessagesRead({
    required String bookingId,
  });
}
