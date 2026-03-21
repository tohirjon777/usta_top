import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../models/salon.dart';
import '../providers/workshop_provider.dart';
import '../ui/app_loading_view.dart';
import '../widgets/app_empty_state.dart';

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

  final MapController _mapController = MapController();
  LatLng? _userLocation;
  bool _isLocating = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final WorkshopProvider workshopProvider = context.watch<WorkshopProvider>();
    final List<Salon> allSalons = workshopProvider.workshops;
    final List<Salon> salonsWithCoords = allSalons
        .where(
            (Salon salon) => salon.latitude != null && salon.longitude != null)
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

    final LatLng center = _userLocation ??
        (salonsWithCoords.isEmpty
            ? _tashkentCenter
            : LatLng(
                salonsWithCoords.first.latitude!,
                salonsWithCoords.first.longitude!,
              ));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.mapTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.mapHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryTextOf(context),
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: <Widget>[
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 12.4,
                      ),
                      children: <Widget>[
                        // OSM tile qatlami API key talab qilmaydi.
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'uz.tokhirjon.usta_top',
                        ),
                        MarkerLayer(
                          markers: <Marker>[
                            ...salonsWithCoords.map(
                              (Salon salon) => Marker(
                                point:
                                    LatLng(salon.latitude!, salon.longitude!),
                                width: 50,
                                height: 50,
                                child: GestureDetector(
                                  onTap: () =>
                                      _showSalonCard(context, salon, l10n),
                                  child: _MapPin(isOpen: salon.isOpen),
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
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        child: IconButton(
                          onPressed: _isLocating
                              ? null
                              : () => _focusUserLocation(l10n),
                          tooltip: l10n.mapMyLocation,
                          icon: _isLocating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  Icons.my_location,
                                  color: AppColors.primaryToneOf(context),
                                ),
                        ),
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
                      ),
                  ],
                ),
              ),
            ),
            if (salonsWithCoords.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: salonsWithCoords.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final Salon salon = salonsWithCoords[index];
                    return _MapSalonChip(
                      salon: salon,
                      actionLabel: l10n.openOnMap,
                      onTap: () => widget.onOpenSalon(salon),
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

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSalonCard(
    BuildContext context,
    Salon salon,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(salon.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                salon.address,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryTextOf(context),
                    ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onOpenSalon(salon);
                },
                child: Text(l10n.openOnMap),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final Color fillColor =
        isOpen ? AppColors.primaryToneOf(context) : AppColors.warning;
    return Align(
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: fillColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2.2,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 4),
              color: Color(0x33000000),
            ),
          ],
        ),
        child: const Icon(Icons.build_rounded, color: Colors.white, size: 20),
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

class _MapSalonChip extends StatelessWidget {
  const _MapSalonChip({
    required this.salon,
    required this.actionLabel,
    required this.onTap,
  });

  final Salon salon;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: <Widget>[
                Icon(Icons.location_on,
                    color: AppColors.primaryToneOf(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        salon.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        actionLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryTextOf(context),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
