import 'vehicle_types.dart';

enum BookingStatus { upcoming, completed, cancelled }

class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
  });

  final String id;
  final String name;
  final int price;
  final int durationMinutes;

  ServiceModel copyWith({
    String? id,
    String? name,
    int? price,
    int? durationMinutes,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: _toInt(json['price']),
      durationMinutes: _toInt(json['durationMinutes']),
    );
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'id': id,
      'name': name,
      'price': price,
      'durationMinutes': durationMinutes,
    };
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

class WorkshopModel {
  const WorkshopModel({
    required this.id,
    required this.name,
    required this.master,
    required this.rating,
    required this.reviewCount,
    required this.address,
    required this.description,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    required this.isOpen,
    required this.badge,
    required this.ownerAccessCode,
    required this.telegramChatId,
    required this.telegramChatLabel,
    required this.telegramLinkCode,
    required this.services,
  });

  final String id;
  final String name;
  final String master;
  final double rating;
  final int reviewCount;
  final String address;
  final String description;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final bool isOpen;
  final String badge;
  final String ownerAccessCode;
  final String telegramChatId;
  final String telegramChatLabel;
  final String telegramLinkCode;
  final List<ServiceModel> services;

  WorkshopModel copyWith({
    String? id,
    String? name,
    String? master,
    double? rating,
    int? reviewCount,
    String? address,
    String? description,
    double? distanceKm,
    double? latitude,
    double? longitude,
    bool? isOpen,
    String? badge,
    String? ownerAccessCode,
    String? telegramChatId,
    String? telegramChatLabel,
    String? telegramLinkCode,
    List<ServiceModel>? services,
  }) {
    return WorkshopModel(
      id: id ?? this.id,
      name: name ?? this.name,
      master: master ?? this.master,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      address: address ?? this.address,
      description: description ?? this.description,
      distanceKm: distanceKm ?? this.distanceKm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isOpen: isOpen ?? this.isOpen,
      badge: badge ?? this.badge,
      ownerAccessCode: ownerAccessCode ?? this.ownerAccessCode,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      telegramChatLabel: telegramChatLabel ?? this.telegramChatLabel,
      telegramLinkCode: telegramLinkCode ?? this.telegramLinkCode,
      services: services ?? this.services,
    );
  }

  factory WorkshopModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawServices = json['services'];
    final List<ServiceModel> services = rawServices is List
        ? rawServices
            .whereType<Map<String, dynamic>>()
            .map(ServiceModel.fromJson)
            .toList(growable: false)
        : <ServiceModel>[];

    return WorkshopModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      master: (json['master'] ?? '').toString(),
      rating: _toDouble(json['rating']),
      reviewCount: _toInt(json['reviewCount']),
      address: (json['address'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      distanceKm: _toDouble(json['distanceKm']),
      latitude: _toDouble(json['latitude'] ?? json['lat']),
      longitude: _toDouble(json['longitude'] ?? json['lng']),
      isOpen: json['isOpen'] == true,
      badge: (json['badge'] ?? '').toString(),
      ownerAccessCode: _normalizeOwnerAccessCode(
        rawCode: (json['ownerAccessCode'] ?? '').toString(),
        workshopId: (json['id'] ?? '').toString(),
      ),
      telegramChatId: _normalizeTelegramChatId(
        (json['telegramChatId'] ?? '').toString(),
      ),
      telegramChatLabel: _normalizeTelegramChatLabel(
        (json['telegramChatLabel'] ?? '').toString(),
      ),
      telegramLinkCode: _normalizeTelegramLinkCode(
        (json['telegramLinkCode'] ?? '').toString(),
      ),
      services: services,
    );
  }

  ServiceModel? getServiceById(String serviceId) {
    for (final ServiceModel service in services) {
      if (service.id == serviceId) {
        return service;
      }
    }
    return null;
  }

  int get startingPrice {
    if (services.isEmpty) {
      return 0;
    }

    int minPrice = services.first.price;
    for (final ServiceModel service in services.skip(1)) {
      if (service.price < minPrice) {
        minPrice = service.price;
      }
    }
    return minPrice;
  }

  bool matchesQuery(String query) {
    final String q = query.toLowerCase();
    if (name.toLowerCase().contains(q) || address.toLowerCase().contains(q)) {
      return true;
    }
    for (final ServiceModel service in services) {
      if (service.name.toLowerCase().contains(q)) {
        return true;
      }
    }
    return false;
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'id': id,
      'name': name,
      'master': master,
      'rating': rating,
      'reviewCount': reviewCount,
      'address': address,
      'description': description,
      'distanceKm': distanceKm,
      'latitude': latitude,
      'longitude': longitude,
      'isOpen': isOpen,
      'badge': badge,
      'ownerAccessCode': ownerAccessCode,
      'telegramChatId': telegramChatId,
      'telegramChatLabel': telegramChatLabel,
      'telegramLinkCode': telegramLinkCode,
      'startingPrice': startingPrice,
      'services': services.map((ServiceModel item) => item.toJson()).toList(),
    };
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

  static double _toDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? 0;
  }

  static String defaultOwnerAccessCode(String workshopId) {
    final String digits = workshopId.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return '0000';
    }
    if (digits.length >= 4) {
      return digits.substring(digits.length - 4);
    }
    return digits.padLeft(4, '0');
  }

  static String _normalizeOwnerAccessCode({
    required String rawCode,
    required String workshopId,
  }) {
    final String code = rawCode.trim();
    if (code.isNotEmpty) {
      return code;
    }
    return defaultOwnerAccessCode(workshopId);
  }

  static String _normalizeTelegramChatId(String raw) {
    return raw.trim();
  }

  static String _normalizeTelegramChatLabel(String raw) {
    return raw.trim();
  }

  static String _normalizeTelegramLinkCode(String raw) {
    return raw.trim().toUpperCase();
  }
}

class BookingModel {
  const BookingModel({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.workshopId,
    required this.workshopName,
    required this.masterName,
    required this.serviceId,
    required this.serviceName,
    required this.vehicleModel,
    required this.vehicleTypeId,
    required this.dateTime,
    required this.basePrice,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String customerName;
  final String customerPhone;
  final String workshopId;
  final String workshopName;
  final String masterName;
  final String serviceId;
  final String serviceName;
  final String vehicleModel;
  final String vehicleTypeId;
  final DateTime dateTime;
  final int basePrice;
  final int price;
  final BookingStatus status;
  final DateTime createdAt;

  BookingModel copyWith({
    BookingStatus? status,
  }) {
    return BookingModel(
      id: id,
      userId: userId,
      customerName: customerName,
      customerPhone: customerPhone,
      workshopId: workshopId,
      workshopName: workshopName,
      masterName: masterName,
      serviceId: serviceId,
      serviceName: serviceName,
      vehicleModel: vehicleModel,
      vehicleTypeId: vehicleTypeId,
      dateTime: dateTime,
      basePrice: basePrice,
      price: price,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      customerPhone: (json['customerPhone'] ?? '').toString(),
      workshopId: (json['workshopId'] ?? '').toString(),
      workshopName: (json['workshopName'] ?? '').toString(),
      masterName: (json['masterName'] ?? '').toString(),
      serviceId: (json['serviceId'] ?? '').toString(),
      serviceName: (json['serviceName'] ?? '').toString(),
      vehicleModel: (json['vehicleModel'] ?? '').toString(),
      vehicleTypeId: vehicleTypePricingById(
        (json['vehicleTypeId'] ?? '').toString(),
      ).id,
      dateTime: DateTime.tryParse((json['dateTime'] ?? '').toString()) ??
          DateTime.now(),
      basePrice: _toInt(json['basePrice']) == 0
          ? _toInt(json['price'])
          : _toInt(json['basePrice']),
      price: _toInt(json['price']),
      status: _bookingStatusFromString((json['status'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'id': id,
      'userId': userId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'workshopId': workshopId,
      'workshopName': workshopName,
      'masterName': masterName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'vehicleModel': vehicleModel,
      'vehicleTypeId': vehicleTypeId,
      'dateTime': dateTime.toUtc().toIso8601String(),
      'basePrice': basePrice,
      'price': price,
      'status': status.name,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  Map<String, Object> toStorageJson() => toJson();

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }

  static BookingStatus _bookingStatusFromString(String raw) {
    switch (raw.toLowerCase()) {
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

class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.password,
  });

  final String id;
  final String fullName;
  final String phone;
  final String password;

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? password,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      password: password ?? this.password,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
    );
  }

  Map<String, Object> toStorageJson() {
    return <String, Object>{
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'password': password,
    };
  }

  Map<String, Object> toPublicJson() {
    return <String, Object>{
      'id': id,
      'fullName': fullName,
      'phone': phone,
    };
  }
}
