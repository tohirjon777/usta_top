import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/booking_item.dart';

class BookingController extends ChangeNotifier {
  BookingController({List<BookingItem>? seed}) {
    if (seed != null && seed.isNotEmpty) {
      _bookings.addAll(seed);
    }
  }

  final List<BookingItem> _bookings = <BookingItem>[];

  UnmodifiableListView<BookingItem> get bookings =>
      UnmodifiableListView<BookingItem>(_bookings);

  int get totalBookings => _bookings.length;

  int get upcomingBookings => _bookings
      .where((BookingItem item) =>
          item.status == BookingStatus.upcoming ||
          item.status == BookingStatus.rescheduled ||
          item.status == BookingStatus.accepted)
      .length;

  void addBooking(BookingItem booking) {
    _bookings.insert(0, booking);
    notifyListeners();
  }

  bool cancelBooking(String bookingId) {
    final int index =
        _bookings.indexWhere((BookingItem item) => item.id == bookingId);
    if (index == -1) {
      return false;
    }

    final BookingItem current = _bookings[index];
    if (current.status != BookingStatus.upcoming &&
        current.status != BookingStatus.rescheduled &&
        current.status != BookingStatus.accepted) {
      return false;
    }

    _bookings[index] = current.copyWith(
      status: BookingStatus.cancelled,
      cancelReasonId: 'customer_request',
      cancelledByRole: 'customer',
      cancelledAt: DateTime.now(),
    );
    notifyListeners();
    return true;
  }

  @protected
  void replaceBookings(Iterable<BookingItem> items) {
    _bookings
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  @protected
  void upsertBooking(BookingItem booking) {
    final int index =
        _bookings.indexWhere((BookingItem item) => item.id == booking.id);
    if (index == -1) {
      _bookings.insert(0, booking);
    } else {
      _bookings[index] = booking;
    }
    notifyListeners();
  }
}
