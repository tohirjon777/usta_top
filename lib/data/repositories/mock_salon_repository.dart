import '../../models/salon.dart';
import 'salon_repository.dart';

class MockSalonRepository implements SalonRepository {
  const MockSalonRepository();

  static const List<Salon> _salons = <Salon>[
    Salon(
      id: 'w-1',
      name: 'Turbo Usta Servis',
      master: 'Aziz Usta',
      rating: 4.9,
      reviewCount: 218,
      address: 'Chilonzor, Toshkent',
      description: 'Tez diagnostika va sifatli ta\'mirlash ishlari bir joyda.',
      distanceKm: 1.2,
      isOpen: true,
      badge: 'Eng ishonchli',
      services: <SalonService>[
        SalonService(
          id: 'srv-1',
          name: 'Kompyuter diagnostika',
          price: 120,
          durationMinutes: 35,
        ),
        SalonService(
          id: 'srv-2',
          name: 'Moy va filtr almashtirish',
          price: 90,
          durationMinutes: 30,
        ),
        SalonService(
          id: 'srv-3',
          name: 'Tormoz kolodkasini almashtirish',
          price: 180,
          durationMinutes: 55,
        ),
      ],
    ),
    Salon(
      id: 'w-2',
      name: 'Motor Usta Markazi',
      master: 'Sardor Usta',
      rating: 4.8,
      reviewCount: 167,
      address: 'Yunusobod, Toshkent',
      description:
          'Dvigatel va yurish qismini puxta tekshiruv va kafolatli ta\'mirlash.',
      distanceKm: 2.4,
      isOpen: true,
      badge: 'Tez qabul',
      services: <SalonService>[
        SalonService(
          id: 'srv-4',
          name: 'Dvigatel diagnostikasi',
          price: 140,
          durationMinutes: 45,
        ),
        SalonService(
          id: 'srv-5',
          name: 'Akkumulyator va elektr tizimi tekshiruvi',
          price: 110,
          durationMinutes: 40,
        ),
        SalonService(
          id: 'srv-6',
          name: 'Konditsioner xizmati',
          price: 220,
          durationMinutes: 70,
        ),
      ],
    ),
    Salon(
      id: 'w-3',
      name: 'Usta Mashina Servis',
      master: 'Bekzod Usta',
      rating: 4.7,
      reviewCount: 102,
      address: 'Mirzo Ulugbek, Toshkent',
      description:
          'Murakkab nosozliklarni tajribali ustalar bilan aniq bartaraf etish.',
      distanceKm: 3.1,
      isOpen: false,
      badge: 'Yuqori toifa',
      services: <SalonService>[
        SalonService(
          id: 'srv-7',
          name: 'Kuzov geometriyasi tekshiruvi',
          price: 160,
          durationMinutes: 55,
        ),
        SalonService(
          id: 'srv-8',
          name: 'Yurish qismi ta\'miri',
          price: 130,
          durationMinutes: 50,
        ),
        SalonService(
          id: 'srv-9',
          name: 'To\'liq texnik ko\'rik',
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
      orElse: () => throw StateError('Servis topilmadi. id: $id'),
    );
  }
}
