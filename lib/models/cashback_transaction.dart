class CashbackTransaction {
  const CashbackTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.bookingId = '',
    this.workshopName = '',
    this.serviceName = '',
    this.createdAt,
  });

  final String id;
  final String type;
  final int amount;
  final int balanceAfter;
  final String bookingId;
  final String workshopName;
  final String serviceName;
  final DateTime? createdAt;

  bool get isCredit => amount > 0;

  factory CashbackTransaction.fromJson(Map<String, dynamic> json) {
    return CashbackTransaction(
      id: (json['id'] ?? '').toString().trim(),
      type: (json['type'] ?? '').toString().trim(),
      amount: _toInt(json['amount']),
      balanceAfter: _toInt(json['balanceAfter']),
      bookingId: (json['bookingId'] ?? '').toString().trim(),
      workshopName: (json['workshopName'] ?? '').toString().trim(),
      serviceName: (json['serviceName'] ?? '').toString().trim(),
      createdAt: _parseDateTime(json['createdAt']),
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
}
