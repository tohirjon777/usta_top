import 'models.dart';

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

class ReviewSegmentSummary {
  const ReviewSegmentSummary({
    required this.id,
    required this.label,
    required this.reviewCount,
    required this.averageRating,
  });

  final String id;
  final String label;
  final int reviewCount;
  final double averageRating;
}

class ReviewAnalyticsSummary {
  const ReviewAnalyticsSummary({
    required this.totalReviews,
    required this.averageRating,
    required this.starBuckets,
    required this.topSegments,
  });

  final int totalReviews;
  final double averageRating;
  final List<ReviewStarBucket> starBuckets;
  final List<ReviewSegmentSummary> topSegments;
}

ReviewAnalyticsSummary buildReviewAnalytics(
  Iterable<WorkshopReviewModel> reviews, {
  String Function(WorkshopReviewModel review)? segmentIdOf,
  String Function(WorkshopReviewModel review)? segmentLabelOf,
  int topLimit = 3,
}) {
  final List<WorkshopReviewModel> items = reviews.toList(growable: false);
  final int totalReviews = items.length;
  final double averageRating = totalReviews == 0
      ? 0
      : items.fold<int>(
            0,
            (int sum, WorkshopReviewModel review) => sum + review.rating,
          ) /
          totalReviews;

  final List<ReviewStarBucket> starBuckets =
      List<ReviewStarBucket>.generate(5, (int index) {
    final int stars = 5 - index;
    final int count = items
        .where((WorkshopReviewModel review) => review.rating == stars)
        .length;
    return ReviewStarBucket(
      stars: stars,
      count: count,
      share: totalReviews == 0 ? 0 : count / totalReviews,
    );
  });

  final String Function(WorkshopReviewModel) effectiveSegmentIdOf =
      segmentIdOf ?? (WorkshopReviewModel review) => review.serviceId;
  final String Function(WorkshopReviewModel) effectiveSegmentLabelOf =
      segmentLabelOf ?? (WorkshopReviewModel review) => review.serviceName;

  final Map<String, List<WorkshopReviewModel>> grouped =
      <String, List<WorkshopReviewModel>>{};
  for (final WorkshopReviewModel review in items) {
    grouped
        .putIfAbsent(effectiveSegmentIdOf(review), () => <WorkshopReviewModel>[])
        .add(review);
  }

  final List<ReviewSegmentSummary> topSegments = grouped.entries
      .map((MapEntry<String, List<WorkshopReviewModel>> entry) {
    final List<WorkshopReviewModel> segmentReviews = entry.value;
    final double segmentAverage = segmentReviews.fold<int>(
          0,
          (int sum, WorkshopReviewModel review) => sum + review.rating,
        ) /
        segmentReviews.length;
    return ReviewSegmentSummary(
      id: entry.key,
      label: effectiveSegmentLabelOf(segmentReviews.first),
      reviewCount: segmentReviews.length,
      averageRating: segmentAverage,
    );
  }).toList(growable: false)
    ..sort((ReviewSegmentSummary a, ReviewSegmentSummary b) {
      final int countCompare = b.reviewCount.compareTo(a.reviewCount);
      if (countCompare != 0) {
        return countCompare;
      }
      final int ratingCompare = b.averageRating.compareTo(a.averageRating);
      if (ratingCompare != 0) {
        return ratingCompare;
      }
      return a.label.compareTo(b.label);
    });

  return ReviewAnalyticsSummary(
    totalReviews: totalReviews,
    averageRating: averageRating,
    starBuckets: starBuckets,
    topSegments: topSegments.take(topLimit).toList(growable: false),
  );
}
