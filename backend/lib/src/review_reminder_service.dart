import 'dart:io';

import 'models.dart';
import 'store.dart';
import 'user_notifications.dart';

class ReviewReminderService {
  const ReviewReminderService(
    this._store, {
    required this.bookingsFilePath,
    required this.userNotificationsService,
    required this.reminderDelay,
  });

  final InMemoryStore _store;
  final String bookingsFilePath;
  final UserNotificationsService userNotificationsService;
  final Duration reminderDelay;

  bool get isConfigured => userNotificationsService.isConfigured;

  Future<int> sendDueReminders() async {
    if (!isConfigured) {
      return 0;
    }

    final List<BookingModel> dueBookings = _store.bookingsAwaitingReviewReminder(
      delay: reminderDelay,
    );
    if (dueBookings.isEmpty) {
      return 0;
    }

    bool didPersist = false;
    int sentCount = 0;
    for (final BookingModel booking in dueBookings) {
      final UserModel? user = _store.userById(booking.userId);
      final WorkshopModel? workshop = _store.workshopById(booking.workshopId);
      if (user == null ||
          workshop == null ||
          user.pushTokens.every((PushTokenModel item) => item.token.trim().isEmpty)) {
        continue;
      }

      try {
        await userNotificationsService.sendReviewReminderNotification(
          user: user,
          booking: booking,
          workshop: workshop,
        );
        _store.markReviewReminderSent(booking.id);
        didPersist = true;
        sentCount += 1;
      } on Exception catch (error) {
        stderr.writeln('Review reminder yuborilmadi (${booking.id}): $error');
      }
    }

    if (didPersist) {
      await _store.saveBookings(bookingsFilePath);
    }
    return sentCount;
  }
}
