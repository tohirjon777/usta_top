class SalonReview {
  const SalonReview({
    required this.id,
    required this.workshopId,
    required this.serviceId,
    required this.serviceName,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.ownerReply = '',
    this.ownerReplyAt,
    this.ownerReplySource = '',
  });

  final String id;
  final String workshopId;
  final String serviceId;
  final String serviceName;
  final String customerName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String ownerReply;
  final DateTime? ownerReplyAt;
  final String ownerReplySource;

  bool get hasOwnerReply => ownerReply.trim().isNotEmpty;

  factory SalonReview.fromJson(Map<String, dynamic> json) {
    return SalonReview(
      id: (json['id'] ?? '').toString(),
      workshopId: (json['workshopId'] ?? '').toString(),
      serviceId: (json['serviceId'] ?? '').toString(),
      serviceName: (json['serviceName'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      rating: _toInt(json['rating']).clamp(1, 5),
      comment: normalizeSalonReviewText((json['comment'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      ownerReply:
          normalizeSalonReviewText((json['ownerReply'] ?? '').toString()),
      ownerReplyAt:
          DateTime.tryParse((json['ownerReplyAt'] ?? '').toString()),
      ownerReplySource: (json['ownerReplySource'] ?? '').toString(),
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

String normalizeSalonReviewText(String raw) {
  return raw
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((String line) => line.trimRight())
      .join('\n')
      .trim();
}
