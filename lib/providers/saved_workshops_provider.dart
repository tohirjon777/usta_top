import 'package:flutter/foundation.dart';

import '../core/storage/saved_workshops_storage.dart';

class SavedWorkshopsProvider extends ChangeNotifier {
  SavedWorkshopsProvider({
    required SavedWorkshopsStorage storage,
  }) : _storage = storage;

  final SavedWorkshopsStorage _storage;
  final Set<String> _savedIds = <String>{};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<String> get savedIds => List<String>.unmodifiable(_savedIds);

  bool isSaved(String workshopId) => _savedIds.contains(workshopId);

  Future<void> restoreSaved() async {
    final List<String> ids = await _storage.loadIds();
    _savedIds
      ..clear()
      ..addAll(ids);
    _isLoaded = true;
    notifyListeners();
  }

  Future<bool> toggleSaved(String workshopId) async {
    final bool shouldSave = !_savedIds.contains(workshopId);
    if (shouldSave) {
      _savedIds.add(workshopId);
    } else {
      _savedIds.remove(workshopId);
    }
    notifyListeners();

    try {
      await _storage.saveIds(_savedIds);
      return shouldSave;
    } catch (_) {
      if (shouldSave) {
        _savedIds.remove(workshopId);
      } else {
        _savedIds.add(workshopId);
      }
      notifyListeners();
      rethrow;
    }
  }
}
