import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_navigation_intent.dart';
import '../providers/auth_provider.dart';
import '../providers/app_navigation_provider.dart';
import '../providers/notification_settings_provider.dart';
import '../services/auth_service.dart';

const AndroidNotificationChannel _bookingUpdatesChannel =
    AndroidNotificationChannel(
  'booking_updates',
  'Zakaz yangilanishlari',
  description: 'Zakaz statusi o‘zgarganda ko‘rsatiladigan xabarnomalar',
  importance: Importance.max,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase config bo'lmasa background init sokin o'tkaziladi.
  }
}

class PushNotificationsProvider extends ChangeNotifier {
  PushNotificationsProvider({
    required AuthProvider authProvider,
    required AppNavigationProvider appNavigationProvider,
    required NotificationSettingsProvider notificationSettingsProvider,
    required AuthService authService,
  })  : _authProvider = authProvider,
        _appNavigationProvider = appNavigationProvider,
        _notificationSettingsProvider = notificationSettingsProvider,
        _authService = authService;

  final AuthProvider _authProvider;
  final AppNavigationProvider _appNavigationProvider;
  final NotificationSettingsProvider _notificationSettingsProvider;
  final AuthService _authService;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool _isInitialized = false;
  bool _isFirebaseReady = false;
  bool _isSyncing = false;
  String? _registeredPushToken;
  String? _lastKnownAccessToken;
  String? _lastError;

  bool get isFirebaseReady => _isFirebaseReady;
  String? get lastError => _lastError;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    _authProvider.addListener(_handleDependenciesChanged);
    _notificationSettingsProvider.addListener(_handleDependenciesChanged);

    if (!_supportsPushNotifications) {
      return;
    }

    try {
      await Firebase.initializeApp();
      _isFirebaseReady = true;
    } catch (_) {
      _lastError = 'Firebase konfiguratsiyasi topilmadi';
      notifyListeners();
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _initializeLocalNotifications();
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _messageSubscription =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _messageOpenedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
      (String token) {
        unawaited(_syncPushToken(forcedToken: token));
      },
    );

    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpened(initialMessage);
    }

    await _syncPushToken();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleDependenciesChanged);
    _notificationSettingsProvider.removeListener(_handleDependenciesChanged);
    _messageSubscription?.cancel();
    _messageOpenedSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }

  void _handleDependenciesChanged() {
    unawaited(_syncPushToken());
  }

  Future<void> _initializeLocalNotifications() async {
    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (
        NotificationResponse response,
      ) {
        _handleNotificationPayload(response.payload);
      },
    );
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_bookingUpdatesChannel);
  }

  Future<void> _syncPushToken({
    String? forcedToken,
  }) async {
    if (!_isFirebaseReady ||
        !_notificationSettingsProvider.isLoaded ||
        _isSyncing) {
      return;
    }

    final String? accessToken = _authProvider.accessToken;
    if (!_authProvider.isLoggedIn || accessToken == null || accessToken.isEmpty) {
      final String? existingToken = _registeredPushToken;
      final String? lastKnownAccessToken = _lastKnownAccessToken;
      if (existingToken != null &&
          lastKnownAccessToken != null &&
          lastKnownAccessToken.isNotEmpty) {
        try {
          await _authService.unregisterPushToken(
            accessToken: lastKnownAccessToken,
            token: existingToken,
          );
        } catch (_) {
          // Logout paytida xatolik bo'lsa ham app oqimini to'xtatmaymiz.
        }
      }
      _registeredPushToken = null;
      _lastKnownAccessToken = null;
      return;
    }

    _lastKnownAccessToken = accessToken;

    _isSyncing = true;
    try {
      if (!_notificationSettingsProvider.isEnabled) {
        final String? existingToken = _registeredPushToken;
        if (existingToken != null) {
          await _authService.unregisterPushToken(
            accessToken: accessToken,
            token: existingToken,
          );
          _registeredPushToken = null;
        }
        _lastError = null;
        notifyListeners();
        return;
      }

      final NotificationSettings permissionSettings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (!_isPermissionGranted(permissionSettings)) {
        final String? existingToken = _registeredPushToken;
        if (existingToken != null) {
          await _authService.unregisterPushToken(
            accessToken: accessToken,
            token: existingToken,
          );
          _registeredPushToken = null;
        }
        _lastError = 'Notification ruxsati berilmagan';
        notifyListeners();
        return;
      }

      final String? token =
          forcedToken ?? await FirebaseMessaging.instance.getToken();
      if (token == null || token.trim().isEmpty) {
        _lastError = 'Push token olib bo‘lmadi';
        notifyListeners();
        return;
      }

      if (_registeredPushToken == token) {
        _lastError = null;
        notifyListeners();
        return;
      }

      final String? previousToken = _registeredPushToken;
      await _authService.registerPushToken(
        accessToken: accessToken,
        token: token,
        platform: _platformName,
      );
      if (previousToken != null && previousToken != token) {
        await _authService.unregisterPushToken(
          accessToken: accessToken,
          token: previousToken,
        );
      }
      _registeredPushToken = token;
      _lastError = null;
      notifyListeners();
    } catch (_) {
      _lastError = 'Push notificationni sozlashda xatolik yuz berdi';
      notifyListeners();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    if (notification == null) {
      return;
    }

    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _bookingUpdatesChannel.id,
        _bookingUpdatesChannel.name,
        channelDescription: _bookingUpdatesChannel.description,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotificationsPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: _encodePayload(message.data),
    );
  }

  void _handleMessageOpened(RemoteMessage message) {
    _queueNavigationIntent(AppNavigationIntent.fromPushData(message.data));
  }

  void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return;
    }

    try {
      final dynamic decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _queueNavigationIntent(AppNavigationIntent.fromPushData(decoded));
      }
    } on FormatException {
      // Notification payload o'qilmasa foydalanuvchi oqimini to'xtatmaymiz.
    }
  }

  void _queueNavigationIntent(AppNavigationIntent? intent) {
    if (intent == null) {
      return;
    }
    _appNavigationProvider.queueIntent(intent);
  }

  String? _encodePayload(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return null;
    }

    final Map<String, String> normalized = <String, String>{};
    data.forEach((Object? key, Object? value) {
      final String stringKey = key?.toString().trim() ?? '';
      if (stringKey.isEmpty) {
        return;
      }
      normalized[stringKey] = value?.toString() ?? '';
    });
    if (normalized.isEmpty) {
      return null;
    }
    return jsonEncode(normalized);
  }

  bool get _supportsPushNotifications {
    if (kIsWeb) {
      return false;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return false;
    }
  }

  bool _isPermissionGranted(NotificationSettings settings) {
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  String get _platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return 'unknown';
    }
  }
}
