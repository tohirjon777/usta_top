import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/booking_item.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({
    super.key,
    required this.bookings,
    required this.onCancel,
  });

  final List<BookingItem> bookings;
  final ValueChanged<String> onCancel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    if (bookings.isEmpty) {
      return SafeArea(child: _EmptyBookingsState(l10n: l10n));
    }

    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: bookings.length,
        itemBuilder: (BuildContext context, int index) {
          final BookingItem booking = bookings[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BookingCard(
              l10n: l10n,
              booking: booking,
              onCancel: () => onCancel(booking.id),
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.l10n,
    required this.booking,
    required this.onCancel,
  });

  final AppLocalizations l10n;
  final BookingItem booking;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    booking.salonName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusBadge(l10n: l10n, status: booking.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.masterPrefix(booking.masterName)),
            Text(l10n.serviceLabel(booking.serviceName)),
            Text(l10n.dateLabel(AppFormatters.dateTime(booking.dateTime))),
            const SizedBox(height: 6),
            Text(
              l10n.priceLabel(AppFormatters.moneyK(booking.price)),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (booking.status == BookingStatus.upcoming) ...<Widget>[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close, size: 18),
                label: Text(l10n.cancelBooking),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.l10n, required this.status});

  final AppLocalizations l10n;
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color foreground;
    late final Color background;

    switch (status) {
      case BookingStatus.upcoming:
        foreground = AppColors.primary;
        background = AppColors.primarySoft;
      case BookingStatus.completed:
        foreground = const Color(0xFF2E7D32);
        background = const Color(0xFFE8F5E9);
      case BookingStatus.cancelled:
        foreground = AppColors.warning;
        background = const Color(0xFFFFEBEE);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _statusText(status),
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _statusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return l10n.statusUpcoming;
      case BookingStatus.completed:
        return l10n.statusCompleted;
      case BookingStatus.cancelled:
        return l10n.statusCancelled;
    }
  }
}

class _EmptyBookingsState extends StatelessWidget {
  const _EmptyBookingsState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.calendar_month_outlined,
              size: 64,
              color: AppColors.secondaryText,
            ),
            const SizedBox(height: 10),
            Text(l10n.noBookingsYet,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              l10n.bookingsEmptyHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
