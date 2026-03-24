import 'package:flutter_test/flutter_test.dart';
import 'package:usta_top/models/app_navigation_intent.dart';

void main() {
  test('parses review reminder push into composer intent', () {
    final AppNavigationIntent? intent =
        AppNavigationIntent.fromPushData(<String, dynamic>{
      'type': 'review_reminder',
      'screen': 'workshop_review',
      'workshopId': 'w-1',
      'serviceId': 'srv-2',
      'bookingId': 'b-42',
    });

    expect(intent, isNotNull);
    expect(intent!.target, AppNavigationTarget.workshopReviewComposer);
    expect(intent.workshopId, 'w-1');
    expect(intent.serviceId, 'srv-2');
    expect(intent.bookingId, 'b-42');
  });

  test('parses review reply push into workshop review intent', () {
    final AppNavigationIntent? intent =
        AppNavigationIntent.fromPushData(<String, dynamic>{
      'type': 'workshop_review_reply',
      'screen': 'workshop',
      'workshopId': 'w-9',
      'serviceId': 'srv-7',
      'reviewId': 'rv-11',
    });

    expect(intent, isNotNull);
    expect(intent!.target, AppNavigationTarget.workshopReview);
    expect(intent.workshopId, 'w-9');
    expect(intent.serviceId, 'srv-7');
    expect(intent.reviewId, 'rv-11');
  });
}
