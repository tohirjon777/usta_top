import 'salon.dart';
import 'salon_review.dart';

class ReviewStarBucket {
  const ReviewStarBucket({
    required this.stars,
    required this.count,
    required this.share,
  });

  final int stars;
  final int count;
  final double share;
}

class ReviewServiceSummary {
  const ReviewServiceSummary({
    required this.serviceId,
    required this.serviceName,
    required this.reviewCount,
    required this.averageRating,
  });

  final String serviceId;
  final String serviceName;
  final int reviewCount;
  final double averageRating;
}

class ReviewAnalytics {
  const ReviewAnalytics({
    required this.totalReviews,
    required this.averageRating,
    required this.starBuckets,
    required this.topServices,
  });

  final int totalReviews;
  final double averageRating;
  final List<ReviewStarBucket> starBuckets;
  final List<ReviewServiceSummary> topServices;

  factory ReviewAnalytics.fromSalon({
    required List<SalonReview> reviews,
    required List<SalonService> services,
  }) {
    final List<SalonReview> visibleReviews = reviews.toList(growable: false);
    final int totalReviews = visibleReviews.length;
    final double averageRating = totalReviews == 0
        ? 0
        : visibleReviews
                .fold<int>(
                  0,
                  (int sum, SalonReview review) => sum + review.rating,
                ) /
            totalReviews;

    final List<ReviewStarBucket> starBuckets =
        List<ReviewStarBucket>.generate(5, (int index) {
      final int stars = 5 - index;
      final int count = visibleReviews
          .where((SalonReview review) => review.rating == stars)
          .length;
      final double share = totalReviews == 0 ? 0 : count / totalReviews;
      return ReviewStarBucket(
        stars: stars,
        count: count,
        share: share,
      );
    });

    final Map<String, SalonService> servicesById = <String, SalonService>{
      for (final SalonService service in services) service.id: service,
    };
    final Map<String, List<SalonReview>> grouped = <String, List<SalonReview>>{};
    for (final SalonReview review in visibleReviews) {
      grouped.putIfAbsent(review.serviceId, () => <SalonReview>[]).add(review);
    }

    final List<ReviewServiceSummary> topServices = grouped.entries
        .map((MapEntry<String, List<SalonReview>> entry) {
      final List<SalonReview> serviceReviews = entry.value;
      final String fallbackName = serviceReviews.isEmpty
          ? entry.key
          : serviceReviews.first.serviceName;
      final String serviceName =
          servicesById[entry.key]?.name.trim().isNotEmpty == true
              ? servicesById[entry.key]!.name
              : fallbackName;
      final double serviceAverage = serviceReviews.fold<int>(
            0,
            (int sum, SalonReview review) => sum + review.rating,
          ) /
          serviceReviews.length;
      return ReviewServiceSummary(
        serviceId: entry.key,
        serviceName: serviceName,
        reviewCount: serviceReviews.length,
        averageRating: serviceAverage,
      );
    }).toList(growable: false)
      ..sort((ReviewServiceSummary a, ReviewServiceSummary b) {
        final int countCompare = b.reviewCount.compareTo(a.reviewCount);
        if (countCompare != 0) {
          return countCompare;
        }
        final int ratingCompare = b.averageRating.compareTo(a.averageRating);
        if (ratingCompare != 0) {
          return ratingCompare;
        }
        return a.serviceName.compareTo(b.serviceName);
      });

    return ReviewAnalytics(
      totalReviews: totalReviews,
      averageRating: averageRating,
      starBuckets: starBuckets,
      topServices: topServices.take(3).toList(growable: false),
    );
  }
}
