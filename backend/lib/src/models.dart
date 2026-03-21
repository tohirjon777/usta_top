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
    required this.dateTime,
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
  final DateTime dateTime;
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
      dateTime: dateTime,
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
      dateTime: DateTime.tryParse((json['dateTime'] ?? '').toString()) ??
          DateTime.now(),
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
      'dateTime': dateTime.toUtc().toIso8601String(),
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
