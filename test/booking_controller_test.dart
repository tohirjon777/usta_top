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

  test('reschedules booking and keeps it in active counters', () {
    final BookingController controller = BookingController();

    final BookingItem booking = BookingItem(
      id: 'b-2',
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
    final bool rescheduled = controller.rescheduleBooking(
      'b-2',
      dateTime: DateTime(2026, 3, 20, 12, 30),
    );

    expect(rescheduled, isTrue);
    expect(controller.upcomingBookings, 1);
    expect(controller.bookings.first.status, BookingStatus.rescheduled);
    expect(
      controller.bookings.first.previousDateTime,
      DateTime(2026, 3, 20, 11, 0),
    );
    expect(controller.bookings.first.dateTime, DateTime(2026, 3, 20, 12, 30));
  });

  test('accepts rescheduled booking from workshop side', () {
    final BookingController controller = BookingController();

    final BookingItem booking = BookingItem(
      id: 'b-3',
      workshopId: 'w-1',
      salonName: 'Turbo Usta Servis',
      masterName: 'Aziz Usta',
      serviceId: 'srv-1',
      serviceName: 'Kompyuter diagnostika',
      vehicleModel: 'Chevrolet Cobalt',
      vehicleTypeId: 'sedan',
      dateTime: DateTime(2026, 3, 20, 12, 30),
      basePrice: 120,
      price: 120,
      status: BookingStatus.rescheduled,
      previousDateTime: DateTime(2026, 3, 20, 11, 0),
      rescheduledByRole: 'owner_panel',
    );

    controller.addBooking(booking);
    final bool accepted = controller.acceptRescheduledBooking('b-3');

    expect(accepted, isTrue);
    expect(controller.bookings.first.status, BookingStatus.accepted);
    expect(controller.bookings.first.acceptedAt, isNotNull);
    expect(controller.upcomingBookings, 1);
  });
}
