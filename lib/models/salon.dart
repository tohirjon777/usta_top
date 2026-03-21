class SalonService {
  const SalonService({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
  });

  final String id;
  final String name;
  final int price;
  final int durationMinutes;

  factory SalonService.fromJson(Map<String, dynamic> json) {
    // TODO(API): service object quyidagi kalitlarni yuborishi kerak:
    // id, name, price, durationMinutes
    return SalonService(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: _toInt(json['price']),
      durationMinutes: _toInt(json['durationMinutes']),
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
  final bool isOpen;
  final String badge;
  final List<SalonService> services;

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

    return Salon(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      master: (json['master'] ?? '').toString(),
      rating: _toDouble(json['rating']),
      reviewCount: _toInt(json['reviewCount']),
      address: (json['address'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      distanceKm: _toDouble(json['distanceKm']),
      isOpen: json['isOpen'] == true,
      badge: (json['badge'] ?? '').toString(),
      services: parsedServices,
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
}
