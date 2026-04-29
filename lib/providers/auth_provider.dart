import 'package:flutter/foundation.dart';

import '../core/storage/auth_token_storage.dart';
import '../models/saved_payment_card.dart';
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
      _clearAuthState();
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

  Future<AuthOtpChallenge?> requestSignUpCode({
    required String phone,
  }) async {
    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final AuthOtpChallenge challenge = await _authService.sendSignUpCode(
        phone: phone,
      );
      _errorMessage = null;
      return challenge;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Tasdiqlash kodini yuborishda xatolik yuz berdi';
      return null;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> verifySignUpCode({
    required String fullName,
    required String phone,
    required String password,
    required String code,
  }) async {
    try {
      _errorMessage = null;
      final AuthSession session = await _authService.verifySignUpCode(
        fullName: fullName,
        phone: phone,
        password: password,
        code: code,
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
      _errorMessage = 'Akkauntni tasdiqlashda xatolik yuz berdi';
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

  Future<AuthOtpChallenge?> requestPasswordResetCode({
    required String phone,
  }) async {
    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final AuthOtpChallenge challenge =
          await _authService.sendPasswordResetCode(
        phone: phone,
      );
      _errorMessage = null;
      return challenge;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Tasdiqlash kodini yuborishda xatolik yuz berdi';
      return null;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> verifyPasswordResetCode({
    required String phone,
    required String newPassword,
    required String code,
  }) async {
    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.verifyPasswordResetCode(
        phone: phone,
        newPassword: newPassword,
        code: code,
      );
      _errorMessage = null;
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Parolni tasdiqlashda xatolik yuz berdi';
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

  Future<bool> uploadCurrentUserAvatar({
    required List<int> bytes,
    required String fileName,
  }) async {
    final String? token = _accessToken;
    if (!_isLoggedIn || token == null || token.isEmpty) {
      return false;
    }

    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.uploadCurrentUserAvatar(
        accessToken: token,
        bytes: bytes,
        fileName: fileName,
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
      _errorMessage = 'Avatarni yangilashda xatolik yuz berdi';
      return false;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> addPaymentCard({
    required String holderName,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required bool isDefault,
  }) async {
    final String? token = _accessToken;
    if (!_isLoggedIn || token == null || token.isEmpty) {
      return false;
    }

    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.addPaymentCard(
        accessToken: token,
        holderName: holderName,
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        isDefault: isDefault,
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
      _errorMessage = 'Kartani saqlashda xatolik yuz berdi';
      return false;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> updatePaymentCard({
    required String cardId,
    required String holderName,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required bool isDefault,
  }) async {
    final String? token = _accessToken;
    if (!_isLoggedIn || token == null || token.isEmpty) {
      return false;
    }

    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.updatePaymentCard(
        accessToken: token,
        cardId: cardId,
        holderName: holderName,
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        isDefault: isDefault,
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
      _errorMessage = 'Kartani yangilashda xatolik yuz berdi';
      return false;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> deletePaymentCard({
    required String cardId,
  }) async {
    final String? token = _accessToken;
    if (!_isLoggedIn || token == null || token.isEmpty) {
      return false;
    }

    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.deletePaymentCard(
        accessToken: token,
        cardId: cardId,
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
      _errorMessage = 'Kartani o\'chirishda xatolik yuz berdi';
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
    _clearAuthState();
    notifyListeners();
  }

  void _clearAuthState() {
    _isLoggedIn = false;
    _accessToken = null;
    _currentUser = null;
    _errorMessage = null;
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

  void rememberPaymentCard(SavedPaymentCard card) {
    final AuthUser? currentUser = _currentUser;
    if (currentUser == null) {
      return;
    }

    final List<SavedPaymentCard> nextCards = <SavedPaymentCard>[
      ...currentUser.savedPaymentCards.where(
        (SavedPaymentCard item) => item.id != card.id,
      ),
      card,
    ];
    nextCards.sort((SavedPaymentCard a, SavedPaymentCard b) {
      if (a.isDefault && !b.isDefault) {
        return -1;
      }
      if (!a.isDefault && b.isDefault) {
        return 1;
      }
      final DateTime aTime =
          a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bTime =
          b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    _currentUser = currentUser.copyWith(
      savedPaymentCards: List<SavedPaymentCard>.unmodifiable(nextCards),
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
