import '../data/repositories/salon_repository.dart';
import '../models/salon.dart';
import 'workshop_service.dart';

class MockWorkshopService implements WorkshopService {
  const MockWorkshopService({required SalonRepository repository})
      : _repository = repository;

  final SalonRepository _repository;

  @override
  Future<List<Salon>> fetchFeaturedWorkshops() async {
    return _repository.getFeaturedSalons();
  }

  @override
  Future<Salon> fetchWorkshopById(String id) async {
    return _repository.getById(id);
  }
}
