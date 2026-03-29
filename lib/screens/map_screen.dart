import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/salon.dart';
import '../providers/workshop_provider.dart';
import '../services/navigation_launcher.dart';
import '../ui/app_loading_view.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/workshop_image_view.dart';

enum _MapDiscoveryFilter { all, open, topRated, nearby }

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.onOpenSalon,
  });

  final ValueChanged<Salon> onOpenSalon;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _tashkentCenter = LatLng(41.3111, 69.2797);
  static const double _initialMapZoom = 12.4;
  static const double _zoomStep = 1;

  final MapController _mapController = MapController();
  LatLng? _userLocation;
  bool _isLocating = false;
  _MapDiscoveryFilter _activeFilter = _MapDiscoveryFilter.all;
  String? _selectedSalonId;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final WorkshopProvider workshopProvider = context.watch<WorkshopProvider>();
    final List<Salon> allSalons = workshopProvider.workshops;
    final List<Salon> salonsWithCoords = allSalons
        .where(
          (Salon salon) => salon.latitude != null && salon.longitude != null,
        )
        .toList(growable: false);

    if (workshopProvider.isLoading && allSalons.isEmpty) {
      return const SafeArea(child: AppLoadingView());
    }

    if (allSalons.isEmpty) {
      return SafeArea(
        child: AppEmptyState(
          icon: Icons.map_outlined,
          title: l10n.noSalonsFound,
          subtitle: workshopProvider.errorMessage ?? l10n.tryDifferentSearch,
        ),
      );
    }

    final List<Salon> filteredSalons = _applyFilter(salonsWithCoords);
    final Salon? selectedSalon = _resolveSelectedSalon(filteredSalons);
    final int openCount =
        salonsWithCoords.where((Salon salon) => salon.isOpen).length;
    final double averageRating = salonsWithCoords.isEmpty
        ? 0
        : salonsWithCoords.fold<double>(
              0,
              (double sum, Salon salon) => sum + salon.rating,
            ) /
            salonsWithCoords.length;
    final LatLng center = _userLocation ??
        (selectedSalon != null
            ? LatLng(selectedSalon.latitude!, selectedSalon.longitude!)
            : (salonsWithCoords.isEmpty
                ? _tashkentCenter
                : LatLng(
                    salonsWithCoords.first.latitude!,
                    salonsWithCoords.first.longitude!,
                  )));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _MapDiscoveryHeroCard(
              l10n: l10n,
              workshopCount: salonsWithCoords.length,
              openCount: openCount,
              averageRating: averageRating,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _MapFilterChip(
                  label: l10n.mapFilterAll,
                  selected: _activeFilter == _MapDiscoveryFilter.all,
                  onSelected: () => _setFilter(_MapDiscoveryFilter.all),
                ),
                _MapFilterChip(
                  label: l10n.openNow,
                  selected: _activeFilter == _MapDiscoveryFilter.open,
                  onSelected: () => _setFilter(_MapDiscoveryFilter.open),
                ),
                _MapFilterChip(
                  label: l10n.mapFilterTopRated,
                  selected: _activeFilter == _MapDiscoveryFilter.topRated,
                  onSelected: () => _setFilter(_MapDiscoveryFilter.topRated),
                ),
                _MapFilterChip(
                  label: l10n.mapFilterNearby,
                  selected: _activeFilter == _MapDiscoveryFilter.nearby,
                  onSelected: () => _setFilter(_MapDiscoveryFilter.nearby),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: <Widget>[
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: _initialMapZoom,
                        onTap: (_, __) => _clearSelectedSalon(),
                      ),
                      children: <Widget>[
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'uz.tokhirjon.usta_top',
                        ),
                        MarkerLayer(
                          markers: <Marker>[
                            ...filteredSalons.map(
                              (Salon salon) => Marker(
                                point:
                                    LatLng(salon.latitude!, salon.longitude!),
                                width: salon.id == selectedSalon?.id ? 148 : 58,
                                height: salon.id == selectedSalon?.id ? 98 : 58,
                                child: GestureDetector(
                                  onTap: () => _focusSalon(salon),
                                  child: _MapPin(
                                    label: salon.name,
                                    isOpen: salon.isOpen,
                                    isSelected: salon.id == selectedSalon?.id,
                                  ),
                                ),
                              ),
                            ),
                            if (_userLocation != null)
                              Marker(
                                point: _userLocation!,
                                width: 30,
                                height: 30,
                                child: const _UserLocationDot(),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.black.withValues(alpha: 0.02),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.08),
                              ],
                              stops: const <double>[0, 0.38, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 92,
                      child: _MapTopInfoBar(
                        title: l10n.mapTitle,
                        subtitle: filteredSalons.isEmpty
                            ? l10n.mapNoMatches
                            : l10n.salonsNearby(filteredSalons.length),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Column(
                        children: <Widget>[
                          _MapZoomControls(
                            zoomInTooltip: l10n.mapZoomIn,
                            zoomOutTooltip: l10n.mapZoomOut,
                            onZoomIn: _zoomIn,
                            onZoomOut: _zoomOut,
                          ),
                          const SizedBox(height: 8),
                          _MapActionButton(
                            tooltip: l10n.mapMyLocation,
                            onPressed: _isLocating
                                ? null
                                : () => _focusUserLocation(l10n),
                            child: _isLocating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.my_location_rounded,
                                    color: AppColors.primaryToneOf(context),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    if (salonsWithCoords.isEmpty)
                      Positioned.fill(
                        child: ColoredBox(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.92),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                l10n.mapNoCoordinates,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (filteredSalons.isEmpty)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: _MapFilterEmptyCard(
                          title: l10n.mapNoMatches,
                          subtitle: l10n.tryDifferentSearch,
                        ),
                      )
                    else if (selectedSalon != null)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: _SelectedWorkshopCard(
                          salon: selectedSalon,
                          l10n: l10n,
                          onClose: _clearSelectedSalon,
                          onRoute: () => NavigationLauncher.showNavigatorPicker(
                            context,
                            salon: selectedSalon,
                            origin: _userLocation,
                          ),
                          onOpen: () => widget.onOpenSalon(selectedSalon),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (salonsWithCoords.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              _MapSectionHeader(
                title: l10n.mapBrowseList,
                subtitle: filteredSalons.isEmpty
                    ? l10n.mapNoMatches
                    : l10n.mapHint,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 124,
                child: filteredSalons.isEmpty
                    ? _MapFilterEmptyCard(
                        title: l10n.mapNoMatches,
                        subtitle: l10n.tryDifferentSearch,
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredSalons.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (BuildContext context, int index) {
                          final Salon salon = filteredSalons[index];
                          return _MapSalonPreviewCard(
                            salon: salon,
                            isSelected: salon.id == selectedSalon?.id,
                            onTap: () => _focusSalon(salon),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Salon> _applyFilter(List<Salon> salons) {
    switch (_activeFilter) {
      case _MapDiscoveryFilter.all:
        return salons;
      case _MapDiscoveryFilter.open:
        return salons.where((Salon salon) => salon.isOpen).toList(growable: false);
      case _MapDiscoveryFilter.topRated:
        return salons
            .where((Salon salon) => salon.rating >= 4.7)
            .toList(growable: false);
      case _MapDiscoveryFilter.nearby:
        return salons
            .where((Salon salon) => salon.distanceKm > 0 && salon.distanceKm <= 5)
            .toList(growable: false);
    }
  }

  Salon? _resolveSelectedSalon(List<Salon> salons) {
    if (salons.isEmpty || _selectedSalonId == null) {
      return null;
    }
    for (final Salon salon in salons) {
      if (salon.id == _selectedSalonId) {
        return salon;
      }
    }
    return null;
  }

  void _setFilter(_MapDiscoveryFilter filter) {
    if (_activeFilter == filter) {
      return;
    }
    setState(() {
      _activeFilter = filter;
      _selectedSalonId = null;
    });
  }

  void _focusSalon(Salon salon) {
    final LatLng point = LatLng(salon.latitude!, salon.longitude!);
    setState(() {
      _selectedSalonId = salon.id;
    });
    final double nextZoom =
        _mapController.camera.zoom < 14.2 ? 14.2 : _mapController.camera.zoom;
    _mapController.move(point, nextZoom);
  }

  void _clearSelectedSalon() {
    if (_selectedSalonId == null) {
      return;
    }
    setState(() {
      _selectedSalonId = null;
    });
  }

  Future<void> _focusUserLocation(AppLocalizations l10n) async {
    setState(() {
      _isLocating = true;
    });

    try {
      final bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _showMessage(l10n.mapLocationDisabled);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage(l10n.mapLocationDenied);
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.best),
      );
      final LatLng point = LatLng(position.latitude, position.longitude);

      if (!mounted) {
        return;
      }

      setState(() {
        _userLocation = point;
      });
      _mapController.move(point, 14.8);
    } catch (_) {
      _showMessage(l10n.mapLocationError);
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _zoomIn() => _changeZoom(_zoomStep);

  void _zoomOut() => _changeZoom(-_zoomStep);

  void _changeZoom(double delta) {
    final MapCamera camera = _mapController.camera;
    final double nextZoom = camera.clampZoom(camera.zoom + delta);
    if (nextZoom == camera.zoom) {
      return;
    }
    _mapController.move(camera.center, nextZoom);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _MapDiscoveryHeroCard extends StatelessWidget {
  const _MapDiscoveryHeroCard({
    required this.l10n,
    required this.workshopCount,
    required this.openCount,
    required this.averageRating,
  });

  final AppLocalizations l10n;
  final int workshopCount;
  final int openCount;
  final double averageRating;

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
            l10n.mapTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.mapHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryTextOf(context),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _MapMetricTile(
                  label: l10n.workshopsMetricLabel,
                  value: '$workshopCount',
                  icon: Icons.garage_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MapMetricTile(
                  label: l10n.openNow,
                  value: '$openCount',
                  icon: Icons.flash_on_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MapMetricTile(
                  label: l10n.reviewAverageLabel,
                  value: averageRating == 0 ? '0.0' : averageRating.toStringAsFixed(1),
                  icon: Icons.star_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapMetricTile extends StatelessWidget {
  const _MapMetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.82),
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
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryTextOf(context),
                ),
          ),
        ],
      ),
    );
  }
}

class _MapFilterChip extends StatelessWidget {
  const _MapFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primarySoftOf(context),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected
                ? AppColors.primaryToneOf(context)
                : AppColors.textOf(context),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
      side: BorderSide(color: AppColors.borderOf(context)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }
}

class _MapTopInfoBar extends StatelessWidget {
  const _MapTopInfoBar({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryTextOf(context),
                ),
          ),
        ],
      ),
    );
  }
}

class _SelectedWorkshopCard extends StatelessWidget {
  const _SelectedWorkshopCard({
    required this.salon,
    required this.l10n,
    required this.onClose,
    required this.onRoute,
    required this.onOpen,
  });

  final Salon salon;
  final AppLocalizations l10n;
  final VoidCallback onClose;
  final VoidCallback onRoute;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x16000000),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.mapSelectedWorkshop,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.secondaryTextOf(context),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                visualDensity: VisualDensity.compact,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              WorkshopImageView(
                imageUrl: salon.imageUrl,
                width: 42,
                height: 42,
                borderRadius: BorderRadius.circular(14),
                fallbackIcon: Icons.build_circle_rounded,
                iconSize: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      salon.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      salon.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryTextOf(context),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            salon.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textOf(context),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _WorkshopInfoPill(
                icon: Icons.star_rounded,
                text: salon.rating.toStringAsFixed(1),
              ),
              _WorkshopInfoPill(
                icon: Icons.route_rounded,
                text: '${salon.distanceKm.toStringAsFixed(1)} km',
              ),
              _WorkshopInfoPill(
                icon: salon.isOpen ? Icons.flash_on_rounded : Icons.lock_clock,
                text: salon.isOpen ? l10n.openNow : l10n.currentlyClosed,
              ),
              _WorkshopInfoPill(
                icon: Icons.payments_outlined,
                text: l10n.fromPrice(AppFormatters.moneyK(salon.startingPrice)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRoute,
                  icon: const Icon(Icons.route_outlined),
                  label: Text(l10n.routeToWorkshop),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onOpen,
                  child: Text(l10n.openOnMap),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkshopInfoPill extends StatelessWidget {
  const _WorkshopInfoPill({
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
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.primaryToneOf(context)),
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

class _MapSectionHeader extends StatelessWidget {
  const _MapSectionHeader({
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

class _MapFilterEmptyCard extends StatelessWidget {
  const _MapFilterEmptyCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentSoftOf(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.travel_explore_rounded,
              color: AppColors.accentOf(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryTextOf(context),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.label,
    required this.isOpen,
    required this.isSelected,
  });

  final String label;
  final bool isOpen;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final Color fillColor =
        isOpen ? AppColors.primaryToneOf(context) : AppColors.warning;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (isSelected)
          Container(
            constraints: const BoxConstraints(maxWidth: 132),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderOf(context)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  blurRadius: 12,
                  offset: Offset(0, 6),
                  color: Color(0x1A000000),
                ),
              ],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        if (isSelected) const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isSelected ? 46 : 38,
          height: isSelected ? 46 : 38,
          decoration: BoxDecoration(
            color: fillColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: isSelected ? 3 : 2.2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                blurRadius: isSelected ? 18 : 10,
                offset: const Offset(0, 4),
                color: Colors.black.withValues(alpha: isSelected ? 0.26 : 0.2),
              ),
            ],
          ),
          child: const Icon(Icons.build_rounded, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: child,
      ),
    );
  }
}

class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls({
    required this.zoomInTooltip,
    required this.zoomOutTooltip,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final String zoomInTooltip;
  final String zoomOutTooltip;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final Color dividerColor =
        Theme.of(context).dividerColor.withValues(alpha: 0.35);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            onPressed: onZoomIn,
            tooltip: zoomInTooltip,
            icon: Icon(Icons.add, color: AppColors.primaryToneOf(context)),
          ),
          Container(
            width: 36,
            height: 1,
            color: dividerColor,
          ),
          IconButton(
            onPressed: onZoomOut,
            tooltip: zoomOutTooltip,
            icon: Icon(Icons.remove, color: AppColors.primaryToneOf(context)),
          ),
        ],
      ),
    );
  }
}

class _UserLocationDot extends StatelessWidget {
  const _UserLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryToneOf(context),
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _MapSalonPreviewCard extends StatelessWidget {
  const _MapSalonPreviewCard({
    required this.salon,
    required this.isSelected,
    required this.onTap,
  });

  final Salon salon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? AppColors.primaryToneOf(context)
                : AppColors.borderOf(context),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primarySoftOf(context)
                            : AppColors.chipBackgroundOf(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.place_rounded,
                        color: isSelected
                            ? AppColors.primaryToneOf(context)
                            : AppColors.secondaryTextOf(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        salon.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  salon.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryTextOf(context),
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        AppFormatters.moneyK(salon.startingPrice),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.primaryToneOf(context),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${salon.distanceKm.toStringAsFixed(1)} km',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.secondaryTextOf(context),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
