import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/salon.dart';
import '../services/api_exception.dart';
import '../services/workshop_service.dart';

class WorkshopProvider extends ChangeNotifier {
  WorkshopProvider({required WorkshopService service}) : _service = service;

  final WorkshopService _service;

  bool _isLoading = false;
  bool _isResolvingLocation = false;
  String? _errorMessage;
  String? _locationErrorMessage;
  String _query = '';
  List<Salon> _workshops = <Salon>[];
  double? _userLatitude;
  double? _userLongitude;

  bool get isLoading => _isLoading;
  bool get isResolvingLocation => _isResolvingLocation;
  String? get errorMessage => _errorMessage;
  String? get locationErrorMessage => _locationErrorMessage;
  bool get hasUserLocation => _userLatitude != null && _userLongitude != null;
  String get query => _query;
  int get totalCount => _workshops.length;
  List<Salon> get allWorkshops => List<Salon>.unmodifiable(_workshops);

  List<Salon> get workshops {
    if (_query.isEmpty) {
      return List<Salon>.unmodifiable(_workshops);
    }

    final String q = _query.toLowerCase();
    final List<Salon> filtered = _workshops.where((Salon workshop) {
      final bool matchName = workshop.name.toLowerCase().contains(q);
      final bool matchAddress = workshop.address.toLowerCase().contains(q);
      final bool matchServices = workshop.services.any(
        (SalonService service) => service.name.toLowerCase().contains(q),
      );
      return matchName || matchAddress || matchServices;
    }).toList(growable: false);

    return List<Salon>.unmodifiable(filtered);
  }

  Salon? workshopById(String id) {
    for (final Salon workshop in _workshops) {
      if (workshop.id == id) {
        return workshop;
      }
    }
    return null;
  }

  Future<void> loadWorkshops({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // TODO(API): Workshop ro'yxati WorkshopService.fetchFeaturedWorkshops bilan olinadi.
      _workshops = _applyUserDistances(await _service.fetchFeaturedWorkshops());
      _errorMessage = null;
    } on ApiException catch (error) {
      if (!silent) {
        _errorMessage = error.message;
      }
    } catch (_) {
      if (!silent) {
        _errorMessage = 'Servislarni yuklashda xatolik yuz berdi';
      }
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> refreshDistancesFromCurrentLocation({
    bool requestPermission = false,
  }) async {
    if (_isResolvingLocation) {
      return;
    }

    _isResolvingLocation = true;
    _locationErrorMessage = null;
    notifyListeners();

    try {
      final bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _locationErrorMessage = 'Joylashuv xizmati o\'chiq';
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _locationErrorMessage = 'Joylashuv ruxsati berilmadi';
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      updateDistancesFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        notify: false,
      );
    } catch (_) {
      _locationErrorMessage = 'Joriy joylashuvni aniqlab bo\'lmadi';
    } finally {
      _isResolvingLocation = false;
      notifyListeners();
    }
  }

  void updateDistancesFromCoordinates({
    required double latitude,
    required double longitude,
    bool notify = true,
  }) {
    _userLatitude = latitude;
    _userLongitude = longitude;
    _locationErrorMessage = null;
    _workshops = _applyUserDistances(_workshops);
    if (notify) {
      notifyListeners();
    }
  }

  void setQuery(String value) {
    if (_query == value) {
      return;
    }
    _query = value;
    notifyListeners();
  }

  Future<Salon?> refreshWorkshopById(String id) async {
    try {
      final Salon salon = await _service.fetchWorkshopById(id);
      _upsertWorkshop(salon);
      return salon;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return null;
    } catch (_) {
      _errorMessage = 'Servis ma\'lumotini yangilab bo\'lmadi';
      notifyListeners();
      return null;
    }
  }

  Future<Salon?> submitReview({
    required String workshopId,
    required String serviceId,
    required int rating,
    required String comment,
    String? bookingId,
  }) async {
    try {
      final Salon updated = await _service.submitReview(
        workshopId: workshopId,
        serviceId: serviceId,
        rating: rating,
        comment: comment,
        bookingId: bookingId,
      );
      _upsertWorkshop(updated);
      return updated;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return null;
    } catch (_) {
      _errorMessage = 'Sharh yuborishda xatolik yuz berdi';
      notifyListeners();
      return null;
    }
  }

  void _upsertWorkshop(Salon salon) {
    final int index =
        _workshops.indexWhere((Salon item) => item.id == salon.id);
    final Salon resolvedSalon = _applyUserDistance(salon);
    if (index < 0) {
      _workshops.insert(0, resolvedSalon);
    } else {
      _workshops[index] = resolvedSalon;
    }
    notifyListeners();
  }

  List<Salon> _applyUserDistances(List<Salon> workshops) {
    if (!hasUserLocation) {
      return workshops;
    }

    return workshops.map(_applyUserDistance).toList(growable: false);
  }

  Salon _applyUserDistance(Salon workshop) {
    final double? userLatitude = _userLatitude;
    final double? userLongitude = _userLongitude;
    final double? workshopLatitude = workshop.latitude;
    final double? workshopLongitude = workshop.longitude;
    if (userLatitude == null ||
        userLongitude == null ||
        workshopLatitude == null ||
        workshopLongitude == null) {
      return workshop;
    }

    final double distanceKm = _distanceKm(
      userLatitude,
      userLongitude,
      workshopLatitude,
      workshopLongitude,
    );

    return workshop.copyWith(
      distanceKm: (distanceKm * 10).roundToDouble() / 10,
    );
  }

  double _distanceKm(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const double earthRadiusKm = 6371;
    final double lat1 = _degreesToRadians(startLatitude);
    final double lat2 = _degreesToRadians(endLatitude);
    final double deltaLat = _degreesToRadians(endLatitude - startLatitude);
    final double deltaLng = _degreesToRadians(endLongitude - startLongitude);
    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}
