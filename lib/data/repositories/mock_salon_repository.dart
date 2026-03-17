import '../../models/salon.dart';
import 'salon_repository.dart';

class MockSalonRepository implements SalonRepository {
  const MockSalonRepository();

  static const List<Salon> _salons = <Salon>[
    Salon(
      id: 's-1',
      name: 'Prime Barber House',
      master: 'Aziz',
      rating: 4.9,
      reviewCount: 218,
      address: 'Chilonzor, Tashkent',
      description:
          'High precision fades, clean beard styling, and fast professional service.',
      distanceKm: 1.2,
      isOpen: true,
      badge: 'Top Rated',
      services: <SalonService>[
        SalonService(
            id: 'srv-1', name: 'Haircut', price: 120, durationMinutes: 45),
        SalonService(
            id: 'srv-2', name: 'Beard Trim', price: 90, durationMinutes: 30),
        SalonService(
          id: 'srv-3',
          name: 'Hair + Beard Combo',
          price: 180,
          durationMinutes: 60,
        ),
      ],
    ),
    Salon(
      id: 's-2',
      name: 'Urban Style Studio',
      master: 'Sardor',
      rating: 4.8,
      reviewCount: 167,
      address: 'Yunusobod, Tashkent',
      description:
          'Modern men grooming with premium styling and personalized recommendations.',
      distanceKm: 2.4,
      isOpen: true,
      badge: 'Fast Booking',
      services: <SalonService>[
        SalonService(
            id: 'srv-4', name: 'Haircut', price: 140, durationMinutes: 50),
        SalonService(
            id: 'srv-5', name: 'Styling', price: 110, durationMinutes: 35),
        SalonService(
            id: 'srv-6', name: 'Coloring', price: 220, durationMinutes: 75),
      ],
    ),
    Salon(
      id: 's-3',
      name: 'Gentlemen Club',
      master: 'Bekzod',
      rating: 4.7,
      reviewCount: 102,
      address: 'Mirzo Ulugbek, Tashkent',
      description:
          'Comfort-first lounge style barbershop focused on quality and consistency.',
      distanceKm: 3.1,
      isOpen: false,
      badge: 'Premium',
      services: <SalonService>[
        SalonService(
            id: 'srv-7', name: 'Haircut', price: 160, durationMinutes: 55),
        SalonService(
            id: 'srv-8', name: 'Face Care', price: 130, durationMinutes: 40),
        SalonService(
          id: 'srv-9',
          name: 'Hair + Face Care',
          price: 240,
          durationMinutes: 85,
        ),
      ],
    ),
  ];

  @override
  List<Salon> getFeaturedSalons() => _salons;

  @override
  Salon getById(String id) {
    return _salons.firstWhere(
      (Salon salon) => salon.id == id,
      orElse: () => throw StateError('Salon not found for id: $id'),
    );
  }
}
