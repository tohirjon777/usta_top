import 'package:flutter/foundation.dart';

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
    final String? normalizedOverride =
        overrideBaseUrl == null || overrideBaseUrl.trim().isEmpty
            ? null
            : normalizeBaseUrl(overrideBaseUrl);
    if (normalizedOverride != null) {
      return normalizedOverride;
    }

    // TODO(API): Eng to'g'ri yo'l - ishga tushirishda `API_BASE_URL` berish.
    final String? fromDefine = definedBaseUrl;
    if (fromDefine != null) {
      return fromDefine;
    }

    if (kReleaseMode) {
      return productionBaseUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8080';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // TODO(API): Android emulator localhostga 10.0.2.2 orqali chiqadi.
        return 'http://10.0.2.2:8080';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:8080';
    }
  }
}
