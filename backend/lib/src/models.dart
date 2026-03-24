import 'booking_cancellation.dart';
import 'vehicle_types.dart';

enum BookingStatus { upcoming, completed, cancelled }

enum BookingChatSenderRole { customer, workshopOwner }

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
    this.cancelReasonId = '',
    this.cancelledByRole = '',
    this.cancelledAt,
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
  final String cancelReasonId;
  final String cancelledByRole;
  final DateTime? cancelledAt;

  BookingModel copyWith({
    BookingStatus? status,
    String? cancelReasonId,
    String? cancelledByRole,
    DateTime? cancelledAt,
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
      cancelReasonId: cancelReasonId ?? this.cancelReasonId,
      cancelledByRole: cancelledByRole ?? this.cancelledByRole,
      cancelledAt: cancelledAt ?? this.cancelledAt,
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
      cancelReasonId: normalizeBookingCancellationReasonId(
        (json['cancelReasonId'] ?? '').toString(),
      ),
      cancelledByRole: normalizeBookingCancellationActor(
        (json['cancelledByRole'] ?? '').toString(),
      ),
      cancelledAt: DateTime.tryParse((json['cancelledAt'] ?? '').toString()),
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
      if (cancelReasonId.isNotEmpty) 'cancelReasonId': cancelReasonId,
      if (cancelledByRole.isNotEmpty) 'cancelledByRole': cancelledByRole,
      if (cancelledAt != null)
        'cancelledAt': cancelledAt!.toUtc().toIso8601String(),
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

class BookingChatMessageModel {
  const BookingChatMessageModel({
    required this.id,
    required this.bookingId,
    required this.senderRole,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.readByCustomerAt,
    this.readByOwnerAt,
  });

  final String id;
  final String bookingId;
  final BookingChatSenderRole senderRole;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final DateTime? readByCustomerAt;
  final DateTime? readByOwnerAt;

  bool get isFromCustomer => senderRole == BookingChatSenderRole.customer;

  BookingChatMessageModel copyWith({
    String? id,
    String? bookingId,
    BookingChatSenderRole? senderRole,
    String? senderName,
    String? text,
    DateTime? createdAt,
    DateTime? readByCustomerAt,
    DateTime? readByOwnerAt,
  }) {
    return BookingChatMessageModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      senderRole: senderRole ?? this.senderRole,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      readByCustomerAt: readByCustomerAt ?? this.readByCustomerAt,
      readByOwnerAt: readByOwnerAt ?? this.readByOwnerAt,
    );
  }

  factory BookingChatMessageModel.fromJson(Map<String, dynamic> json) {
    return BookingChatMessageModel(
      id: (json['id'] ?? '').toString().trim(),
      bookingId: (json['bookingId'] ?? '').toString().trim(),
      senderRole: bookingChatSenderRoleFromString(
        (json['senderRole'] ?? '').toString(),
      ),
      senderName: (json['senderName'] ?? '').toString().trim(),
      text: normalizeBookingChatText((json['text'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      readByCustomerAt: DateTime.tryParse(
        (json['readByCustomerAt'] ?? '').toString(),
      ),
      readByOwnerAt: DateTime.tryParse(
        (json['readByOwnerAt'] ?? '').toString(),
      ),
    );
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'id': id,
      'bookingId': bookingId,
      'senderRole': bookingChatSenderRoleName(senderRole),
      'senderName': senderName,
      'text': text,
      'createdAt': createdAt.toUtc().toIso8601String(),
      if (readByCustomerAt != null)
        'readByCustomerAt': readByCustomerAt!.toUtc().toIso8601String(),
      if (readByOwnerAt != null)
        'readByOwnerAt': readByOwnerAt!.toUtc().toIso8601String(),
    };
  }
}

class BookingChatSummaryModel {
  const BookingChatSummaryModel({
    this.messageCount = 0,
    this.unreadForCustomerCount = 0,
    this.unreadForOwnerCount = 0,
    this.lastMessagePreview = '',
    this.lastMessageSenderRole = '',
    this.lastMessageAt,
  });

  final int messageCount;
  final int unreadForCustomerCount;
  final int unreadForOwnerCount;
  final String lastMessagePreview;
  final String lastMessageSenderRole;
  final DateTime? lastMessageAt;
}

class PushTokenModel {
  const PushTokenModel({
    required this.token,
    required this.platform,
    required this.updatedAt,
  });

  final String token;
  final String platform;
  final DateTime updatedAt;

  PushTokenModel copyWith({
    String? token,
    String? platform,
    DateTime? updatedAt,
  }) {
    return PushTokenModel(
      token: token ?? this.token,
      platform: platform ?? this.platform,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PushTokenModel.fromJson(Map<String, dynamic> json) {
    return PushTokenModel(
      token: (json['token'] ?? '').toString().trim(),
      platform: normalizePushPlatform((json['platform'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'token': token,
      'platform': platform,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }
}

String normalizePushPlatform(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'android':
      return 'android';
    case 'ios':
      return 'ios';
    case 'web':
      return 'web';
    default:
      return 'unknown';
  }
}

BookingChatSenderRole bookingChatSenderRoleFromString(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'workshop_owner':
      return BookingChatSenderRole.workshopOwner;
    case 'customer':
    default:
      return BookingChatSenderRole.customer;
  }
}

String bookingChatSenderRoleName(BookingChatSenderRole role) {
  switch (role) {
    case BookingChatSenderRole.customer:
      return 'customer';
    case BookingChatSenderRole.workshopOwner:
      return 'workshop_owner';
  }
}

String normalizeBookingChatText(String raw) {
  return raw
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((String line) => line.trimRight())
      .join('\n')
      .trim();
}

String bookingChatPreview(
  String raw, {
  int maxLength = 88,
}) {
  final String normalized = normalizeBookingChatText(
    raw,
  ).replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.length <= maxLength) {
    return normalized;
  }
  return '${normalized.substring(0, maxLength - 3)}...';
}

class SavedVehicleModel {
  const SavedVehicleModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.vehicleTypeId,
    this.catalogVehicleId = '',
    this.isCustom = false,
    this.usageCount = 0,
    this.lastUsedAt,
  });

  final String id;
  final String brand;
  final String model;
  final String vehicleTypeId;
  final String catalogVehicleId;
  final bool isCustom;
  final int usageCount;
  final DateTime? lastUsedAt;

  SavedVehicleModel copyWith({
    String? id,
    String? brand,
    String? model,
    String? vehicleTypeId,
    String? catalogVehicleId,
    bool? isCustom,
    int? usageCount,
    DateTime? lastUsedAt,
  }) {
    return SavedVehicleModel(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      vehicleTypeId: vehicleTypeId ?? this.vehicleTypeId,
      catalogVehicleId: catalogVehicleId ?? this.catalogVehicleId,
      isCustom: isCustom ?? this.isCustom,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  factory SavedVehicleModel.fromJson(Map<String, dynamic> json) {
    return SavedVehicleModel(
      id: (json['id'] ?? '').toString().trim(),
      brand: normalizeSavedVehicleBrand((json['brand'] ?? '').toString()),
      model: normalizeSavedVehicleModelName((json['model'] ?? '').toString()),
      vehicleTypeId:
          vehicleTypePricingById((json['vehicleTypeId'] ?? '').toString()).id,
      catalogVehicleId: (json['catalogVehicleId'] ?? '').toString().trim(),
      isCustom: json['isCustom'] == true,
      usageCount: _toInt(json['usageCount']),
      lastUsedAt: DateTime.tryParse((json['lastUsedAt'] ?? '').toString()),
    );
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'id': id,
      'brand': brand,
      'model': model,
      'vehicleTypeId': vehicleTypeId,
      if (catalogVehicleId.isNotEmpty) 'catalogVehicleId': catalogVehicleId,
      'isCustom': isCustom,
      'usageCount': usageCount,
      if (lastUsedAt != null)
        'lastUsedAt': lastUsedAt!.toUtc().toIso8601String(),
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

String normalizeSavedVehicleBrand(String raw) {
  return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String normalizeSavedVehicleModelName(String raw) {
  return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String formatSavedVehicleDisplayName({
  required String brand,
  required String model,
}) {
  final String normalizedBrand = normalizeSavedVehicleBrand(brand);
  final String normalizedModel = normalizeSavedVehicleModelName(model);
  if (normalizedBrand.isEmpty) {
    return normalizedModel;
  }
  if (normalizedModel.isEmpty) {
    return normalizedBrand;
  }
  return '$normalizedBrand $normalizedModel';
}

class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.password,
    this.pushTokens = const <PushTokenModel>[],
    this.savedVehicles = const <SavedVehicleModel>[],
  });

  final String id;
  final String fullName;
  final String phone;
  final String password;
  final List<PushTokenModel> pushTokens;
  final List<SavedVehicleModel> savedVehicles;

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? password,
    List<PushTokenModel>? pushTokens,
    List<SavedVehicleModel>? savedVehicles,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      pushTokens: pushTokens ?? this.pushTokens,
      savedVehicles: savedVehicles ?? this.savedVehicles,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawPushTokens = json['pushTokens'];
    final List<PushTokenModel> pushTokens = rawPushTokens is List
        ? rawPushTokens
            .whereType<Map<String, dynamic>>()
            .map(PushTokenModel.fromJson)
            .where((PushTokenModel item) => item.token.isNotEmpty)
            .toList(growable: false)
        : <PushTokenModel>[];
    final dynamic rawSavedVehicles = json['savedVehicles'];
    final List<SavedVehicleModel> savedVehicles = rawSavedVehicles is List
        ? rawSavedVehicles
            .whereType<Map<String, dynamic>>()
            .map(SavedVehicleModel.fromJson)
            .where((SavedVehicleModel item) {
            return item.brand.isNotEmpty && item.model.isNotEmpty;
          }).toList(growable: false)
        : <SavedVehicleModel>[];

    return UserModel(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
      pushTokens: pushTokens,
      savedVehicles: savedVehicles,
    );
  }

  Map<String, Object> toStorageJson() {
    return <String, Object>{
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'password': password,
      if (pushTokens.isNotEmpty)
        'pushTokens':
            pushTokens.map((PushTokenModel item) => item.toJson()).toList(),
      if (savedVehicles.isNotEmpty)
        'savedVehicles': savedVehicles
            .map((SavedVehicleModel item) => item.toJson())
            .toList(),
    };
  }

  Map<String, Object> toPublicJson() {
    return <String, Object>{
      'id': id,
      'fullName': fullName,
      'phone': phone,
      if (savedVehicles.isNotEmpty)
        'savedVehicles': savedVehicles
            .map((SavedVehicleModel item) => item.toJson())
            .toList(),
    };
  }
}
