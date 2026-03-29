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
import '../ui/booking_reschedule_sheet.dart';
import '../ui/review_composer_sheet.dart';
import '../widgets/app_reveal.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BookingProvider bookingProvider = context.watch<BookingProvider>();
    final List<BookingItem> bookings = bookingProvider.bookings.toList();
    final bool isLoading = bookingProvider.isLoading;
    final String? errorMessage = bookingProvider.errorMessage;
    final int activeCount = bookings
        .where(
          (BookingItem item) =>
              item.status == BookingStatus.upcoming ||
              item.status == BookingStatus.accepted ||
              item.status == BookingStatus.rescheduled,
        )
        .length;
    final int completedCount = bookings
        .where((BookingItem item) => item.status == BookingStatus.completed)
        .length;

    if (isLoading && bookings.isEmpty) {
      return const SafeArea(child: AppLoadingView());
    }

    Future<void> openReviewForBooking(BookingItem booking) async {
      final WorkshopProvider workshopProvider =
          context.read<WorkshopProvider>();
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

    Future<void> openRescheduleForBooking(BookingItem booking) async {
      final bool? changed = await showBookingRescheduleSheet(
        context: context,
        booking: booking,
      );
      if (!context.mounted || changed != true) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bookingRescheduled)),
      );
    }

    Future<void> acceptRescheduledBooking(BookingItem booking) async {
      final bool changed = await bookingProvider.acceptRescheduledBookingRequest(
        booking.id,
      );
      if (!context.mounted) {
        return;
      }
      if (!changed) {
        final String message =
            bookingProvider.errorMessage ?? l10n.acceptRescheduledFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.acceptRescheduledSuccess)),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: bookingProvider.loadBookings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            AppReveal(
              child: _BookingsHeroCard(
                l10n: l10n,
                title: l10n.navBookings,
                subtitle: l10n.bookingHistorySubtitle,
                totalCount: bookings.length,
                activeCount: activeCount,
                completedCount: completedCount,
                onRefresh: isLoading ? null : bookingProvider.loadBookings,
                refreshTooltip: l10n.refresh,
              ),
            ),
            if (errorMessage != null && bookings.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.warning,
                ),
              ),
            ],
            const SizedBox(height: 18),
            AppReveal(
              delay: const Duration(milliseconds: 90),
              child: _BookingsSectionHeader(
                title: l10n.bookingHistory,
                subtitle:
                    bookings.isEmpty ? l10n.bookingsEmptyHint : '${bookings.length}',
              ),
            ),
            const SizedBox(height: 12),
            if (bookings.isEmpty)
              AppReveal(
                delay: const Duration(milliseconds: 150),
                child: _EmptyBookingsState(
                  l10n: l10n,
                  subtitle: errorMessage ?? l10n.bookingsEmptyHint,
                  isError: errorMessage != null,
                ),
              )
            else
              ...bookings.map((BookingItem booking) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AppReveal(
                    delay: Duration(milliseconds: 150 + (bookings.indexOf(booking) * 45)),
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
                      onReschedule: () {
                        openRescheduleForBooking(booking);
                      },
                      onAcceptRescheduled:
                          booking.status == BookingStatus.rescheduled &&
                                  booking.rescheduledByRole != 'customer'
                              ? () {
                                  acceptRescheduledBooking(booking);
                                }
                              : null,
                      onWriteReview: booking.status == BookingStatus.completed &&
                              !booking.hasReview
                          ? () {
                              openReviewForBooking(booking);
                            }
                          : null,
                    ),
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
    required this.onReschedule,
    this.onAcceptRescheduled,
    this.onWriteReview,
  });

  final AppLocalizations l10n;
  final BookingItem booking;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;
  final VoidCallback? onAcceptRescheduled;
  final VoidCallback? onWriteReview;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoftOf(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.directions_car_filled_rounded,
                    color: AppColors.primaryToneOf(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        booking.salonName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.serviceName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryTextOf(context),
                            ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(l10n: l10n, status: booking.status),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _BookingInfoPill(
                  icon: Icons.person_outline_rounded,
                  text: l10n.masterPrefix(booking.masterName),
                ),
                _BookingInfoPill(
                  icon: Icons.calendar_today_outlined,
                  text: l10n.dateLabel(AppFormatters.dateTime(booking.dateTime)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.vehicleModelLabel(booking.vehicleModel)),
            Text(
              l10n.vehicleTypeLabel(
                vehicleTypeById(booking.vehicleTypeId).label(l10n),
              ),
            ),
            if (booking.status == BookingStatus.rescheduled &&
                booking.previousDateTime != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.rescheduledFromLabel(
                      AppFormatters.dateTime(booking.previousDateTime!),
                    ),
                  ),
                  if (booking.rescheduledByRole.isNotEmpty)
                    Text(
                      l10n.rescheduledByLabel(
                        bookingRescheduleActorLabel(
                          booking.rescheduledByRole,
                          l10n,
                        ),
                      ),
                    ),
                  if (booking.rescheduledAt != null)
                    Text(
                      l10n.rescheduledAtLabel(
                        AppFormatters.dateTime(booking.rescheduledAt!),
                      ),
                    ),
                ],
              ),
            if (booking.acceptedAt != null &&
                booking.status != BookingStatus.upcoming)
              Text(
                l10n.acceptedAtLabel(
                  AppFormatters.dateTime(booking.acceptedAt!),
                ),
              ),
            const SizedBox(height: 6),
            Text(l10n.basePriceLabel(AppFormatters.moneyK(booking.basePrice))),
            Text(
              l10n.priceLabel(AppFormatters.moneyK(booking.price)),
              style: TextStyle(
                color: AppColors.primaryToneOf(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (booking.prepaymentAmount > 0)
              Text(
                booking.paymentStatus == BookingPaymentStatus.paid
                    ? l10n.prepaymentPaidLabel(
                        AppFormatters.moneyK(booking.prepaymentAmount),
                      )
                    : l10n.prepaymentAmountLabel(
                        AppFormatters.moneyK(booking.prepaymentAmount),
                      ),
              ),
            if (booking.prepaymentAmount > 0)
              Text(
                l10n.remainingPaymentLabel(
                  AppFormatters.moneyK(booking.remainingAmount),
                ),
              ),
            Text(
              l10n.paymentStatusLabel(
                _paymentStatusText(booking.paymentStatus),
              ),
            ),
            if (booking.paymentMethod.isNotEmpty)
              Text(
                l10n.paymentMethodValueLabel(
                  _paymentMethodText(booking.paymentMethod),
                ),
              ),
            if (booking.status == BookingStatus.cancelled) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                l10n.cancelledByLabel(
                  bookingCancellationActorLabel(booking.cancelledByRole, l10n),
                ),
              ),
              if (booking.cancelledAt != null)
                Text(
                  l10n.cancelledAtLabel(
                    AppFormatters.dateTime(booking.cancelledAt!),
                  ),
                ),
              Text(
                l10n.cancellationReasonLabel(
                  bookingCancellationReasonLabel(booking.cancelReasonId, l10n),
                ),
              ),
            ],
            if (booking.status == BookingStatus.completed &&
                booking.completedAt != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                l10n.completedAtLabel(
                  AppFormatters.dateTime(booking.completedAt!),
                ),
              ),
            ],
            if (booking.status == BookingStatus.upcoming ||
                booking.status == BookingStatus.rescheduled ||
                booking.status == BookingStatus.accepted) ...<Widget>[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (onAcceptRescheduled != null)
                    TextButton.icon(
                      onPressed: onAcceptRescheduled,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(l10n.acceptRescheduledBooking),
                    ),
                  TextButton.icon(
                    onPressed: onReschedule,
                    icon: const Icon(Icons.schedule_outlined, size: 18),
                    label: Text(l10n.rescheduleBooking),
                  ),
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

  String _paymentStatusText(BookingPaymentStatus status) {
    switch (status) {
      case BookingPaymentStatus.pending:
        return l10n.paymentStatusPending;
      case BookingPaymentStatus.paid:
        return l10n.paymentStatusPaid;
      case BookingPaymentStatus.refunded:
        return l10n.paymentStatusRefunded;
      case BookingPaymentStatus.notRequired:
        return l10n.paymentStatusNotRequired;
    }
  }

  String _paymentMethodText(String method) {
    switch (method.trim()) {
      case 'cash':
        return l10n.paymentMethodCash;
      case 'test_card':
        return l10n.paymentMethodTestCard;
      case 'click':
      case 'payme':
      case 'uzum':
      case 'bank_card':
        return l10n.paymentMethodTestCard;
      default:
        return l10n.paymentMethodBankCard;
    }
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
      case BookingStatus.rescheduled:
        foreground = AppColors.accentOf(context);
        background = AppColors.primarySoftOf(context);
      case BookingStatus.accepted:
        foreground = AppColors.accentOf(context);
        background = AppColors.accentSoftOf(context);
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
      case BookingStatus.rescheduled:
        return l10n.statusRescheduled;
      case BookingStatus.accepted:
        return l10n.statusAccepted;
      case BookingStatus.completed:
        return l10n.statusCompleted;
      case BookingStatus.cancelled:
        return l10n.statusCancelled;
    }
  }
}

class _BookingsHeroCard extends StatelessWidget {
  const _BookingsHeroCard({
    required this.l10n,
    required this.title,
    required this.subtitle,
    required this.totalCount,
    required this.activeCount,
    required this.completedCount,
    required this.refreshTooltip,
    this.onRefresh,
  });

  final AppLocalizations l10n;
  final String title;
  final String subtitle;
  final int totalCount;
  final int activeCount;
  final int completedCount;
  final String refreshTooltip;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.primarySoftOf(context),
            AppColors.accentSoftOf(context),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondaryTextOf(context),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                tooltip: refreshTooltip,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _BookingsMetricTile(
                  icon: Icons.receipt_long_rounded,
                  label: l10n.totalBookings,
                  value: '$totalCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BookingsMetricTile(
                  icon: Icons.schedule_rounded,
                  label: l10n.upcoming,
                  value: '$activeCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BookingsMetricTile(
                  icon: Icons.check_circle_outline_rounded,
                  label: l10n.completedMetricLabel,
                  value: '$completedCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingsMetricTile extends StatelessWidget {
  const _BookingsMetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.primaryToneOf(context)),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryTextOf(context),
                ),
          ),
        ],
      ),
    );
  }
}

class _BookingsSectionHeader extends StatelessWidget {
  const _BookingsSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryTextOf(context),
              ),
        ),
      ],
    );
  }
}

class _BookingInfoPill extends StatelessWidget {
  const _BookingInfoPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.chipBackgroundOf(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: AppColors.primaryToneOf(context)),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
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
