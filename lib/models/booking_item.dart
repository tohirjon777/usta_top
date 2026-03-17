enum BookingStatus { upcoming, completed, cancelled }

extension BookingStatusX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class BookingItem {
  const BookingItem({
    required this.id,
    required this.salonName,
    required this.masterName,
    required this.serviceName,
    required this.dateTime,
    required this.price,
    this.status = BookingStatus.upcoming,
  });

  final String id;
  final String salonName;
  final String masterName;
  final String serviceName;
  final DateTime dateTime;
  final int price;
  final BookingStatus status;

  BookingItem copyWith({
    String? id,
    String? salonName,
    String? masterName,
    String? serviceName,
    DateTime? dateTime,
    int? price,
    BookingStatus? status,
  }) {
    return BookingItem(
      id: id ?? this.id,
      salonName: salonName ?? this.salonName,
      masterName: masterName ?? this.masterName,
      serviceName: serviceName ?? this.serviceName,
      dateTime: dateTime ?? this.dateTime,
      price: price ?? this.price,
      status: status ?? this.status,
    );
  }
}
