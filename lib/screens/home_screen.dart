import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/salon.dart';
import '../providers/workshop_provider.dart';
import '../ui/app_loading_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenSalon,
  });

  final ValueChanged<Salon> onOpenSalon;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final WorkshopProvider workshopProvider = context.watch<WorkshopProvider>();
    final List<Salon> salons = workshopProvider.workshops;
    final bool isLoading = workshopProvider.isLoading;
    final String query = workshopProvider.query;
    final String? errorMessage = workshopProvider.errorMessage;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: <Widget>[
          Text(
            l10n.appTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.findTrustedMasters,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryTextOf(context),
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (String value) {
              context.read<WorkshopProvider>().setQuery(value.trim());
            },
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        context.read<WorkshopProvider>().setQuery('');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _QuickBadge(
                    text: l10n.salonsNearby(workshopProvider.totalCount)),
                const SizedBox(width: 8),
                _QuickBadge(text: l10n.fastConfirmation),
                const SizedBox(width: 8),
                _QuickBadge(text: l10n.verifiedMasters),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (isLoading && salons.isEmpty)
            const SizedBox(height: 220, child: AppLoadingView())
          else if (errorMessage != null && salons.isEmpty)
            _EmptySearchState(
              title: l10n.noSalonsFound,
              subtitle: errorMessage,
            )
          else if (salons.isEmpty)
            _EmptySearchState(
              title: l10n.noSalonsFound,
              subtitle: l10n.tryDifferentSearch,
            )
          else
            ...salons.map(
              (Salon salon) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SalonCard(
                  l10n: l10n,
                  salon: salon,
                  onTap: () => widget.onOpenSalon(salon),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickBadge extends StatelessWidget {
  const _QuickBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primarySoftOf(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.primaryToneOf(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SalonCard extends StatelessWidget {
  const _SalonCard({
    required this.l10n,
    required this.salon,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final Salon salon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color openColor =
        salon.isOpen ? AppColors.primaryToneOf(context) : AppColors.warning;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoftOf(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.car_repair,
                      color: AppColors.primaryToneOf(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(salon.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          l10n.masterPrefix(salon.master),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.secondaryTextOf(context),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  _InfoChip(
                    icon: Icons.star,
                    text: '${salon.rating} (${salon.reviewCount})',
                  ),
                  _InfoChip(
                      icon: Icons.place_outlined,
                      text: '${salon.distanceKm} km'),
                  _InfoChip(
                    icon: Icons.circle,
                    iconColor: openColor,
                    text: salon.isOpen ? l10n.openNow : l10n.closed,
                    textColor: openColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                salon.address,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Text(
                    l10n.fromPrice(AppFormatters.moneyK(salon.startingPrice)),
                    style: TextStyle(
                      color: AppColors.primaryToneOf(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoftOf(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      salon.badge,
                      style: TextStyle(
                        color: AppColors.accentOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String text;
  final Color? iconColor;
  final Color? textColor;

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
          Icon(icon, size: 14, color: iconColor ?? AppColors.starOf(context)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor ?? AppColors.secondaryTextOf(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.search_off,
              size: 48,
              color: AppColors.secondaryTextOf(context),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryTextOf(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
