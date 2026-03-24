import 'vehicle_type.dart';

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
    required this.vehicleModel,
    required this.vehicleTypeId,
    required this.dateTime,
    required this.basePrice,
    required this.price,
    this.status = BookingStatus.upcoming,
    this.completedAt,
    this.reviewId = '',
    this.reviewSubmittedAt,
    this.messageCount = 0,
    this.unreadForCustomerCount = 0,
    this.lastMessagePreview = '',
    this.lastMessageSenderRole = '',
    this.lastMessageAt,
    this.cancelReasonId = '',
    this.cancelledByRole = '',
    this.cancelledAt,
  });

  final String id;
  final String workshopId;
  final String salonName;
  final String masterName;
  final String serviceId;
  final String serviceName;
  final String vehicleModel;
  final String vehicleTypeId;
  final DateTime dateTime;
  final int basePrice;
  final int price;
  final BookingStatus status;
  final DateTime? completedAt;
  final String reviewId;
  final DateTime? reviewSubmittedAt;
  final int messageCount;
  final int unreadForCustomerCount;
  final String lastMessagePreview;
  final String lastMessageSenderRole;
  final DateTime? lastMessageAt;
  final String cancelReasonId;
  final String cancelledByRole;
  final DateTime? cancelledAt;

  bool get hasReview => reviewId.trim().isNotEmpty;

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
      vehicleModel: (json['vehicleModel'] ?? '').toString(),
      vehicleTypeId: vehicleTypeById(
        (json['vehicleTypeId'] ?? 'sedan').toString(),
      ).id,
      dateTime: DateTime.tryParse((json['dateTime'] ?? '').toString()) ??
          DateTime.now(),
      basePrice: _toInt(json['basePrice']) == 0
          ? _toInt(json['price'])
          : _toInt(json['basePrice']),
      price: _toInt(json['price']),
      status: _statusFromString((json['status'] ?? '').toString()),
      completedAt: DateTime.tryParse((json['completedAt'] ?? '').toString()),
      reviewId: (json['reviewId'] ?? '').toString().trim(),
      reviewSubmittedAt:
          DateTime.tryParse((json['reviewSubmittedAt'] ?? '').toString()),
      messageCount: _toInt(json['messageCount']),
      unreadForCustomerCount: _toInt(json['unreadForCustomerCount']),
      lastMessagePreview: (json['lastMessagePreview'] ?? '').toString(),
      lastMessageSenderRole: (json['lastMessageSenderRole'] ?? '').toString(),
      lastMessageAt:
          DateTime.tryParse((json['lastMessageAt'] ?? '').toString()),
      cancelReasonId: (json['cancelReasonId'] ?? '').toString().trim(),
      cancelledByRole: (json['cancelledByRole'] ?? '').toString().trim(),
      cancelledAt: DateTime.tryParse((json['cancelledAt'] ?? '').toString()),
    );
  }

  BookingItem copyWith({
    String? id,
    String? workshopId,
    String? salonName,
    String? masterName,
    String? serviceId,
    String? serviceName,
    String? vehicleModel,
    String? vehicleTypeId,
    DateTime? dateTime,
    int? basePrice,
    int? price,
    BookingStatus? status,
    DateTime? completedAt,
    String? reviewId,
    DateTime? reviewSubmittedAt,
    int? messageCount,
    int? unreadForCustomerCount,
    String? lastMessagePreview,
    String? lastMessageSenderRole,
    DateTime? lastMessageAt,
    String? cancelReasonId,
    String? cancelledByRole,
    DateTime? cancelledAt,
  }) {
    return BookingItem(
      id: id ?? this.id,
      workshopId: workshopId ?? this.workshopId,
      salonName: salonName ?? this.salonName,
      masterName: masterName ?? this.masterName,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleTypeId: vehicleTypeId ?? this.vehicleTypeId,
      dateTime: dateTime ?? this.dateTime,
      basePrice: basePrice ?? this.basePrice,
      price: price ?? this.price,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      reviewId: reviewId ?? this.reviewId,
      reviewSubmittedAt: reviewSubmittedAt ?? this.reviewSubmittedAt,
      messageCount: messageCount ?? this.messageCount,
      unreadForCustomerCount:
          unreadForCustomerCount ?? this.unreadForCustomerCount,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageSenderRole:
          lastMessageSenderRole ?? this.lastMessageSenderRole,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      cancelReasonId: cancelReasonId ?? this.cancelReasonId,
      cancelledByRole: cancelledByRole ?? this.cancelledByRole,
      cancelledAt: cancelledAt ?? this.cancelledAt,
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
