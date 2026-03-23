import 'package:flutter_test/flutter_test.dart';
import 'package:usta_top/models/booking_item.dart';
import 'package:usta_top/state/booking_controller.dart';

void main() {
  test('adds and cancels booking with counters update', () {
    final BookingController controller = BookingController();

    final BookingItem booking = BookingItem(
      id: 'b-1',
      workshopId: 'w-1',
      salonName: 'Turbo Usta Servis',
      masterName: 'Aziz Usta',
      serviceId: 'srv-1',
      serviceName: 'Kompyuter diagnostika',
      vehicleModel: 'Chevrolet Cobalt',
      vehicleTypeId: 'sedan',
      dateTime: DateTime(2026, 3, 20, 11, 0),
      basePrice: 120,
      price: 120,
    );

    controller.addBooking(booking);
    expect(controller.totalBookings, 1);
    expect(controller.upcomingBookings, 1);

    final bool cancelled = controller.cancelBooking('b-1');
    expect(cancelled, isTrue);
    expect(controller.upcomingBookings, 0);
    expect(controller.bookings.first.status, BookingStatus.cancelled);
  });
}
