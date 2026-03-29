class BookingAvailability {
  const BookingAvailability({
    required this.date,
    required this.slots,
    required this.isClosedDay,
    required this.serviceDurationMinutes,
    required this.openingTime,
    required this.closingTime,
    required this.breakStartTime,
    required this.breakEndTime,
  });

  final DateTime date;
  final List<BookingAvailabilitySlot> slots;
  final bool isClosedDay;
  final int serviceDurationMinutes;
  final String openingTime;
  final String closingTime;
  final String breakStartTime;
  final String breakEndTime;

  List<String> get slotTimes => slots
      .where((BookingAvailabilitySlot slot) => slot.isAvailable)
      .map((BookingAvailabilitySlot slot) => slot.time)
      .toList(growable: false);

  bool get hasBreak =>
      breakStartTime.trim().isNotEmpty && breakEndTime.trim().isNotEmpty;

  factory BookingAvailability.fromJson(Map<String, dynamic> json) {
    final dynamic rawAllSlots = json['allSlots'];
    final dynamic rawSlots = json['slots'];

    final List<BookingAvailabilitySlot> parsedSlots;
    if (rawAllSlots is List) {
      parsedSlots = rawAllSlots
          .whereType<Map<String, dynamic>>()
          .map(BookingAvailabilitySlot.fromJson)
          .toList(growable: false);
    } else if (rawSlots is List) {
      parsedSlots = rawSlots
          .map(
            (dynamic item) => BookingAvailabilitySlot(
              time: item.toString(),
              isAvailable: true,
              reason: 'available',
            ),
          )
          .toList(growable: false);
    } else {
      parsedSlots = const <BookingAvailabilitySlot>[];
    }

    return BookingAvailability(
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      slots: parsedSlots,
      isClosedDay: json['isClosedDay'] == true,
      serviceDurationMinutes: _toInt(json['serviceDurationMinutes']),
      openingTime: (json['openingTime'] ?? '').toString(),
      closingTime: (json['closingTime'] ?? '').toString(),
      breakStartTime: (json['breakStartTime'] ?? '').toString(),
      breakEndTime: (json['breakEndTime'] ?? '').toString(),
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

class BookingAvailabilitySlot {
  const BookingAvailabilitySlot({
    required this.time,
    required this.isAvailable,
    required this.reason,
  });

  final String time;
  final bool isAvailable;
  final String reason;

  factory BookingAvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return BookingAvailabilitySlot(
      time: (json['time'] ?? '').toString(),
      isAvailable: json['isAvailable'] == true,
      reason: (json['reason'] ?? '').toString(),
    );
  }
}
