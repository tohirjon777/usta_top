import '../../models/salon.dart';

abstract interface class SalonRepository {
  List<Salon> getFeaturedSalons();

  Salon getById(String id);
}
