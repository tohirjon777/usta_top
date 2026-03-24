import 'package:flutter_test/flutter_test.dart';
import 'package:usta_top/models/review_analytics.dart';
import 'package:usta_top/models/salon.dart';
import 'package:usta_top/models/salon_review.dart';

void main() {
  test('review analytics summarizes stars and top services', () {
    final ReviewAnalytics analytics = ReviewAnalytics.fromSalon(
      reviews: <SalonReview>[
        SalonReview(
          id: 'r-1',
          workshopId: 'w-1',
          serviceId: 'srv-1',
          serviceName: 'Diagnostika',
          customerName: 'Ali',
          rating: 5,
          comment: 'Zo‘r',
          createdAt: DateTime(2026, 3, 24, 10),
        ),
        SalonReview(
          id: 'r-2',
          workshopId: 'w-1',
          serviceId: 'srv-1',
          serviceName: 'Diagnostika',
          customerName: 'Vali',
          rating: 4,
          comment: 'Yaxshi',
          createdAt: DateTime(2026, 3, 24, 11),
        ),
        SalonReview(
          id: 'r-3',
          workshopId: 'w-1',
          serviceId: 'srv-2',
          serviceName: 'Moy almashtirish',
          customerName: 'Sardor',
          rating: 5,
          comment: 'Tez bajarildi',
          createdAt: DateTime(2026, 3, 24, 12),
        ),
      ],
      services: const <SalonService>[
        SalonService(
          id: 'srv-1',
          name: 'Diagnostika',
          price: 120,
          durationMinutes: 30,
        ),
        SalonService(
          id: 'srv-2',
          name: 'Moy almashtirish',
          price: 90,
          durationMinutes: 40,
        ),
      ],
    );

    expect(analytics.totalReviews, 3);
    expect(analytics.averageRating, closeTo(4.67, 0.01));
    expect(
      analytics.starBuckets.firstWhere((ReviewStarBucket item) => item.stars == 5).count,
      2,
    );
    expect(
      analytics.topServices.first.serviceName,
      'Diagnostika',
    );
    expect(
      analytics.topServices.first.averageRating,
      closeTo(4.5, 0.01),
    );
  });
}
