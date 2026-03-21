import 'package:flutter/foundation.dart';

class BackendConfig {
  const BackendConfig._();

  static String resolveBaseUrl() {
    // TODO(API): Eng to'g'ri yo'l - ishga tushirishda `API_BASE_URL` berish.
    const String fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
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
