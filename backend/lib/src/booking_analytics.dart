import 'models.dart';

class BookingAnalyticsSegment {
  const BookingAnalyticsSegment({
    required this.id,
    required this.label,
    required this.bookingCount,
    required this.revenue,
  });

  final String id;
  final String label;
  final int bookingCount;
  final int revenue;
}

class BookingAnalyticsSummary {
  const BookingAnalyticsSummary({
    required this.totalBookings,
    required this.activeBookings,
    required this.scheduledTodayCount,
    required this.createdTodayCount,
    required this.completedRevenue,
    required this.prepaymentCollected,
    required this.topServices,
    required this.topVehicles,
  });

  final int totalBookings;
  final int activeBookings;
  final int scheduledTodayCount;
  final int createdTodayCount;
  final int completedRevenue;
  final int prepaymentCollected;
  final List<BookingAnalyticsSegment> topServices;
  final List<BookingAnalyticsSegment> topVehicles;
}

BookingAnalyticsSummary buildBookingAnalytics(
  Iterable<BookingModel> bookings, {
  DateTime? now,
  int topLimit = 4,
}) {
  final List<BookingModel> items = bookings.toList(growable: false);
  final DateTime localNow = (now ?? DateTime.now()).toLocal();
  final int totalBookings = items.length;
  final int activeBookings = items
      .where((BookingModel item) {
        return item.status == BookingStatus.upcoming ||
            item.status == BookingStatus.accepted ||
            item.status == BookingStatus.rescheduled;
      })
      .length;
  final int scheduledTodayCount = items
      .where((BookingModel item) => _sameDate(item.dateTime.toLocal(), localNow))
      .length;
  final int createdTodayCount = items
      .where((BookingModel item) => _sameDate(item.createdAt.toLocal(), localNow))
      .length;
  final int completedRevenue = items
      .where((BookingModel item) => item.status == BookingStatus.completed)
      .fold<int>(0, (int sum, BookingModel item) => sum + item.price);
  final int prepaymentCollected = items
      .where((BookingModel item) => item.paymentStatus == BookingPaymentStatus.paid)
      .fold<int>(0, (int sum, BookingModel item) => sum + item.prepaymentAmount);

  final List<BookingAnalyticsSegment> topServices = _topSegments(
    items,
    topLimit: topLimit,
    idOf: (BookingModel item) => item.serviceId,
    labelOf: (BookingModel item) => item.serviceName,
  );
  final List<BookingAnalyticsSegment> topVehicles = _topSegments(
    items,
    topLimit: topLimit,
    idOf: (BookingModel item) => item.vehicleModel,
    labelOf: (BookingModel item) => item.vehicleModel,
  );

  return BookingAnalyticsSummary(
    totalBookings: totalBookings,
    activeBookings: activeBookings,
    scheduledTodayCount: scheduledTodayCount,
    createdTodayCount: createdTodayCount,
    completedRevenue: completedRevenue,
    prepaymentCollected: prepaymentCollected,
    topServices: topServices,
    topVehicles: topVehicles,
  );
}

List<BookingAnalyticsSegment> _topSegments(
  Iterable<BookingModel> bookings, {
  required int topLimit,
  required String Function(BookingModel booking) idOf,
  required String Function(BookingModel booking) labelOf,
}) {
  final Map<String, List<BookingModel>> grouped = <String, List<BookingModel>>{};
  for (final BookingModel booking in bookings) {
    final String id = idOf(booking).trim();
    final String label = labelOf(booking).trim();
    if (id.isEmpty || label.isEmpty) {
      continue;
    }
    grouped.putIfAbsent(id, () => <BookingModel>[]).add(booking);
  }

  final List<BookingAnalyticsSegment> segments = grouped.entries
      .map((MapEntry<String, List<BookingModel>> entry) {
        final List<BookingModel> items = entry.value;
        return BookingAnalyticsSegment(
          id: entry.key,
          label: labelOf(items.first).trim(),
          bookingCount: items.length,
          revenue: items.fold<int>(0, (int sum, BookingModel item) => sum + item.price),
        );
      })
      .toList(growable: false)
    ..sort((BookingAnalyticsSegment a, BookingAnalyticsSegment b) {
      final int countCompare = b.bookingCount.compareTo(a.bookingCount);
      if (countCompare != 0) {
        return countCompare;
      }
      final int revenueCompare = b.revenue.compareTo(a.revenue);
      if (revenueCompare != 0) {
        return revenueCompare;
      }
      return a.label.compareTo(b.label);
    });

  return segments.take(topLimit).toList(growable: false);
}

bool _sameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
