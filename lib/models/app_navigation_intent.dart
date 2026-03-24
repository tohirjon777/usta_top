enum AppNavigationTarget { bookings, workshopReview, workshopReviewComposer }

class AppNavigationIntent {
  const AppNavigationIntent.bookings()
      : target = AppNavigationTarget.bookings,
        workshopId = '',
        serviceId = '',
        reviewId = '',
        bookingId = '';

  const AppNavigationIntent.workshopReview({
    required this.workshopId,
    this.serviceId = '',
    this.reviewId = '',
  })  : target = AppNavigationTarget.workshopReview,
        bookingId = '';

  const AppNavigationIntent.workshopReviewComposer({
    required this.workshopId,
    required this.serviceId,
    required this.bookingId,
  })  : target = AppNavigationTarget.workshopReviewComposer,
        reviewId = '';

  final AppNavigationTarget target;
  final String workshopId;
  final String serviceId;
  final String reviewId;
  final String bookingId;

  static AppNavigationIntent? fromPushData(Map<String, dynamic> data) {
    final String type = (data['type'] ?? '').toString().trim();
    final String screen = (data['screen'] ?? '').toString().trim();
    final String workshopId = (data['workshopId'] ?? '').toString().trim();
    final String serviceId = (data['serviceId'] ?? '').toString().trim();
    final String reviewId = (data['reviewId'] ?? '').toString().trim();
    final String bookingId = (data['bookingId'] ?? '').toString().trim();

    if (screen == 'bookings' || type == 'booking_status') {
      return const AppNavigationIntent.bookings();
    }
    if ((type == 'review_reminder' || screen == 'workshop_review') &&
        workshopId.isNotEmpty &&
        serviceId.isNotEmpty &&
        bookingId.isNotEmpty) {
      return AppNavigationIntent.workshopReviewComposer(
        workshopId: workshopId,
        serviceId: serviceId,
        bookingId: bookingId,
      );
    }
    if ((type == 'workshop_review_reply' || screen == 'workshop') &&
        workshopId.isNotEmpty) {
      return AppNavigationIntent.workshopReview(
        workshopId: workshopId,
        serviceId: serviceId,
        reviewId: reviewId,
      );
    }
    return null;
  }
}
