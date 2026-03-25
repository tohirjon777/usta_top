class BookingAvailabilityCalendar {
  const BookingAvailabilityCalendar({
    required this.days,
    this.nearestAvailableDate,
    this.nearestAvailableTime = '',
  });

  final List<BookingAvailabilityDay> days;
  final DateTime? nearestAvailableDate;
  final String nearestAvailableTime;

  factory BookingAvailabilityCalendar.fromJson(Map<String, dynamic> json) {
    final dynamic rawDays = json['days'];
    return BookingAvailabilityCalendar(
      days: rawDays is List
          ? rawDays
              .whereType<Map<String, dynamic>>()
              .map(BookingAvailabilityDay.fromJson)
              .toList(growable: false)
          : const <BookingAvailabilityDay>[],
      nearestAvailableDate: DateTime.tryParse(
        (json['nearestAvailableDate'] ?? '').toString(),
      ),
      nearestAvailableTime: (json['nearestAvailableTime'] ?? '').toString(),
    );
  }
}

class BookingAvailabilityDay {
  const BookingAvailabilityDay({
    required this.date,
    required this.isClosedDay,
    required this.slotCount,
    required this.activeBookingCount,
    required this.isFullyBooked,
    this.firstSlot = '',
  });

  final DateTime date;
  final bool isClosedDay;
  final int slotCount;
  final int activeBookingCount;
  final bool isFullyBooked;
  final String firstSlot;

  bool get isSelectable => !isClosedDay && !isFullyBooked && slotCount > 0;

  factory BookingAvailabilityDay.fromJson(Map<String, dynamic> json) {
    return BookingAvailabilityDay(
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      isClosedDay: json['isClosedDay'] == true,
      slotCount: _toInt(json['slotCount']),
      activeBookingCount: _toInt(json['activeBookingCount']),
      isFullyBooked: json['isFullyBooked'] == true,
      firstSlot: (json['firstSlot'] ?? '').toString(),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }
}
