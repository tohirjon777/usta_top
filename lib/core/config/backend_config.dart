class BackendConfig {
  const BackendConfig._();

  static const String productionBaseUrl = 'http://45.80.148.221';

  static const String releaseBaseUrlRequiredMessage =
      'Release build requires --dart-define=API_BASE_URL=https://your-domain';

  static String? get definedBaseUrl {
    const String fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isEmpty) {
      return null;
    }
    return normalizeBaseUrl(fromDefine);
  }

  static String normalizeBaseUrl(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }

  static bool get hasDefinedBaseUrl => definedBaseUrl != null;

  static String resolveBaseUrl({
    String? overrideBaseUrl,
  }) {
    return productionBaseUrl;
  }
}
