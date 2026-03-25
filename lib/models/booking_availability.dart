class BookingAvailability {
  const BookingAvailability({
    required this.date,
    required this.slotTimes,
    required this.isClosedDay,
    required this.serviceDurationMinutes,
    required this.openingTime,
    required this.closingTime,
    required this.breakStartTime,
    required this.breakEndTime,
  });

  final DateTime date;
  final List<String> slotTimes;
  final bool isClosedDay;
  final int serviceDurationMinutes;
  final String openingTime;
  final String closingTime;
  final String breakStartTime;
  final String breakEndTime;

  bool get hasBreak =>
      breakStartTime.trim().isNotEmpty && breakEndTime.trim().isNotEmpty;

  factory BookingAvailability.fromJson(Map<String, dynamic> json) {
    final dynamic rawSlots = json['slots'];
    return BookingAvailability(
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      slotTimes: rawSlots is List
          ? rawSlots.map((dynamic item) => item.toString()).toList(growable: false)
          : const <String>[],
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
