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

  Map<String, Object> toJson() {
    return <String, Object>{
      'id': id,
      'name': name,
      'price': price,
      'durationMinutes': durationMinutes,
    };
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
  final List<ServiceModel> services;

  WorkshopModel copyWith({
    double? latitude,
    double? longitude,
  }) {
    return WorkshopModel(
      id: id,
      name: name,
      master: master,
      rating: rating,
      reviewCount: reviewCount,
      address: address,
      description: description,
      distanceKm: distanceKm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isOpen: isOpen,
      badge: badge,
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
      'startingPrice': startingPrice,
      'services': services.map((ServiceModel item) => item.toJson()).toList(),
    };
  }
}

class BookingModel {
  const BookingModel({
    required this.id,
    required this.userId,
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

  Map<String, Object> toJson() {
    return <String, Object>{
      'id': id,
      'userId': userId,
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

  Map<String, Object> toPublicJson() {
    return <String, Object>{
      'id': id,
      'fullName': fullName,
      'phone': phone,
    };
  }
}
