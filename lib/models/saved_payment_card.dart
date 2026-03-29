class SavedPaymentCard {
  const SavedPaymentCard({
    required this.id,
    required this.holderName,
    required this.brand,
    required this.maskedNumber,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    this.isDefault = false,
    this.updatedAt,
  });

  final String id;
  final String holderName;
  final String brand;
  final String maskedNumber;
  final String last4;
  final int expiryMonth;
  final int expiryYear;
  final bool isDefault;
  final DateTime? updatedAt;

  String get expiryLabel {
    final String month = expiryMonth.toString().padLeft(2, '0');
    final String year = (expiryYear % 100).toString().padLeft(2, '0');
    return '$month/$year';
  }

  String get brandLabel {
    final String normalized = brand.trim();
    return normalized.isEmpty ? 'Card' : normalized;
  }

  SavedPaymentCard copyWith({
    String? id,
    String? holderName,
    String? brand,
    String? maskedNumber,
    String? last4,
    int? expiryMonth,
    int? expiryYear,
    bool? isDefault,
    DateTime? updatedAt,
  }) {
    return SavedPaymentCard(
      id: id ?? this.id,
      holderName: holderName ?? this.holderName,
      brand: brand ?? this.brand,
      maskedNumber: maskedNumber ?? this.maskedNumber,
      last4: last4 ?? this.last4,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      isDefault: isDefault ?? this.isDefault,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SavedPaymentCard.fromJson(Map<String, dynamic> json) {
    return SavedPaymentCard(
      id: (json['id'] ?? '').toString().trim(),
      holderName: (json['holderName'] ?? '').toString().trim(),
      brand: (json['brand'] ?? '').toString().trim(),
      maskedNumber: (json['maskedNumber'] ?? '').toString().trim(),
      last4: (json['last4'] ?? '').toString().trim(),
      expiryMonth: _toInt(json['expiryMonth']),
      expiryYear: _normalizeYear(_toInt(json['expiryYear'])),
      isDefault: json['isDefault'] == true,
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
    );
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'id': id,
      'holderName': holderName,
      'brand': brand,
      'maskedNumber': maskedNumber,
      'last4': last4,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'isDefault': isDefault,
      if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
    };
  }

  static String normalizeDigits(String raw) {
    return raw.replaceAll(RegExp(r'\D+'), '');
  }

  static String detectBrand(String digits) {
    if (digits.startsWith('8600')) {
      return 'Uzcard';
    }
    if (digits.startsWith('9860')) {
      return 'Humo';
    }
    if (digits.startsWith('4')) {
      return 'Visa';
    }

    final int? prefixTwo =
        digits.length >= 2 ? int.tryParse(digits.substring(0, 2)) : null;
    final int? prefixFour =
        digits.length >= 4 ? int.tryParse(digits.substring(0, 4)) : null;
    if ((prefixTwo != null && prefixTwo >= 51 && prefixTwo <= 55) ||
        (prefixFour != null && prefixFour >= 2221 && prefixFour <= 2720)) {
      return 'Mastercard';
    }
    if (digits.startsWith('62')) {
      return 'UnionPay';
    }

    return 'Card';
  }

  static String maskDigits(String digits) {
    if (digits.isEmpty) {
      return '';
    }

    final int visibleCount = digits.length >= 4 ? 4 : digits.length;
    final int hiddenCount = digits.length - visibleCount;
    final StringBuffer buffer = StringBuffer();
    for (int index = 0; index < hiddenCount; index += 1) {
      buffer.write('*');
    }
    buffer.write(digits.substring(digits.length - visibleCount));

    final String rawMasked = buffer.toString();
    final List<String> groups = <String>[];
    for (int index = 0; index < rawMasked.length; index += 4) {
      final int end = (index + 4).clamp(0, rawMasked.length);
      groups.add(rawMasked.substring(index, end));
    }
    return groups.join(' ');
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

  static int _normalizeYear(int year) {
    if (year >= 100) {
      return year;
    }
    return year <= 0 ? 0 : 2000 + year;
  }
}
