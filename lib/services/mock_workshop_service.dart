import '../data/repositories/salon_repository.dart';
import '../models/salon.dart';
import '../models/salon_review.dart';
import 'workshop_service.dart';

class MockWorkshopService implements WorkshopService {
  MockWorkshopService({required SalonRepository repository})
      : _repository = repository {
    for (final Salon salon in _repository.getFeaturedSalons()) {
      _salonsById[salon.id] = salon;
    }
  }

  final SalonRepository _repository;
  final Map<String, Salon> _salonsById = <String, Salon>{};

  @override
  Future<List<Salon>> fetchFeaturedWorkshops() async {
    return _salonsById.values.toList(growable: false);
  }

  @override
  Future<Salon> fetchWorkshopById(String id) async {
    final Salon? salon = _salonsById[id];
    if (salon == null) {
      throw StateError('Servis topilmadi');
    }
    return salon;
  }

  @override
  Future<Salon> submitReview({
    required String workshopId,
    required String serviceId,
    required int rating,
    required String comment,
  }) async {
    final Salon? current = _salonsById[workshopId];
    if (current == null) {
      throw StateError('Servis topilmadi');
    }
    final SalonService service = current.services.firstWhere(
      (SalonService item) => item.id == serviceId,
      orElse: () => throw StateError('Xizmat topilmadi'),
    );

    final SalonReview review = SalonReview(
      id: 'rv-local-${DateTime.now().microsecondsSinceEpoch}',
      workshopId: workshopId,
      serviceId: serviceId,
      serviceName: service.name,
      customerName: 'Tokhirjon',
      rating: rating.clamp(1, 5),
      comment: normalizeSalonReviewText(comment),
      createdAt: DateTime.now(),
    );
    final int nextCount = current.reviewCount + 1;
    final double nextRating = nextCount <= 1
        ? review.rating.toDouble()
        : ((current.rating * current.reviewCount) + review.rating) / nextCount;
    final Salon updated = current.copyWith(
      rating: double.parse(nextRating.toStringAsFixed(1)),
      reviewCount: nextCount,
      reviews: <SalonReview>[review, ...current.reviews],
    );
    _salonsById[workshopId] = updated;
    return updated;
  }
}
