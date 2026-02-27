import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_api.dart';
import '../data/token_store.dart';
import '../domain/auth_models.dart';

class AuthController extends ChangeNotifier {
  AuthController({required AuthApi authApi, required TokenStore tokenStore})
      : _authApi = authApi,
        _tokenStore = tokenStore;

  final AuthApi _authApi;
  final TokenStore _tokenStore;

  bool _isBootstrapping = true;
  bool _isBusy = false;
  String? _notice;
  String? _error;
  String? _accessToken;
  AuthUser? _currentUser;

  bool get isBootstrapping => _isBootstrapping;
  bool get isBusy => _isBusy;
  bool get isAuthenticated => _accessToken != null;
  AuthUser? get currentUser => _currentUser;
  String? get notice => _notice;
  String? get error => _error;

  Future<void> bootstrap() async {
    _isBootstrapping = true;
    notifyListeners();

    final String? token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) {
      _isBootstrapping = false;
      notifyListeners();
      return;
    }

    try {
      _accessToken = token;
      _currentUser = await _authApi.me(token);
    } catch (_) {
      await _tokenStore.clearToken();
      _accessToken = null;
      _currentUser = null;
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    return _runGuarded<bool>(() async {
      _clearMessages();
      final AuthResult result = await _authApi.login(email: email, password: password);
      _accessToken = result.accessToken;
      _currentUser = await _authApi.me(result.accessToken);
      _notice = 'Welcome back, ${_currentUser?.displayName ?? 'friend'}.';
      return true;
    }, fallback: false);
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return _runGuarded<bool>(() async {
      _clearMessages();
      final String message = await _authApi.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      _notice = message;
      return true;
    }, fallback: false);
  }

  Future<bool> forgotPassword(String email) async {
    return _runGuarded<bool>(() async {
      _clearMessages();
      final String message = await _authApi.forgotPassword(email);
      _notice = message;
      return true;
    }, fallback: false);
  }

  Future<bool> resetPassword({required String token, required String password}) async {
    return _runGuarded<bool>(() async {
      _clearMessages();
      final ResetPasswordResult result =
          await _authApi.resetPassword(token: token, password: password);
      _notice = result.message;
      return result.status == 'success';
    }, fallback: false);
  }

  Future<bool> checkDisplayNameAvailability(String name) async {
    return _runGuarded<bool>(
      () => _authApi.checkDisplayNameAvailability(name),
      fallback: false,
      mutateBusyState: false,
      clearMessagesBefore: false,
    );
  }

  Future<void> logout() async {
    await _tokenStore.clearToken();
    _accessToken = null;
    _currentUser = null;
    _notice = 'You have been logged out.';
    _error = null;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  void clearNotice() {
    if (_notice == null) {
      return;
    }
    _notice = null;
    notifyListeners();
  }

  Future<T> _runGuarded<T>(
    Future<T> Function() action, {
    required T fallback,
    bool mutateBusyState = true,
    bool clearMessagesBefore = true,
  }) async {
    try {
      if (clearMessagesBefore) {
        _clearMessages();
      }
      if (mutateBusyState) {
        _isBusy = true;
        notifyListeners();
      }
      final T result = await action();
      return result;
    } on ApiException catch (error) {
      _error = error.message;
      return fallback;
    } catch (_) {
      _error = 'Unexpected error. Please try again.';
      return fallback;
    } finally {
      if (mutateBusyState) {
        _isBusy = false;
      }
      notifyListeners();
    }
  }

  void _clearMessages() {
    _notice = null;
    _error = null;
  }
}
