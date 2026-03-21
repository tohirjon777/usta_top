import '../models/salon.dart';

abstract interface class WorkshopService {
  Future<List<Salon>> fetchFeaturedWorkshops();

  Future<Salon> fetchWorkshopById(String id);
}
