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

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: savedSalons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final Salon salon = savedSalons[index];
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onOpenSalon(salon),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  salon.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.removeSavedWorkshop,
                                onPressed: () =>
                                    _toggleSaved(context, salon: salon),
                                icon: const Icon(
                                  Icons.favorite,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            salon.address,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.secondaryTextOf(context),
                                ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _InfoChip(
                                icon: Icons.star,
                                text: '${salon.rating} (${salon.reviewCount})',
                              ),
                              _InfoChip(
                                icon: Icons.place_outlined,
                                text: '${salon.distanceKm} km',
                              ),
                              _InfoChip(
                                icon: Icons.payments_outlined,
                                text: l10n.fromPrice(
                                    AppFormatters.moneyK(salon.startingPrice)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

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
          Icon(icon, size: 14, color: AppColors.secondaryTextOf(context)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: AppColors.secondaryTextOf(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
