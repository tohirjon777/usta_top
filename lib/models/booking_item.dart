import 'vehicle_type.dart';

enum BookingStatus { upcoming, accepted, rescheduled, completed, cancelled }

enum BookingPaymentStatus { notRequired, pending, paid, refunded }

extension BookingStatusX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.rescheduled:
        return 'Rescheduled';
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
    this.originalPrice = 0,
    this.prepaymentPercent = 0,
    this.prepaymentAmount = 0,
    this.remainingAmount = 0,
    this.paymentStatus = BookingPaymentStatus.notRequired,
    this.paymentMethod = '',
    this.paidAt,
    this.cashbackAppliedAmount = 0,
    this.cashbackAppliedStatus = '',
    this.cashbackPercent = 0,
    this.cashbackAmount = 0,
    this.cashbackStatus = '',
    this.cashbackCreditedAt,
    this.status = BookingStatus.upcoming,
    this.acceptedAt,
    this.completedAt,
    this.previousDateTime,
    this.rescheduledAt,
    this.rescheduledByRole = '',
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
  final int originalPrice;
  final int prepaymentPercent;
  final int prepaymentAmount;
  final int remainingAmount;
  final BookingPaymentStatus paymentStatus;
  final String paymentMethod;
  final DateTime? paidAt;
  final int cashbackAppliedAmount;
  final String cashbackAppliedStatus;
  final int cashbackPercent;
  final int cashbackAmount;
  final String cashbackStatus;
  final DateTime? cashbackCreditedAt;
  final BookingStatus status;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? previousDateTime;
  final DateTime? rescheduledAt;
  final String rescheduledByRole;
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
      dateTime: _parseDateTime(json['dateTime']) ?? DateTime.now(),
      basePrice: _toInt(json['basePrice']) == 0
          ? _toInt(json['price'])
          : _toInt(json['basePrice']),
      price: _toInt(json['price']),
      originalPrice: _toInt(json['originalPrice']) == 0
          ? _toInt(json['price'])
          : _toInt(json['originalPrice']),
      prepaymentPercent: _toInt(json['prepaymentPercent']),
      prepaymentAmount: _toInt(json['prepaymentAmount']),
      remainingAmount: _toInt(json['remainingAmount']),
      paymentStatus: _paymentStatusFromString(
        (json['paymentStatus'] ?? '').toString(),
      ),
      paymentMethod: (json['paymentMethod'] ?? '').toString().trim(),
      paidAt: _parseDateTime(json['paidAt']),
      cashbackAppliedAmount: _toInt(json['cashbackAppliedAmount']),
      cashbackAppliedStatus:
          (json['cashbackAppliedStatus'] ?? '').toString().trim(),
      cashbackPercent: _toInt(json['cashbackPercent']),
      cashbackAmount: _toInt(json['cashbackAmount']),
      cashbackStatus: (json['cashbackStatus'] ?? '').toString().trim(),
      cashbackCreditedAt: _parseDateTime(json['cashbackCreditedAt']),
      status: _statusFromString((json['status'] ?? '').toString()),
      acceptedAt: _parseDateTime(json['acceptedAt']),
      completedAt: _parseDateTime(json['completedAt']),
      previousDateTime: _parseDateTime(json['previousDateTime']),
      rescheduledAt: _parseDateTime(json['rescheduledAt']),
      rescheduledByRole: (json['rescheduledByRole'] ?? '').toString().trim(),
      reviewId: (json['reviewId'] ?? '').toString().trim(),
      reviewSubmittedAt: _parseDateTime(json['reviewSubmittedAt']),
      messageCount: _toInt(json['messageCount']),
      unreadForCustomerCount: _toInt(json['unreadForCustomerCount']),
      lastMessagePreview: (json['lastMessagePreview'] ?? '').toString(),
      lastMessageSenderRole: (json['lastMessageSenderRole'] ?? '').toString(),
      lastMessageAt: _parseDateTime(json['lastMessageAt']),
      cancelReasonId: (json['cancelReasonId'] ?? '').toString().trim(),
      cancelledByRole: (json['cancelledByRole'] ?? '').toString().trim(),
      cancelledAt: _parseDateTime(json['cancelledAt']),
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
    int? originalPrice,
    int? prepaymentPercent,
    int? prepaymentAmount,
    int? remainingAmount,
    BookingPaymentStatus? paymentStatus,
    String? paymentMethod,
    DateTime? paidAt,
    int? cashbackAppliedAmount,
    String? cashbackAppliedStatus,
    int? cashbackPercent,
    int? cashbackAmount,
    String? cashbackStatus,
    DateTime? cashbackCreditedAt,
    BookingStatus? status,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? previousDateTime,
    DateTime? rescheduledAt,
    String? rescheduledByRole,
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
      originalPrice: originalPrice ?? this.originalPrice,
      prepaymentPercent: prepaymentPercent ?? this.prepaymentPercent,
      prepaymentAmount: prepaymentAmount ?? this.prepaymentAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      cashbackAppliedAmount:
          cashbackAppliedAmount ?? this.cashbackAppliedAmount,
      cashbackAppliedStatus:
          cashbackAppliedStatus ?? this.cashbackAppliedStatus,
      cashbackPercent: cashbackPercent ?? this.cashbackPercent,
      cashbackAmount: cashbackAmount ?? this.cashbackAmount,
      cashbackStatus: cashbackStatus ?? this.cashbackStatus,
      cashbackCreditedAt: cashbackCreditedAt ?? this.cashbackCreditedAt,
      status: status ?? this.status,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      previousDateTime: previousDateTime ?? this.previousDateTime,
      rescheduledAt: rescheduledAt ?? this.rescheduledAt,
      rescheduledByRole: rescheduledByRole ?? this.rescheduledByRole,
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

  static DateTime? _parseDateTime(Object? value) {
    final DateTime? parsed = DateTime.tryParse((value ?? '').toString());
    if (parsed == null) {
      return null;
    }
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  static BookingStatus _statusFromString(String value) {
    switch (value.toLowerCase()) {
      case 'accepted':
        return BookingStatus.accepted;
      case 'rescheduled':
        return BookingStatus.rescheduled;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'upcoming':
      default:
        return BookingStatus.upcoming;
    }
  }

  static BookingPaymentStatus _paymentStatusFromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return BookingPaymentStatus.pending;
      case 'paid':
        return BookingPaymentStatus.paid;
      case 'refunded':
        return BookingPaymentStatus.refunded;
      case 'not_required':
      case 'notrequired':
      default:
        return BookingPaymentStatus.notRequired;
    }
  }
}
