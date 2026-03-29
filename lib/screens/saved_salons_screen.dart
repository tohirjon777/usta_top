import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/salon.dart';
import '../providers/saved_workshops_provider.dart';
import '../providers/workshop_provider.dart';
import '../ui/app_loading_view.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_reveal.dart';
import '../widgets/workshop_image_view.dart';

class SavedSalonsScreen extends StatelessWidget {
  const SavedSalonsScreen({
    super.key,
    required this.onOpenSalon,
  });

  final Future<void> Function(Salon salon) onOpenSalon;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final WorkshopProvider workshopProvider = context.watch<WorkshopProvider>();
    final SavedWorkshopsProvider savedProvider =
        context.watch<SavedWorkshopsProvider>();
    final List<Salon> allWorkshops = workshopProvider.allWorkshops;
    final List<String> savedIds = savedProvider.savedIds;
    final List<Salon> savedSalons = allWorkshops
        .where((Salon salon) => savedIds.contains(salon.id))
        .toList(growable: false);
    final int openCount =
        savedSalons.where((Salon salon) => salon.isOpen).length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.savedWorkshopsTitle)),
      body: SafeArea(
        child: Builder(
          builder: (BuildContext context) {
            if (workshopProvider.isLoading && allWorkshops.isEmpty) {
              return const AppLoadingView();
            }

            if (savedIds.isEmpty) {
              return AppEmptyState(
                icon: Icons.favorite_border,
                title: l10n.savedWorkshopsEmptyTitle,
                subtitle: l10n.savedWorkshopsEmptyHint,
              );
            }

            if (savedSalons.isEmpty) {
              return AppEmptyState(
                icon: Icons.error_outline,
                title: l10n.noSalonsFound,
                subtitle:
                    workshopProvider.errorMessage ?? l10n.tryDifferentSearch,
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: <Widget>[
                AppReveal(
                  child: _SavedHeroCard(
                    l10n: l10n,
                    title: l10n.savedWorkshopsTitle,
                    subtitle: l10n.savedWorkshopsEmptyHint,
                    savedCount: savedSalons.length,
                    openCount: openCount,
                  ),
                ),
                const SizedBox(height: 18),
                ...savedSalons.asMap().entries.map(
                  (MapEntry<int, Salon> entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AppReveal(
                      delay: Duration(milliseconds: 90 + (entry.key * 50)),
                      child: _SavedWorkshopCard(
                        salon: entry.value,
                        l10n: l10n,
                        onTap: () => onOpenSalon(entry.value),
                        onToggleSaved: () =>
                            _toggleSaved(context, salon: entry.value),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _toggleSaved(
    BuildContext context, {
    required Salon salon,
  }) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SavedWorkshopsProvider savedProvider =
        context.read<SavedWorkshopsProvider>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      final bool saved = await savedProvider.toggleSaved(salon.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? l10n.savedWorkshopAdded(salon.name)
                : l10n.savedWorkshopRemoved(salon.name),
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.savedWorkshopUpdateFailed)),
      );
    }
  }
}

class _SavedHeroCard extends StatelessWidget {
  const _SavedHeroCard({
    required this.l10n,
    required this.title,
    required this.subtitle,
    required this.savedCount,
    required this.openCount,
  });

  final AppLocalizations l10n;
  final String title;
  final String subtitle;
  final int savedCount;
  final int openCount;

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
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _SavedMetricTile(
                  icon: Icons.favorite_rounded,
                  label: l10n.savedSalons,
                  value: '$savedCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SavedMetricTile(
                  icon: Icons.flash_on_rounded,
                  label: l10n.openNow,
                  value: '$openCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedMetricTile extends StatelessWidget {
  const _SavedMetricTile({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.primaryToneOf(context)),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

class _SavedWorkshopCard extends StatelessWidget {
  const _SavedWorkshopCard({
    required this.salon,
    required this.l10n,
    required this.onTap,
    required this.onToggleSaved,
  });

  final Salon salon;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  WorkshopImageView(
                    imageUrl: salon.imageUrl,
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(16),
                    fallbackIcon: Icons.garage_rounded,
                    iconSize: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          salon.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          salon.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.secondaryTextOf(context),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.removeSavedWorkshop,
                    onPressed: onToggleSaved,
                    icon: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _SavedInfoPill(
                    icon: Icons.star_rounded,
                    text: '${salon.rating.toStringAsFixed(1)} • ${salon.reviewCount}',
                  ),
                  _SavedInfoPill(
                    icon: Icons.route_rounded,
                    text: '${salon.distanceKm.toStringAsFixed(1)} km',
                  ),
                  _SavedInfoPill(
                    icon: Icons.payments_outlined,
                    text:
                        l10n.fromPrice(AppFormatters.moneyK(salon.startingPrice)),
                  ),
                  _SavedInfoPill(
                    icon: salon.isOpen
                        ? Icons.flash_on_rounded
                        : Icons.lock_clock_outlined,
                    text: salon.isOpen ? l10n.openNow : l10n.currentlyClosed,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedInfoPill extends StatelessWidget {
  const _SavedInfoPill({
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
          Icon(icon, size: 15, color: AppColors.secondaryTextOf(context)),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.secondaryTextOf(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
