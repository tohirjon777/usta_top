import 'package:shared_preferences/shared_preferences.dart';

class BackendEndpointStorage {
  const BackendEndpointStorage();

  static const String _backendEndpointKey = 'backend_endpoint_override';

  Future<String?> loadBaseUrl() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? value = prefs.getString(_backendEndpointKey)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  Future<void> saveBaseUrl(String baseUrl) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendEndpointKey, baseUrl.trim());
  }

  Future<void> clearBaseUrl() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backendEndpointKey);
  }
}
