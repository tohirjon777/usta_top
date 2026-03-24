import '../models/salon.dart';

abstract interface class WorkshopService {
  Future<List<Salon>> fetchFeaturedWorkshops();

  Future<Salon> fetchWorkshopById(String id);

  Future<Salon> submitReview({
    required String workshopId,
    required String serviceId,
    required int rating,
    required String comment,
  });
}
