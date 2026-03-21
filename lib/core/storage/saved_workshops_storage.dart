import 'package:shared_preferences/shared_preferences.dart';

class SavedWorkshopsStorage {
  const SavedWorkshopsStorage();

  static const String _savedWorkshopIdsKey = 'saved_workshop_ids';

  Future<List<String>> loadIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_savedWorkshopIdsKey) ?? <String>[];
  }

  Future<void> saveIds(Iterable<String> ids) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _savedWorkshopIdsKey, ids.toList(growable: false));
  }
}
