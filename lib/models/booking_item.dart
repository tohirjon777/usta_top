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
    required this.workshopId,
    required this.salonName,
    required this.masterName,
    required this.serviceId,
    required this.serviceName,
    required this.dateTime,
    required this.price,
    this.status = BookingStatus.upcoming,
  });

  final String id;
  final String workshopId;
  final String salonName;
  final String masterName;
  final String serviceId;
  final String serviceName;
  final DateTime dateTime;
  final int price;
  final BookingStatus status;

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    // TODO(API): booking object kalitlari:
    // id, workshopId, workshopName|salonName, masterName, serviceId,
    // serviceName, dateTime, price, status
    return BookingItem(
      id: (json['id'] ?? '').toString(),
      workshopId: (json['workshopId'] ?? '').toString(),
      salonName: (json['workshopName'] ?? json['salonName'] ?? '').toString(),
      masterName: (json['masterName'] ?? '').toString(),
      serviceId: (json['serviceId'] ?? '').toString(),
      serviceName: (json['serviceName'] ?? '').toString(),
      dateTime: DateTime.tryParse((json['dateTime'] ?? '').toString()) ??
          DateTime.now(),
      price: _toInt(json['price']),
      status: _statusFromString((json['status'] ?? '').toString()),
    );
  }

  BookingItem copyWith({
    String? id,
    String? workshopId,
    String? salonName,
    String? masterName,
    String? serviceId,
    String? serviceName,
    DateTime? dateTime,
    int? price,
    BookingStatus? status,
  }) {
    return BookingItem(
      id: id ?? this.id,
      workshopId: workshopId ?? this.workshopId,
      salonName: salonName ?? this.salonName,
      masterName: masterName ?? this.masterName,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      dateTime: dateTime ?? this.dateTime,
      price: price ?? this.price,
      status: status ?? this.status,
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

  static BookingStatus _statusFromString(String value) {
    switch (value.toLowerCase()) {
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'upcoming':
      default:
        return BookingStatus.upcoming;
    }
  }
}
