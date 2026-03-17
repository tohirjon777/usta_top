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
}
