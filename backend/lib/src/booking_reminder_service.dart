import 'dart:io';

import 'models.dart';
import 'store.dart';
import 'user_notifications.dart';
import 'workshop_notifications.dart';

class BookingReminderSyncResult {
  const BookingReminderSyncResult({
    required this.customerSent,
    required this.workshopSent,
  });

  final int customerSent;
  final int workshopSent;

  int get totalSent => customerSent + workshopSent;
}

class BookingReminderService {
  const BookingReminderService(
    this._store, {
    required this.bookingsFilePath,
    required this.userNotificationsService,
    required this.workshopNotificationsService,
    required this.customerLeadTime,
    required this.workshopLeadTime,
  });

  final InMemoryStore _store;
  final String bookingsFilePath;
  final UserNotificationsService userNotificationsService;
  final WorkshopNotificationsService workshopNotificationsService;
  final Duration customerLeadTime;
  final Duration workshopLeadTime;

  bool get hasAnyChannelConfigured =>
      userNotificationsService.isConfigured ||
      workshopNotificationsService.isConfigured;

  Future<BookingReminderSyncResult> sendDueReminders() async {
    if (!hasAnyChannelConfigured) {
      return const BookingReminderSyncResult(customerSent: 0, workshopSent: 0);
    }

    bool didPersist = false;
    int customerSent = 0;
    int workshopSent = 0;

    if (userNotificationsService.isConfigured) {
      final List<BookingModel> customerDue = _store
          .bookingsAwaitingCustomerReminder(leadTime: customerLeadTime);
      for (final BookingModel booking in customerDue) {
        final UserModel? user = _store.userById(booking.userId);
        final WorkshopModel? workshop = _store.workshopById(booking.workshopId);
        if (user == null || workshop == null) {
          continue;
        }
        if (user.pushTokens.every((PushTokenModel item) => item.token.trim().isEmpty)) {
          continue;
        }

        try {
          await userNotificationsService.sendUpcomingBookingReminderNotification(
            user: user,
            booking: booking,
            workshop: workshop,
            leadTime: customerLeadTime,
          );
          _store.markCustomerBookingReminderSent(booking.id);
          didPersist = true;
          customerSent += 1;
        } on Exception catch (error) {
          stderr.writeln('Customer booking reminder yuborilmadi (${booking.id}): $error');
        }
      }
    }

    if (workshopNotificationsService.isConfigured) {
      final List<BookingModel> workshopDue = _store
          .bookingsAwaitingWorkshopReminder(leadTime: workshopLeadTime);
      for (final BookingModel booking in workshopDue) {
        final WorkshopModel? workshop = _store.workshopById(booking.workshopId);
        if (workshop == null || workshop.telegramChatId.trim().isEmpty) {
          continue;
        }

        try {
          await workshopNotificationsService.sendUpcomingBookingReminder(
            workshop: workshop,
            booking: booking,
            leadTime: workshopLeadTime,
          );
          _store.markWorkshopBookingReminderSent(booking.id);
          didPersist = true;
          workshopSent += 1;
        } on Exception catch (error) {
          stderr.writeln('Workshop booking reminder yuborilmadi (${booking.id}): $error');
        }
      }
    }

    if (didPersist) {
      await _store.saveBookings(bookingsFilePath);
    }

    return BookingReminderSyncResult(
      customerSent: customerSent,
      workshopSent: workshopSent,
    );
  }
}
