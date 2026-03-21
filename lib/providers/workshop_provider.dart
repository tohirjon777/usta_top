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
}
