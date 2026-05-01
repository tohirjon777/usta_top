import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/salon.dart';
import '../providers/saved_workshops_provider.dart';
import '../providers/workshop_provider.dart';
import '../ui/app_loading_view.dart';
import '../widgets/app_reveal.dart';
import '../widgets/workshop_image_view.dart';

enum _HomeDiscoveryFilter { all, open, topRated, nearby, saved }

enum _HomeDiscoverySort { recommended, nearest, rating, price }

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
  _HomeDiscoveryFilter _activeFilter = _HomeDiscoveryFilter.all;
  _HomeDiscoverySort _activeSort = _HomeDiscoverySort.recommended;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final WorkshopProvider workshopProvider = context.watch<WorkshopProvider>();
    final SavedWorkshopsProvider savedProvider =
        context.watch<SavedWorkshopsProvider>();
    final List<Salon> salons = _sortSalons(
      _applyFilter(
        workshopProvider.workshops,
        savedProvider,
      ),
    );
    final bool isLoading = workshopProvider.isLoading;
    final String query = workshopProvider.query;
    final String? errorMessage = workshopProvider.errorMessage;
    final int totalServices = salons.fold<int>(
      0,
      (int sum, Salon salon) => sum + salon.services.length,
    );
    final double averageRating = salons.isEmpty
        ? 0
        : salons.fold<double>(
              0,
              (double sum, Salon salon) => sum + salon.rating,
            ) /
            salons.length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: context.read<WorkshopProvider>().loadWorkshops,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: <Widget>[
            AppReveal(
              beginOffset: const Offset(0, 0.03),
              beginScale: 0.985,
              child: _HomeHeroCard(
                l10n: l10n,
                controller: _searchController,
                workshopCount: workshopProvider.totalCount,
                totalServices: totalServices,
                averageRating: averageRating,
                onChanged: (String value) {
                  context.read<WorkshopProvider>().setQuery(value.trim());
                },
                onClear: query.isEmpty
                    ? null
                    : () {
                        _searchController.clear();
                        context.read<WorkshopProvider>().setQuery('');
                      },
              ),
            ),
            const SizedBox(height: 18),
            AppReveal(
              delay: const Duration(milliseconds: 90),
              beginOffset: const Offset(0, 0.04),
              beginScale: 0.985,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    _QuickBadge(
                      icon: Icons.near_me_outlined,
                      text: l10n.salonsNearby(workshopProvider.totalCount),
                    ),
                    const SizedBox(width: 8),
                    _QuickBadge(
                      icon: Icons.flash_on_outlined,
                      text: l10n.fastConfirmation,
                    ),
                    const SizedBox(width: 8),
                    _QuickBadge(
                      icon: Icons.verified_outlined,
                      text: l10n.verifiedMasters,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            AppReveal(
              delay: const Duration(milliseconds: 120),
              beginOffset: const Offset(0, 0.045),
              beginScale: 0.985,
              child: _HomeDiscoveryControls(
                l10n: l10n,
                activeFilter: _activeFilter,
                activeSortLabel: _sortLabel(l10n, _activeSort),
                onSortTap: () => _showSortSheet(context),
                onFilterSelected: (value) {
                  setState(() {
                    _activeFilter = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            AppReveal(
              delay: const Duration(milliseconds: 140),
              beginOffset: const Offset(0, 0.05),
              beginScale: 0.985,
              child: _SectionHeader(
                title:
                    query.isEmpty ? l10n.findTrustedMasters : l10n.searchHint,
                subtitle: l10n.homeResultsSummary(
                  salons.length,
                  _sortLabel(l10n, _activeSort),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (isLoading && salons.isEmpty)
              const AppReveal(
                delay: Duration(milliseconds: 180),
                child: SizedBox(height: 260, child: AppLoadingView()),
              )
            else if (errorMessage != null && salons.isEmpty)
              AppReveal(
                delay: const Duration(milliseconds: 180),
                child: _EmptySearchState(
                  title: l10n.noSalonsFound,
                  subtitle: errorMessage,
                ),
              )
            else if (salons.isEmpty)
              AppReveal(
                delay: const Duration(milliseconds: 180),
                child: _EmptySearchState(
                  title: l10n.noSalonsFound,
                  subtitle: l10n.tryDifferentSearch,
                ),
              )
            else
              ...salons.asMap().entries.map(
                (MapEntry<int, Salon> entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AppReveal(
                    delay: Duration(milliseconds: 180 + (entry.key * 55)),
                    duration: const Duration(milliseconds: 240),
                    beginOffset: const Offset(0, 0.08),
                    beginScale: 0.975,
                    child: _SalonCard(
                      l10n: l10n,
                      salon: entry.value,
                      rank: entry.key + 1,
                      isSaved: savedProvider.isSaved(entry.value.id),
                      onTap: () => widget.onOpenSalon(entry.value),
                      onToggleSaved: () => _toggleSaved(entry.value),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSaved(Salon salon) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SavedWorkshopsProvider savedProvider =
        context.read<SavedWorkshopsProvider>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      final bool saved = await savedProvider.toggleSaved(salon.id);
      if (!mounted) {
        return;
      }
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
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.savedWorkshopUpdateFailed)),
      );
    }
  }

  List<Salon> _applyFilter(
    List<Salon> salons,
    SavedWorkshopsProvider savedProvider,
  ) {
    switch (_activeFilter) {
      case _HomeDiscoveryFilter.all:
        return List<Salon>.from(salons, growable: false);
      case _HomeDiscoveryFilter.open:
        return salons
            .where((Salon salon) => salon.isOpen)
            .toList(growable: false);
      case _HomeDiscoveryFilter.topRated:
        return salons
            .where((Salon salon) => salon.rating >= 4.7)
            .toList(growable: false);
      case _HomeDiscoveryFilter.nearby:
        return salons
            .where((Salon salon) => salon.distanceKm > 0 && salon.distanceKm <= 5)
            .toList(growable: false);
      case _HomeDiscoveryFilter.saved:
        return salons
            .where((Salon salon) => savedProvider.isSaved(salon.id))
            .toList(growable: false);
    }
  }

  List<Salon> _sortSalons(List<Salon> salons) {
    final List<Salon> sorted = List<Salon>.from(salons, growable: false);
    sorted.sort((Salon a, Salon b) {
      switch (_activeSort) {
        case _HomeDiscoverySort.recommended:
          final int openCompare = (b.isOpen ? 1 : 0).compareTo(a.isOpen ? 1 : 0);
          if (openCompare != 0) {
            return openCompare;
          }
          final int ratingCompare = b.rating.compareTo(a.rating);
          if (ratingCompare != 0) {
            return ratingCompare;
          }
          final int reviewCompare = b.reviewCount.compareTo(a.reviewCount);
          if (reviewCompare != 0) {
            return reviewCompare;
          }
          return a.distanceKm.compareTo(b.distanceKm);
        case _HomeDiscoverySort.nearest:
          return a.distanceKm.compareTo(b.distanceKm);
        case _HomeDiscoverySort.rating:
          final int ratingCompare = b.rating.compareTo(a.rating);
          if (ratingCompare != 0) {
            return ratingCompare;
          }
          return b.reviewCount.compareTo(a.reviewCount);
        case _HomeDiscoverySort.price:
          final int priceCompare = a.startingPrice.compareTo(b.startingPrice);
          if (priceCompare != 0) {
            return priceCompare;
          }
          return a.distanceKm.compareTo(b.distanceKm);
      }
    });
    return sorted;
  }

  String _sortLabel(AppLocalizations l10n, _HomeDiscoverySort value) {
    switch (value) {
      case _HomeDiscoverySort.recommended:
        return l10n.homeSortRecommended;
      case _HomeDiscoverySort.nearest:
        return l10n.homeSortNearest;
      case _HomeDiscoverySort.rating:
        return l10n.homeSortTopRated;
      case _HomeDiscoverySort.price:
        return l10n.homeSortLowestPrice;
    }
  }

  Future<void> _showSortSheet(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final _HomeDiscoverySort? selected =
        await showModalBottomSheet<_HomeDiscoverySort>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      l10n.homeSortTitle,
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ..._HomeDiscoverySort.values.map(
                  (_HomeDiscoverySort option) => ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: Icon(
                      option == _activeSort
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: option == _activeSort
                          ? AppColors.primaryToneOf(sheetContext)
                          : AppColors.secondaryTextOf(sheetContext),
                    ),
                    title: Text(_sortLabel(l10n, option)),
                    onTap: () => Navigator.of(sheetContext).pop(option),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted || selected == _activeSort) {
      return;
    }

    setState(() {
      _activeSort = selected;
    });
  }
}

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({
    required this.l10n,
    required this.controller,
    required this.workshopCount,
    required this.totalServices,
    required this.averageRating,
    required this.onChanged,
    this.onClear,
  });

  final AppLocalizations l10n;
  final TextEditingController controller;
  final int workshopCount;
  final int totalServices;
  final double averageRating;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final Color primary = AppColors.primaryToneOf(context);
    final Color accent = AppColors.accentOf(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? <Color>[
                  Color.lerp(primary, Colors.black, 0.16)!,
                  Color.lerp(accent, primary, 0.35)!,
                ]
              : <Color>[primary, accent],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.24 : 0.18),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Image.asset(
                    AppAssets.logo,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.appTitle,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.findTrustedMasters,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                  suffixIcon: onClear == null
                      ? null
                      : IconButton(
                          onPressed: onClear,
                          icon: Icon(
                            Icons.close,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: _HeroMetricTile(
                    value: '$workshopCount',
                    label: l10n.workshopsMetricLabel,
                    icon: Icons.garage_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroMetricTile(
                    value: '$totalServices',
                    label: l10n.services,
                    icon: Icons.tune_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroMetricTile(
                    value: averageRating == 0
                        ? '0.0'
                        : averageRating.toStringAsFixed(1),
                    label: l10n.reviewAverageLabel,
                    icon: Icons.star_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetricTile extends StatelessWidget {
  const _HeroMetricTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickBadge extends StatelessWidget {
  const _QuickBadge({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.primarySoftOf(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.primaryToneOf(context)),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: AppColors.primaryToneOf(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDiscoveryControls extends StatelessWidget {
  const _HomeDiscoveryControls({
    required this.l10n,
    required this.activeFilter,
    required this.activeSortLabel,
    required this.onSortTap,
    required this.onFilterSelected,
  });

  final AppLocalizations l10n;
  final _HomeDiscoveryFilter activeFilter;
  final String activeSortLabel;
  final VoidCallback onSortTap;
  final ValueChanged<_HomeDiscoveryFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _HomeFilterChip(
                  label: l10n.mapFilterAll,
                  selected: activeFilter == _HomeDiscoveryFilter.all,
                  onTap: () => onFilterSelected(_HomeDiscoveryFilter.all),
                ),
                const SizedBox(width: 8),
                _HomeFilterChip(
                  label: l10n.openNow,
                  selected: activeFilter == _HomeDiscoveryFilter.open,
                  onTap: () => onFilterSelected(_HomeDiscoveryFilter.open),
                ),
                const SizedBox(width: 8),
                _HomeFilterChip(
                  label: l10n.mapFilterTopRated,
                  selected: activeFilter == _HomeDiscoveryFilter.topRated,
                  onTap: () => onFilterSelected(_HomeDiscoveryFilter.topRated),
                ),
                const SizedBox(width: 8),
                _HomeFilterChip(
                  label: l10n.mapFilterNearby,
                  selected: activeFilter == _HomeDiscoveryFilter.nearby,
                  onTap: () => onFilterSelected(_HomeDiscoveryFilter.nearby),
                ),
                const SizedBox(width: 8),
                _HomeFilterChip(
                  label: l10n.homeFilterSaved,
                  selected: activeFilter == _HomeDiscoveryFilter.saved,
                  onTap: () => onFilterSelected(_HomeDiscoveryFilter.saved),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _HomeSortButton(
          label: activeSortLabel,
          onTap: onSortTap,
        ),
      ],
    );
  }
}

class _HomeFilterChip extends StatelessWidget {
  const _HomeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primarySoftOf(context),
      side: BorderSide(color: AppColors.borderOf(context)),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected
                ? AppColors.primaryToneOf(context)
                : AppColors.textOf(context),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }
}

class _HomeSortButton extends StatelessWidget {
  const _HomeSortButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.tune_rounded,
                size: 18,
                color: AppColors.primaryToneOf(context),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
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
          style: Theme.of(context).textTheme.titleLarge,
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

class _SalonCard extends StatelessWidget {
  const _SalonCard({
    required this.l10n,
    required this.salon,
    required this.rank,
    required this.isSaved,
    required this.onTap,
    required this.onToggleSaved,
  });

  final AppLocalizations l10n;
  final Salon salon;
  final int rank;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color openColor =
        salon.isOpen ? AppColors.primaryToneOf(context) : AppColors.warning;
    final SalonService? firstService =
        salon.services.isEmpty ? null : salon.services.first;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  WorkshopImageView(
                    imageUrl: salon.imageUrl,
                    width: 58,
                    height: 58,
                    borderRadius: BorderRadius.circular(20),
                    fallbackIcon: Icons.car_repair,
                    iconSize: 26,
                    overlay: Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.10 : 0.06,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            color: AppColors.primaryToneOf(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          salon.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
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
                  Column(
                    children: <Widget>[
                      IconButton(
                        onPressed: onToggleSaved,
                        tooltip: isSaved
                            ? l10n.removeSavedWorkshop
                            : l10n.saveWorkshop,
                        icon: Icon(
                          isSaved ? Icons.favorite : Icons.favorite_border,
                          color: isSaved
                              ? Colors.redAccent
                              : AppColors.secondaryTextOf(context),
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoftOf(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderOf(context)),
                        ),
                        child: Icon(
                          Icons.north_east_rounded,
                          size: 18,
                          color: AppColors.primaryToneOf(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
                    text: '${salon.distanceKm.toStringAsFixed(1)} km',
                  ),
                  _InfoChip(
                    icon: Icons.circle,
                    iconColor: openColor,
                    text: salon.isOpen ? l10n.openNow : l10n.closed,
                    textColor: openColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                salon.address,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (salon.services.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: salon.services.take(3).map((SalonService service) {
                    return _ServicePreviewPill(label: service.name);
                  }).toList(),
                ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.fromPrice(
                            AppFormatters.moneyK(salon.startingPrice),
                          ),
                          style: TextStyle(
                            color: AppColors.primaryToneOf(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        if (firstService != null) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            l10n.durationMinutes(firstService.durationMinutes),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.secondaryTextOf(context),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoftOf(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accentOf(context).withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      salon.badge,
                      style: TextStyle(
                        color: AppColors.accentOf(context),
                        fontWeight: FontWeight.w700,
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

class _ServicePreviewPill extends StatelessWidget {
  const _ServicePreviewPill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.chipBackgroundOf(context),
        borderRadius: BorderRadius.circular(999),
        border: isDark
            ? Border.all(
                color: AppColors.borderOf(context).withValues(alpha: 0.76),
              )
            : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textOf(context),
              fontWeight: FontWeight.w600,
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.chipBackgroundOf(context),
        borderRadius: BorderRadius.circular(999),
        border: isDark
            ? Border.all(
                color: AppColors.borderOf(context).withValues(alpha: 0.76),
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: iconColor ?? AppColors.starOf(context)),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: textColor ?? AppColors.secondaryTextOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppColors.primarySoftOf(context),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 38,
                color: AppColors.primaryToneOf(context),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
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
