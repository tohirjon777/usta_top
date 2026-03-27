import 'salon_review.dart';

class SalonService {
  const SalonService({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.prepaymentPercent = 0,
  });

  final String id;
  final String name;
  final int price;
  final int durationMinutes;
  final int prepaymentPercent;

  factory SalonService.fromJson(Map<String, dynamic> json) {
    // TODO(API): service object quyidagi kalitlarni yuborishi kerak:
    // id, name, price, durationMinutes
    return SalonService(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: _toInt(json['price']),
      durationMinutes: _toInt(json['durationMinutes']),
      prepaymentPercent: _normalizePrepaymentPercent(
        _toInt(json['prepaymentPercent']),
      ),
    );
  }

  int calculatePrepaymentAmount(int totalPrice) {
    if (prepaymentPercent <= 0 || totalPrice <= 0) {
      return 0;
    }
    return ((totalPrice * prepaymentPercent) / 100).ceil();
  }

  static int _normalizePrepaymentPercent(int value) {
    if (value <= 0) {
      return 0;
    }
    if (value >= 100) {
      return 100;
    }
    return value;
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

class Salon {
  const Salon({
    required this.id,
    required this.name,
    required this.master,
    required this.rating,
    required this.reviewCount,
    required this.address,
    required this.description,
    required this.distanceKm,
    this.latitude,
    this.longitude,
    required this.isOpen,
    required this.badge,
    required this.services,
    this.reviews = const <SalonReview>[],
  });

  final String id;
  final String name;
  final String master;
  final double rating;
  final int reviewCount;
  final String address;
  final String description;
  final double distanceKm;
  final double? latitude;
  final double? longitude;
  final bool isOpen;
  final String badge;
  final List<SalonService> services;
  final List<SalonReview> reviews;

  factory Salon.fromJson(Map<String, dynamic> json) {
    // TODO(API): workshop object kalitlari:
    // id, name, master, rating, reviewCount, address, description,
    // distanceKm, isOpen, badge, services[]
    final dynamic rawServices = json['services'];
    final List<SalonService> parsedServices = rawServices is List
        ? rawServices
            .whereType<Map<String, dynamic>>()
            .map(SalonService.fromJson)
            .toList(growable: false)
        : <SalonService>[];
    final dynamic rawReviews = json['reviews'];
    final List<SalonReview> parsedReviews = rawReviews is List
        ? rawReviews
            .whereType<Map<String, dynamic>>()
            .map(SalonReview.fromJson)
            .where((SalonReview item) {
        return item.serviceId.isNotEmpty && item.comment.isNotEmpty;
      }).toList(growable: false)
        : <SalonReview>[];

    return Salon(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      master: (json['master'] ?? '').toString(),
      rating: _toDouble(json['rating']),
      reviewCount: _toInt(json['reviewCount']),
      address: (json['address'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      distanceKm: _toDouble(json['distanceKm']),
      latitude: _toNullableDouble(json['latitude'] ?? json['lat']),
      longitude: _toNullableDouble(json['longitude'] ?? json['lng']),
      isOpen: json['isOpen'] == true,
      badge: (json['badge'] ?? '').toString(),
      services: parsedServices,
      reviews: parsedReviews,
    );
  }

  int get startingPrice {
    if (services.isEmpty) {
      return 0;
    }

    int minPrice = services.first.price;
    for (final SalonService service in services.skip(1)) {
      if (service.price < minPrice) {
        minPrice = service.price;
      }
    }
    return minPrice;
  }

  List<String> get tags {
    return services
        .map((SalonService service) => service.name)
        .toSet()
        .toList();
  }

  Salon copyWith({
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
    List<SalonService>? services,
    List<SalonReview>? reviews,
  }) {
    return Salon(
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
      services: services ?? this.services,
      reviews: reviews ?? this.reviews,
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

  static double _toDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? 0;
  }

  static double? _toNullableDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value');
  }
}
