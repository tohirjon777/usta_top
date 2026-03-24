import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/booking_cancellation_reason.dart';
import '../models/booking_item.dart';
import '../models/salon.dart';
import '../models/vehicle_type.dart';
import '../providers/booking_provider.dart';
import '../providers/workshop_provider.dart';
import '../ui/app_loading_view.dart';
import '../ui/review_composer_sheet.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BookingProvider bookingProvider = context.watch<BookingProvider>();
    final List<BookingItem> bookings = bookingProvider.bookings.toList();
    final bool isLoading = bookingProvider.isLoading;
    final String? errorMessage = bookingProvider.errorMessage;

    if (isLoading && bookings.isEmpty) {
      return const SafeArea(child: AppLoadingView());
    }

    Future<void> openReviewForBooking(BookingItem booking) async {
      final WorkshopProvider workshopProvider = context.read<WorkshopProvider>();
      Salon? salon = workshopProvider.workshopById(booking.workshopId);
      salon ??= await workshopProvider.refreshWorkshopById(booking.workshopId);
      if (!context.mounted) {
        return;
      }
      if (salon == null) {
        final String message =
            workshopProvider.errorMessage ?? l10n.reviewSubmitFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }

      await showWorkshopReviewComposerSheet(
        context: context,
        salon: salon,
        l10n: l10n,
        preselectedServiceId: booking.serviceId,
        bookingId: booking.id,
        lockServiceSelection: true,
        title: l10n.completedReviewTitle,
        subtitle: l10n.completedReviewSubtitle(
          booking.serviceName,
          booking.salonName,
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: bookingProvider.loadBookings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.navBookings,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: isLoading ? null : bookingProvider.loadBookings,
                  icon: const Icon(Icons.refresh),
                  tooltip: l10n.refresh,
                ),
              ],
            ),
            if (errorMessage != null && bookings.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.warning,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            if (bookings.isEmpty)
              _EmptyBookingsState(
                l10n: l10n,
                subtitle: errorMessage ?? l10n.bookingsEmptyHint,
                isError: errorMessage != null,
              )
            else
              ...bookings.map((BookingItem booking) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BookingCard(
                    l10n: l10n,
                    booking: booking,
                    onCancel: () async {
                      final bool changed = await bookingProvider
                          .cancelBookingRequest(booking.id);
                      if (!changed) {
                        if (!context.mounted) {
                          return;
                        }
                        final String message = bookingProvider.errorMessage ??
                            'Buyurtmani bekor qilib bo\'lmadi';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                        return;
                      }
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.bookingCancelled)),
                      );
                    },
                    onWriteReview: booking.status == BookingStatus.completed &&
                            !booking.hasReview
                        ? () {
                            openReviewForBooking(booking);
                          }
                        : null,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.l10n,
    required this.booking,
    required this.onCancel,
    this.onWriteReview,
  });

  final AppLocalizations l10n;
  final BookingItem booking;
  final VoidCallback onCancel;
  final VoidCallback? onWriteReview;

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
            Text(l10n.vehicleModelLabel(booking.vehicleModel)),
            Text(
              l10n.vehicleTypeLabel(
                vehicleTypeById(booking.vehicleTypeId).label(l10n),
              ),
            ),
            Text(l10n.dateLabel(AppFormatters.dateTime(booking.dateTime))),
            const SizedBox(height: 6),
            Text(l10n.basePriceLabel(AppFormatters.moneyK(booking.basePrice))),
            Text(
              l10n.priceLabel(AppFormatters.moneyK(booking.price)),
              style: TextStyle(
                color: AppColors.primaryToneOf(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (booking.status == BookingStatus.cancelled) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                l10n.cancelledByLabel(
                  bookingCancellationActorLabel(booking.cancelledByRole, l10n),
                ),
              ),
              Text(
                l10n.cancellationReasonLabel(
                  bookingCancellationReasonLabel(booking.cancelReasonId, l10n),
                ),
              ),
            ],
            if (booking.status == BookingStatus.upcoming ||
                booking.status == BookingStatus.accepted) ...<Widget>[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(l10n.cancelBooking),
                  ),
                ],
              ),
            ],
            if (booking.status == BookingStatus.completed) ...<Widget>[
              const SizedBox(height: 8),
              if (!booking.hasReview)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: onWriteReview,
                      icon: const Icon(Icons.rate_review_outlined, size: 18),
                      label: Text(l10n.writeReview),
                    ),
                  ],
                )
              else
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: AppColors.primaryToneOf(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.reviewSubmittedLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryToneOf(context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
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
        foreground = AppColors.primaryToneOf(context);
        background = AppColors.primarySoftOf(context);
      case BookingStatus.accepted:
        foreground = AppColors.successForegroundOf(context);
        background = AppColors.successBackgroundOf(context);
      case BookingStatus.completed:
        foreground = AppColors.successForegroundOf(context);
        background = AppColors.successBackgroundOf(context);
      case BookingStatus.cancelled:
        foreground = AppColors.warning;
        background = AppColors.warningBackgroundOf(context);
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
      case BookingStatus.accepted:
        return l10n.statusAccepted;
      case BookingStatus.completed:
        return l10n.statusCompleted;
      case BookingStatus.cancelled:
        return l10n.statusCancelled;
    }
  }
}

class _EmptyBookingsState extends StatelessWidget {
  const _EmptyBookingsState({
    required this.l10n,
    required this.subtitle,
    this.isError = false,
  });

  final AppLocalizations l10n;
  final String subtitle;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isError ? Icons.error_outline : Icons.calendar_month_outlined,
              size: 64,
              color: isError
                  ? AppColors.warning
                  : AppColors.secondaryTextOf(context),
            ),
            const SizedBox(height: 10),
            Text(l10n.noBookingsYet,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isError
                        ? AppColors.warning
                        : AppColors.secondaryTextOf(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
