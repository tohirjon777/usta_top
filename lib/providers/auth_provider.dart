import 'package:flutter/foundation.dart';

import '../core/storage/auth_token_storage.dart';
import '../models/saved_vehicle_profile.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService authService,
    required AuthTokenStorage tokenStorage,
  })  : _authService = authService,
        _tokenStorage = tokenStorage;

  final AuthService _authService;
  final AuthTokenStorage _tokenStorage;

  bool _isLoadingSession = true;
  bool _isLoadingProfile = false;
  bool _isLoggedIn = false;
  String? _accessToken;
  String? _errorMessage;
  AuthUser? _currentUser;

  bool get isLoadingSession => _isLoadingSession;
  bool get isLoadingProfile => _isLoadingProfile;
  bool get isLoggedIn => _isLoggedIn;
  String? get accessToken => _accessToken;
  String? get errorMessage => _errorMessage;
  AuthUser? get currentUser => _currentUser;

  Future<void> restoreSession() async {
    _isLoadingSession = true;
    _errorMessage = null;
    notifyListeners();

    final bool hasSession = await _tokenStorage.hasValidSession();
    final String? token = await _tokenStorage.getAccessToken();
    if (!hasSession || token == null || token.isEmpty) {
      _isLoggedIn = false;
      _accessToken = null;
      _currentUser = null;
      _isLoadingSession = false;
      notifyListeners();
      return;
    }

    _isLoggedIn = true;
    _accessToken = token;
    await _fetchCurrentUser(
      accessToken: token,
      setProfileLoading: false,
    );
    _isLoadingSession = false;
    notifyListeners();
  }

  Future<bool> signIn({
    required String phone,
    required String password,
  }) async {
    try {
      _errorMessage = null;
      // TODO(API): Login so'rovi AuthService.login orqali backendga ketadi.
      final AuthSession session = await _authService.login(
        phone: phone,
        password: password,
      );

      await _tokenStorage.saveSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        expiresAt: session.expiresAt,
      );

      _isLoggedIn = true;
      _accessToken = session.accessToken;
      notifyListeners();
      await _fetchCurrentUser(
        accessToken: session.accessToken,
        setProfileLoading: false,
      );
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      _isLoggedIn = false;
      _accessToken = null;
      _currentUser = null;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Kirishda xatolik yuz berdi';
      _isLoggedIn = false;
      _accessToken = null;
      _currentUser = null;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String fullName,
    required String phone,
    required String password,
  }) async {
    try {
      _errorMessage = null;
      final AuthSession session = await _authService.signUp(
        fullName: fullName,
        phone: phone,
        password: password,
      );

      await _tokenStorage.saveSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        expiresAt: session.expiresAt,
      );

      _isLoggedIn = true;
      _accessToken = session.accessToken;
      notifyListeners();
      await _fetchCurrentUser(
        accessToken: session.accessToken,
        setProfileLoading: false,
      );
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      _isLoggedIn = false;
      _accessToken = null;
      _currentUser = null;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Ro\'yxatdan o\'tishda xatolik yuz berdi';
      _isLoggedIn = false;
      _accessToken = null;
      _currentUser = null;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String phone,
    required String newPassword,
  }) async {
    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(
        phone: phone,
        newPassword: newPassword,
      );
      _errorMessage = null;
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Parolni tiklashda xatolik yuz berdi';
      return false;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentUser() async {
    final String? token = _accessToken;
    if (!_isLoggedIn || token == null || token.isEmpty) {
      return;
    }

    await _fetchCurrentUser(
      accessToken: token,
      setProfileLoading: true,
    );
  }

  Future<bool> updateCurrentUserProfile({
    required String fullName,
    required String phone,
  }) async {
    final String? token = _accessToken;
    if (!_isLoggedIn || token == null || token.isEmpty) {
      return false;
    }

    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.updateCurrentUserProfile(
        accessToken: token,
        fullName: fullName,
        phone: phone,
      );
      _errorMessage = null;
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      if (error.statusCode == 401) {
        await _tokenStorage.clearSession();
        _isLoggedIn = false;
        _accessToken = null;
        _currentUser = null;
      }
      return false;
    } catch (_) {
      _errorMessage = 'Profil ma\'lumotini yangilashda xatolik yuz berdi';
      return false;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final String? token = _accessToken;
    if (!_isLoggedIn || token == null || token.isEmpty) {
      return false;
    }

    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.changePassword(
        accessToken: token,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _errorMessage = null;
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      if (error.statusCode == 401) {
        await _tokenStorage.clearSession();
        _isLoggedIn = false;
        _accessToken = null;
        _currentUser = null;
      }
      return false;
    } catch (_) {
      _errorMessage = 'Parolni yangilashda xatolik yuz berdi';
      return false;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> sendTestPush() async {
    final String? token = _accessToken;
    if (!_isLoggedIn || token == null || token.isEmpty) {
      return false;
    }

    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendTestPush(accessToken: token);
      _errorMessage = null;
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Test push yuborishda xatolik yuz berdi';
      return false;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _tokenStorage.clearSession();
    _isLoggedIn = false;
    _accessToken = null;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void rememberVehicleProfile(SavedVehicleProfile vehicle) {
    final AuthUser? currentUser = _currentUser;
    if (currentUser == null) {
      return;
    }

    _currentUser = currentUser.copyWith(
      savedVehicles: SavedVehicleProfile.upsert(
        currentUser.savedVehicles,
        vehicle: vehicle,
      ),
    );
    notifyListeners();
  }

  Future<void> _fetchCurrentUser({
    required String accessToken,
    required bool setProfileLoading,
  }) async {
    if (setProfileLoading) {
      _isLoadingProfile = true;
      notifyListeners();
    }

    try {
      // TODO(API): Profil so'rovi AuthService.getCurrentUser orqali /auth/me ga ketadi.
      _currentUser = await _authService.getCurrentUser(
        accessToken: accessToken,
      );
      _errorMessage = null;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      if (error.statusCode == 401) {
        await _tokenStorage.clearSession();
        _isLoggedIn = false;
        _accessToken = null;
        _currentUser = null;
      }
    } catch (_) {
      _errorMessage = 'Profil ma\'lumotini yuklashda xatolik yuz berdi';
    } finally {
      if (setProfileLoading) {
        _isLoadingProfile = false;
      }
      notifyListeners();
    }
  }
}
