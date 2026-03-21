import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/booking_item.dart';
import '../models/salon.dart';
import 'booking_screen.dart';

class SalonDetailScreen extends StatelessWidget {
  const SalonDetailScreen({super.key, required this.salon});

  final Salon salon;

  Future<void> _openBooking(
    BuildContext context, {
    SalonService? preselected,
  }) async {
    final BookingItem? booking = await Navigator.of(context).push<BookingItem>(
      MaterialPageRoute<BookingItem>(
        builder: (_) => BookingScreen(
          salon: salon,
          preselectedServiceId: preselected?.id,
        ),
      ),
    );

    if (!context.mounted || booking == null) {
      return;
    }

    Navigator.of(context).pop(booking);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Color heroStart = AppColors.primarySoftOf(context);
    final Color heroEnd = AppColors.accentSoftOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(salon.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: <Widget>[
          Container(
            height: 190,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[heroStart, heroEnd],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(
                Icons.car_repair,
                size: 80,
                color: AppColors.primaryToneOf(context),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(salon.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            salon.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryTextOf(context),
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _MetaPill(
                  icon: Icons.star,
                  text: '${salon.rating} (${salon.reviewCount})'),
              _MetaPill(
                  icon: Icons.place_outlined, text: '${salon.distanceKm} km'),
              _MetaPill(
                icon: Icons.circle,
                text: salon.isOpen ? l10n.openNow : l10n.closedNow,
                color: salon.isOpen
                    ? AppColors.primaryToneOf(context)
                    : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 4),
              Expanded(child: Text(salon.address)),
            ],
          ),
          const SizedBox(height: 20),
          Text(l10n.services, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...salon.services.map(
            (SalonService service) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              service.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.durationMinutes(service.durationMinutes),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.secondaryTextOf(context),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        AppFormatters.moneyK(service.price),
                        style: TextStyle(
                          color: AppColors.primaryToneOf(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () =>
                            _openBooking(context, preselected: service),
                        child: Text(l10n.book),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: salon.isOpen ? () => _openBooking(context) : null,
            child: Text(
              salon.isOpen
                  ? l10n.bookNowFrom(
                      AppFormatters.moneyK(salon.startingPrice),
                    )
                  : l10n.currentlyClosed,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chipBackgroundOf(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color ?? AppColors.starOf(context)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color ?? AppColors.secondaryTextOf(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
