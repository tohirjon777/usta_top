import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/salon.dart';
import '../providers/workshop_provider.dart';
import '../services/navigation_launcher.dart';
import '../ui/app_loading_view.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_reveal.dart';
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
  static const Point _tashkentCenter = Point(latitude: 41.3111, longitude: 69.2797);
  static const double _initialMapZoom = 12.4;
  static const double _selectedSalonZoom = 14.2;
  static const double _userLocationZoom = 14.8;
  static const double _zoomStep = 1;
  static const double _minMapZoom = 3;
  static const double _maxMapZoom = 18.5;

  final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers =
      <Factory<OneSequenceGestureRecognizer>>{
    Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
  };

  YandexMapController? _mapController;
  Point? _userLocation;
  bool _isLocating = false;
  _MapDiscoveryFilter _activeFilter = _MapDiscoveryFilter.all;
  String? _selectedSalonId;
  double _currentZoom = _initialMapZoom;
  Brightness? _markerBrightness;
  BitmapDescriptor? _openMarkerIcon;
  BitmapDescriptor? _closedMarkerIcon;
  BitmapDescriptor? _selectedOpenMarkerIcon;
  BitmapDescriptor? _selectedClosedMarkerIcon;
  BitmapDescriptor? _userMarkerIcon;
  String? _appliedViewportSignature;
  bool _viewportSyncScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureMarkerIcons();
  }

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
    final Point center = _userLocation ??
        (selectedSalon != null
            ? Point(
                latitude: selectedSalon.latitude!,
                longitude: selectedSalon.longitude!,
              )
            : (salonsWithCoords.isEmpty
                ? _tashkentCenter
                : Point(
                    latitude: salonsWithCoords.first.latitude!,
                    longitude: salonsWithCoords.first.longitude!,
                  )));

    _scheduleViewportSync(
      filteredSalons: filteredSalons,
      selectedSalon: selectedSalon,
      fallbackCenter: center,
    );

    return SafeArea(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double mapHeight = constraints.maxHeight * 0.5;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: ListView(
              children: <Widget>[
                AppReveal(
                  child: _MapDiscoveryHeroCard(
                    l10n: l10n,
                    workshopCount: salonsWithCoords.length,
                    openCount: openCount,
                    averageRating: averageRating,
                  ),
                ),
                const SizedBox(height: 12),
                AppReveal(
                  delay: const Duration(milliseconds: 90),
                  child: Wrap(
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
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: mapHeight,
                  child: AppReveal(
                    delay: const Duration(milliseconds: 150),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: <Widget>[
                          YandexMap(
                            gestureRecognizers: _gestureRecognizers,
                            fastTapEnabled: true,
                            nightModeEnabled:
                                Theme.of(context).brightness == Brightness.dark,
                            mapObjects:
                                _buildMapObjects(context, filteredSalons, selectedSalon),
                            onMapCreated: (YandexMapController controller) async {
                              _mapController = controller;
                              _appliedViewportSignature = null;
                              await _syncViewportToContent(
                                filteredSalons: filteredSalons,
                                selectedSalon: selectedSalon,
                                fallbackCenter: center,
                              );
                            },
                            onMapTap: (_) => _clearSelectedSalon(),
                            onCameraPositionChanged: (
                              CameraPosition position,
                              CameraUpdateReason _,
                              bool __,
                            ) {
                              _currentZoom = position.zoom;
                            },
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
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
                            ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              reverseDuration:
                                  const Duration(milliseconds: 180),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                final Animation<Offset> slide = Tween<Offset>(
                                  begin: const Offset(0, 0.08),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                );
                                final Animation<double> scale = Tween<double>(
                                  begin: 0.96,
                                  end: 1,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutBack,
                                  ),
                                );
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: scale,
                                    child: SlideTransition(
                                      position: slide,
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                              child: selectedSalon == null
                                  ? const SizedBox.shrink()
                                  : KeyedSubtree(
                                      key: ValueKey<String>(selectedSalon.id),
                                      child: _SelectedWorkshopCard(
                                        salon: selectedSalon,
                                        l10n: l10n,
                                        onClose: _clearSelectedSalon,
                                        onRoute: () =>
                                            NavigationLauncher.showNavigatorPicker(
                                          context,
                                          salon: selectedSalon,
                                          origin: _userLocation == null
                                              ? null
                                              : LatLng(
                                                  _userLocation!.latitude,
                                                  _userLocation!.longitude,
                                                ),
                                        ),
                                        onOpen: () {
                                          _clearSelectedSalon();
                                          widget.onOpenSalon(selectedSalon);
                                        },
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (salonsWithCoords.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  _MapSectionHeader(
                    title: l10n.mapBrowseList,
                    subtitle: filteredSalons.isEmpty
                        ? l10n.mapNoMatches
                        : l10n.mapHint,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 116,
                    child: filteredSalons.isEmpty
                        ? _MapFilterEmptyCard(
                            title: l10n.mapNoMatches,
                            subtitle: l10n.tryDifferentSearch,
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: filteredSalons.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
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
          );
        },
      ),
    );
  }

  List<MapObject> _buildMapObjects(
    BuildContext context,
    List<Salon> salons,
    Salon? selectedSalon,
  ) {
    final List<MapObject> objects = <MapObject>[];
    final Color textColor = AppColors.textOf(context);
    final Color outlineColor = Theme.of(context).scaffoldBackgroundColor;

    for (final Salon salon in salons) {
      final bool isSelected = salon.id == selectedSalon?.id;
      final BitmapDescriptor? icon = switch ((salon.isOpen, isSelected)) {
        (true, true) => _selectedOpenMarkerIcon,
        (false, true) => _selectedClosedMarkerIcon,
        (true, false) => _openMarkerIcon,
        (false, false) => _closedMarkerIcon,
      };

      if (icon == null) {
        continue;
      }

      objects.add(
        PlacemarkMapObject(
          mapId: MapObjectId('salon_${salon.id}'),
          point: Point(latitude: salon.latitude!, longitude: salon.longitude!),
          zIndex: isSelected ? 30 : 10,
          consumeTapEvents: true,
          opacity: 1,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: icon,
              anchor: const Offset(0.5, 0.5),
            ),
          ),
          text: isSelected
              ? PlacemarkText(
                  text: _markerLabel(salon.name),
                  style: PlacemarkTextStyle(
                    placement: TextStylePlacement.top,
                    offset: 1.6,
                    size: 13,
                    color: textColor,
                    outlineColor: outlineColor,
                  ),
                )
              : null,
          onTap: (_, __) => _focusSalon(salon),
        ),
      );
    }

    if (_userLocation != null && _userMarkerIcon != null) {
      objects.add(
        PlacemarkMapObject(
          mapId: const MapObjectId('user_location'),
          point: _userLocation!,
          zIndex: 50,
          consumeTapEvents: false,
          opacity: 1,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: _userMarkerIcon!,
              anchor: const Offset(0.5, 0.5),
            ),
          ),
        ),
      );
    }

    return objects;
  }

  String _markerLabel(String value) {
    const int maxLength = 18;
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength - 1)}…';
  }

  void _scheduleViewportSync({
    required List<Salon> filteredSalons,
    required Salon? selectedSalon,
    required Point fallbackCenter,
  }) {
    final String signature = <String>[
      _activeFilter.name,
      selectedSalon?.id ?? 'none',
      filteredSalons.map((Salon salon) => salon.id).join(','),
    ].join('|');

    if (_appliedViewportSignature == signature || _viewportSyncScheduled) {
      return;
    }

    _viewportSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _viewportSyncScheduled = false;
      if (!mounted || _appliedViewportSignature == signature) {
        return;
      }

      await _syncViewportToContent(
        filteredSalons: filteredSalons,
        selectedSalon: selectedSalon,
        fallbackCenter: fallbackCenter,
      );

      _appliedViewportSignature = signature;
    });
  }

  Future<void> _syncViewportToContent({
    required List<Salon> filteredSalons,
    required Salon? selectedSalon,
    required Point fallbackCenter,
  }) async {
    if (selectedSalon != null) {
      await _moveCamera(
        Point(
          latitude: selectedSalon.latitude!,
          longitude: selectedSalon.longitude!,
        ),
        zoom: _currentZoom < _selectedSalonZoom
            ? _selectedSalonZoom
            : _currentZoom,
      );
      return;
    }

    if (filteredSalons.isEmpty) {
      await _moveCamera(
        fallbackCenter,
        zoom: _currentZoom,
      );
      return;
    }

    await _fitSalonsOnMap(filteredSalons);
  }

  Future<void> _fitSalonsOnMap(List<Salon> salons) async {
    final YandexMapController? controller = _mapController;
    if (controller == null || salons.isEmpty) {
      return;
    }

    if (salons.length == 1) {
      final Salon salon = salons.first;
      await _moveCamera(
        Point(latitude: salon.latitude!, longitude: salon.longitude!),
        zoom: _currentZoom < _selectedSalonZoom
            ? _selectedSalonZoom
            : _currentZoom,
      );
      return;
    }

    double north = salons.first.latitude!;
    double south = salons.first.latitude!;
    double east = salons.first.longitude!;
    double west = salons.first.longitude!;

    for (final Salon salon in salons.skip(1)) {
      final double lat = salon.latitude!;
      final double lon = salon.longitude!;
      if (lat > north) north = lat;
      if (lat < south) south = lat;
      if (lon > east) east = lon;
      if (lon < west) west = lon;
    }

    const double padding = 0.02;

    await controller.moveCamera(
      CameraUpdate.newGeometry(
        Geometry.fromBoundingBox(
          BoundingBox(
            northEast: Point(
              latitude: north + padding,
              longitude: east + padding,
            ),
            southWest: Point(
              latitude: south - padding,
              longitude: west - padding,
            ),
          ),
        ),
      ),
      animation: const MapAnimation(
        type: MapAnimationType.smooth,
        duration: 0.32,
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
    if (_selectedSalonId == salon.id) {
      _clearSelectedSalon();
      return;
    }
    final Point point = Point(
      latitude: salon.latitude!,
      longitude: salon.longitude!,
    );
    setState(() {
      _selectedSalonId = salon.id;
    });
    final double nextZoom =
        _currentZoom < _selectedSalonZoom ? _selectedSalonZoom : _currentZoom;
    _moveCamera(point, zoom: nextZoom);
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
      final Point point = Point(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) {
        return;
      }

      context.read<WorkshopProvider>().updateDistancesFromCoordinates(
            latitude: position.latitude,
            longitude: position.longitude,
          );
      setState(() {
        _userLocation = point;
      });
      await _moveCamera(point, zoom: _userLocationZoom);
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

  Future<void> _changeZoom(double delta) async {
    final YandexMapController? controller = _mapController;
    if (controller == null) {
      return;
    }
    final double nextZoom = (_currentZoom + delta).clamp(_minMapZoom, _maxMapZoom);
    if ((nextZoom - _currentZoom).abs() < 0.001) {
      return;
    }
    _currentZoom = nextZoom;
    await controller.moveCamera(
      CameraUpdate.zoomTo(nextZoom),
      animation: const MapAnimation(
        type: MapAnimationType.smooth,
        duration: 0.22,
      ),
    );
  }

  Future<void> _moveCamera(
    Point target, {
    required double zoom,
    bool animated = true,
  }) async {
    final YandexMapController? controller = _mapController;
    if (controller == null) {
      return;
    }
    final double nextZoom = zoom.clamp(_minMapZoom, _maxMapZoom);
    _currentZoom = nextZoom;
    await controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: nextZoom),
      ),
      animation: animated
          ? const MapAnimation(
              type: MapAnimationType.smooth,
              duration: 0.28,
            )
          : null,
    );
  }

  Future<void> _ensureMarkerIcons() async {
    final Brightness brightness = Theme.of(context).brightness;
    if (_markerBrightness == brightness &&
        _openMarkerIcon != null &&
        _closedMarkerIcon != null &&
        _selectedOpenMarkerIcon != null &&
        _selectedClosedMarkerIcon != null &&
        _userMarkerIcon != null) {
      return;
    }

    final Color openColor = AppColors.primaryToneOf(context);
    final Color closedColor = AppColors.warning;
    final Color userColor = AppColors.accentOf(context);

    final BitmapDescriptor openMarkerIcon = BitmapDescriptor.fromBytes(
      await _buildMarkerBytes(fillColor: openColor),
    );
    final BitmapDescriptor closedMarkerIcon = BitmapDescriptor.fromBytes(
      await _buildMarkerBytes(fillColor: closedColor),
    );
    final BitmapDescriptor selectedOpenMarkerIcon = BitmapDescriptor.fromBytes(
      await _buildMarkerBytes(fillColor: openColor, selected: true),
    );
    final BitmapDescriptor selectedClosedMarkerIcon = BitmapDescriptor.fromBytes(
      await _buildMarkerBytes(fillColor: closedColor, selected: true),
    );
    final BitmapDescriptor userMarkerIcon = BitmapDescriptor.fromBytes(
      await _buildUserMarkerBytes(fillColor: userColor),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _markerBrightness = brightness;
      _openMarkerIcon = openMarkerIcon;
      _closedMarkerIcon = closedMarkerIcon;
      _selectedOpenMarkerIcon = selectedOpenMarkerIcon;
      _selectedClosedMarkerIcon = selectedClosedMarkerIcon;
      _userMarkerIcon = userMarkerIcon;
    });
  }

  Future<Uint8List> _buildMarkerBytes({
    required Color fillColor,
    bool selected = false,
  }) async {
    final double size = selected ? 78 : 62;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Offset center = Offset(size / 2, size / 2);
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: selected ? 0.22 : 0.16)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10);
    final Paint outerPaint = Paint()..color = Colors.white;
    final Paint innerPaint = Paint()..color = fillColor;
    final TextPainter iconPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(Icons.garage_rounded.codePoint),
        style: TextStyle(
          fontSize: selected ? 70 : 67,
          color: Colors.white,
          fontFamily: Icons.garage_rounded.fontFamily,
          package: Icons.garage_rounded.fontPackage,
        ),
      ),
    )..layout();

    canvas.drawCircle(
      Offset(center.dx, center.dy + 3),
      selected ? 22 : 18,
      shadowPaint,
    );
    canvas.drawCircle(center, selected ? 22 : 18, outerPaint);
    canvas.drawCircle(center, selected ? 17 : 14, innerPaint);
    iconPainter.paint(
      canvas,
      Offset(
        center.dx - (iconPainter.width / 2),
        center.dy - (iconPainter.height / 2),
      ),
    );

    final ui.Image image = await recorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _buildUserMarkerBytes({
    required Color fillColor,
  }) async {
    const double size = 54;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Offset center = Offset(size / 2, size / 2);
    final Paint outerPaint = Paint()..color = Colors.white;
    final Paint ringPaint = Paint()..color = fillColor.withValues(alpha: 0.28);
    final Paint innerPaint = Paint()..color = fillColor;

    canvas.drawCircle(center, 16, ringPaint);
    canvas.drawCircle(center, 11, outerPaint);
    canvas.drawCircle(center, 7, innerPaint);

    final ui.Image image = await recorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? <Color>[
                  Color.lerp(AppColors.primaryToneOf(context), Colors.black, 0.18)!,
                  Color.lerp(
                    AppColors.accentOf(context),
                    AppColors.primaryToneOf(context),
                    0.40,
                  )!,
                ]
              : <Color>[
                  AppColors.primarySoftOf(context),
                  AppColors.accentSoftOf(context),
                ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryToneOf(context).withValues(
              alpha: isDark ? 0.18 : 0.12,
            ),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
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
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.primaryToneOf(context)),
          const SizedBox(height: 8),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: 0.10),
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
        const SizedBox(height: 2),
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
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderOf(context)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          icon: child,
        ),
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
      borderRadius: BorderRadius.circular(18),
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
    return AnimatedScale(
      scale: isSelected ? 1 : 0.975,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: isSelected ? Offset.zero : const Offset(0, 0.015),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: 260,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primaryToneOf(context)
                    : AppColors.borderOf(context),
              ),
            ),
            elevation: isSelected ? 4 : 1,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primarySoftOf(context)
                                : AppColors.chipBackgroundOf(context),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.garage_rounded,
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
                    const SizedBox(height: 8),
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
        ),
      ),
    );
  }
}
