import 'package:flutter/foundation.dart';

import '../models/salon.dart';
import '../services/api_exception.dart';
import '../services/workshop_service.dart';

class WorkshopProvider extends ChangeNotifier {
  WorkshopProvider({required WorkshopService service}) : _service = service;

  final WorkshopService _service;

  bool _isLoading = false;
  String? _errorMessage;
  String _query = '';
  List<Salon> _workshops = <Salon>[];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
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

  Future<void> loadWorkshops() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO(API): Workshop ro'yxati WorkshopService.fetchFeaturedWorkshops bilan olinadi.
      _workshops = await _service.fetchFeaturedWorkshops();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Servislarni yuklashda xatolik yuz berdi';
    } finally {
      _isLoading = false;
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
    final int index = _workshops.indexWhere((Salon item) => item.id == salon.id);
    if (index < 0) {
      _workshops.insert(0, salon);
    } else {
      _workshops[index] = salon;
    }
    notifyListeners();
  }
}
