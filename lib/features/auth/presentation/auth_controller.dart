import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/realtime/socket_service.dart';
import '../../../core/services/push_token_sync_service.dart';
import '../data/auth_api.dart';
import '../data/device_helper.dart';
import '../data/login_hint_store.dart';
import '../data/passkey_auth_service.dart';
import '../data/token_store.dart';
import '../domain/auth_error_messages.dart';
import '../domain/auth_models.dart';
import '../domain/passkey_exceptions.dart';

class AuthController extends ChangeNotifier with WidgetsBindingObserver {
  AuthController({
    required AuthApi authApi,
    required TokenStore tokenStore,
    LoginHintStore? loginHintStore,
    PasskeyAuthService? passkeyAuthService,
    PushTokenSyncService? pushTokenSyncService,
  })  : _authApi = authApi,
        _tokenStore = tokenStore,
        _loginHintStore = loginHintStore ?? SecureLoginHintStore(),
        _passkeyAuthService = passkeyAuthService ?? PasskeyAuthService(),
        _pushTokenSyncService = pushTokenSyncService;

  final AuthApi _authApi;
  final TokenStore _tokenStore;
  final LoginHintStore _loginHintStore;
  final PasskeyAuthService _passkeyAuthService;
  final PushTokenSyncService? _pushTokenSyncService;

  bool _isBootstrapping = true;
  bool _isBusy = false;
  bool _canResendActivationEmail = false;
  bool _canAddPasskey = false;
  bool _isPasskeyAvailable = false;
  String? _notice;
  String? _error;
  String? _accessToken;
  String _rememberedEmail = '';
  AuthUser? _currentUser;

  // Rate limiting for passkey attempts
  int _passkeyLoginAttempts = 0;
  DateTime? _lastPasskeyLoginAttempt;
  static const int _maxAttemptsPerMinute = 5;
  static const Duration _attemptWindowDuration = Duration(minutes: 1);

  bool get isBootstrapping => _isBootstrapping;
  bool get isBusy => _isBusy;
  bool get canResendActivationEmail => _canResendActivationEmail;
  bool get canAddPasskey => _canAddPasskey;
  bool get isPasskeyAvailable => _isPasskeyAvailable;
  bool get isAuthenticated => _accessToken != null;
  String? get accessToken => _accessToken;
  String get rememberedEmail => _rememberedEmail;
  AuthUser? get currentUser => _currentUser;
  String? get notice => _notice;
  String? get error => _error;

  void clearMessages() {
    _clearMessages();
    notifyListeners();
  }

  Future<void> bootstrap() async {
    _isBootstrapping = true;
    notifyListeners();

    // Add lifecycle observer to detect when app returns to foreground
    WidgetsBinding.instance.addObserver(this);

    await _hydrateRememberedEmail();
    await _refreshPasskeyAvailability();

    final String? token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) {
      _isBootstrapping = false;
      notifyListeners();
      return;
    }

    try {
      _accessToken = token;
      _currentUser = await _authApi.me(token);
      final pushTokenSyncService = _pushTokenSyncService;
      if (pushTokenSyncService != null) {
        unawaited(pushTokenSyncService.syncTokenForCurrentSession());
      }
    } catch (_) {
      await _tokenStore.clearToken();
      _accessToken = null;
      _currentUser = null;
      _notice = AuthErrorMessages.sessionExpired;
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    final String trimmedEmail = email.trim();
    _clearMessages();
    _isBusy = true;
    notifyListeners();

    try {
      final String deviceId = await DeviceHelper.getDeviceId();
      final AuthResult result = await _authApi.login(
        email: trimmedEmail,
        password: password,
        deviceId: deviceId,
      );
      _accessToken = result.accessToken;
      _currentUser = await _authApi.me(result.accessToken);
      _canAddPasskey = result.canAddPasskey;
      _rememberedEmail = trimmedEmail;
      try {
        await _loginHintStore.writeRememberedEmail(trimmedEmail);
      } catch (_) {
        // Storage failures should not block successful authentication.
      }
      _notice = 'Welcome back, ${_currentUser?.displayName ?? 'friend'}.';
      final pushTokenSyncService = _pushTokenSyncService;
      if (pushTokenSyncService != null) {
        unawaited(pushTokenSyncService.syncTokenForCurrentSession());
      }
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      _canResendActivationEmail = _isAccountNotActivatedError(error);
      return false;
    } catch (_) {
      _error = AuthErrorMessages.unexpectedError;
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
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

  Future<bool> resendActivationEmail(String email) async {
    final String trimmedEmail = email.trim();
    _clearMessages();
    _canResendActivationEmail = true;

    if (trimmedEmail.isEmpty) {
      _error = AuthErrorMessages.emailRequiredForResend;
      notifyListeners();
      return false;
    }

    _isBusy = true;
    notifyListeners();

    try {
      final String message = await _authApi.resendConfirmation(trimmedEmail);
      _notice = message;
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } catch (_) {
      _error = AuthErrorMessages.unexpectedError;
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithPasskey({required String email}) async {
    final String resolvedEmail =
        email.trim().isNotEmpty ? email.trim() : _rememberedEmail.trim();

    if (resolvedEmail.isEmpty) {
      _error = AuthErrorMessages.emailRequiredForPasskey;
      notifyListeners();
      return false;
    }

    // Rate limiting check
    if (_shouldThrottlePasskeyAttempt()) {
      _error = AuthErrorMessages.tooManyPasskeyAttempts;
      notifyListeners();
      return false;
    }

    _trackPasskeyAttempt();
    _clearMessages();
    _isBusy = true;
    notifyListeners();

    try {
      final Map<String, dynamic> startOptions =
          await _authApi.startPasskeyLogin(email: resolvedEmail);
      if (kDebugMode) {
        debugPrint(
          'Received passkey login options from server: $startOptions',
          wrapWidth: 1024,
        );
      }

      final Map<String, dynamic> credentialData = await _passkeyAuthService
          .createAuthenticationCredential(startOptions);

      if (kDebugMode) {
        debugPrint(
          'Created passkey credential data: $credentialData',
          wrapWidth: 1024,
        );
        debugPrint(
          'Attempting to finish passkey login with server using credential data.',
        );
      }
      final AuthResult result = await _authApi.finishPasskeyLogin(
        credentialData: credentialData,
      );

      if (kDebugMode) {
        debugPrint(
          'Passkey login successful, received auth result: accessToken=${result.accessToken}, canAddPasskey=${result.canAddPasskey}',
        );
      }

      _accessToken = result.accessToken;
      _currentUser = await _authApi.me(result.accessToken);
      _canAddPasskey = result.canAddPasskey;
      _rememberedEmail = resolvedEmail;
      try {
        await _loginHintStore.writeRememberedEmail(resolvedEmail);
      } catch (_) {
        // Storage failures should not block successful authentication.
      }
      _notice = 'Welcome back, ${_currentUser?.displayName ?? 'friend'}.';
      final pushTokenSyncService = _pushTokenSyncService;
      if (pushTokenSyncService != null) {
        unawaited(pushTokenSyncService.syncTokenForCurrentSession());
      }
      return true;
    } on ApiException catch (error) {
      // Check for network errors and provide helpful context
      if (error.statusCode == 0 ||
          error.message.toLowerCase().contains('internet') ||
          error.message.toLowerCase().contains('network')) {
        _error = AuthErrorMessages.passkeyNetworkError;
      } else {
        _error = error.message;
      }
      return false;
    } on PasskeyAuthCancelledException catch (_) {
      _error = AuthErrorMessages.passkeyAuthCancelled;
      return false;
    } on PasskeyNoCredentialException catch (_) {
      _error = AuthErrorMessages.passkeyNoCredential;
      return false;
    } on PasskeyNotSupportedException catch (_) {
      _error = AuthErrorMessages.passkeyNotSupported;
      return false;
    } on PasskeySecurityException catch (_) {
      _error = AuthErrorMessages.passkeySecurityFailed;
      return false;
    } catch (unknownError) {
      if (kDebugMode) {
        debugPrint('Passkey sign-in failed: ${unknownError.runtimeType}');
      }
      final String details = unknownError.toString();
      if (details.contains('NoCredentialException') ||
          details.contains('Cannot find a matching credential')) {
        _error = AuthErrorMessages.passkeyNoCredential;
      } else {
        _error = AuthErrorMessages.passkeyAuthFailed;
      }
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> registerPasskeyForCurrentUser() async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      _error = AuthErrorMessages.loginRequired;
      notifyListeners();
      return false;
    }

    return registerPasskeyWithToken(_accessToken!);
  }

  Future<bool> registerPasskeyWithToken(String bearerToken) async {
    if (_isBusy) {
      return false; // Already processing
    }

    if (bearerToken.trim().isEmpty) {
      _error = AuthErrorMessages.tokenRequired;
      notifyListeners();
      return false;
    }

    // Add basic JWT format validation
    if (!_isValidJwtFormat(bearerToken)) {
      _error = AuthErrorMessages.tokenFormatInvalid;
      notifyListeners();
      return false;
    }

    // Add expiration check
    if (_isTokenExpired(bearerToken)) {
      _error = AuthErrorMessages.tokenExpired;
      notifyListeners();
      return false;
    }

    _clearMessages();
    _isBusy = true;
    notifyListeners();

    try {
      final String deviceId = await DeviceHelper.getDeviceId();
      final String platform = DeviceHelper.getPlatformName();
      final Map<String, dynamic> startOptions =
          await _authApi.startPasskeyRegistration(bearerToken: bearerToken);
      final Map<String, dynamic> credentialData =
          await _passkeyAuthService.createRegistrationCredential(startOptions);
      await _authApi.finishPasskeyRegistration(
        bearerToken: bearerToken,
        credentialData: credentialData,
        deviceId: deviceId,
        platform: platform,
      );
      _canAddPasskey = false;
      _notice = AuthErrorMessages.passkeyAdded;
      return true;
    } on ApiException catch (error) {
      // Check for network errors and provide helpful context
      if (error.statusCode == 0 ||
          error.message.toLowerCase().contains('internet') ||
          error.message.toLowerCase().contains('network')) {
        _error = AuthErrorMessages.passkeyNetworkUnavailableRegistration;
      } else if (error.statusCode == 409) {
        _error = AuthErrorMessages.passkeyDuplicate;
      } else {
        _error = error.message;
      }
      return false;
    } on PasskeyAuthCancelledException catch (_) {
      _error = AuthErrorMessages.passkeyRegistrationCancelled;
      return false;
    } catch (unknownError) {
      if (kDebugMode) {
        debugPrint('Passkey registration failed: $unknownError');
      }
      _error = AuthErrorMessages.passkeyRegistrationFailed;
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(
      {required String token, required String password}) async {
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
    SocketService().emitDrawLeave();
    final pushTokenSyncService = _pushTokenSyncService;
    if (pushTokenSyncService != null) {
      unawaited(pushTokenSyncService.deactivateCurrentTokenBinding());
    }
    await _tokenStore.clearToken();
    _accessToken = null;
    _currentUser = null;
    _canAddPasskey = false;
    // Reset rate limiting counters
    _passkeyLoginAttempts = 0;
    _lastPasskeyLoginAttempt = null;
    _clearMessages();
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
      _error = AuthErrorMessages.unexpectedError;
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
    _canResendActivationEmail = false;
  }

  Future<void> _hydrateRememberedEmail() async {
    try {
      final String? savedEmail = await _loginHintStore.readRememberedEmail();
      _rememberedEmail = savedEmail?.trim() ?? '';
    } catch (_) {
      _rememberedEmail = '';
    }
  }

  Future<void> _refreshPasskeyAvailability() async {
    _isPasskeyAvailable = await _passkeyAuthService.isAvailable();
  }

  Future<void> refreshPasskeyAvailability({bool notify = true}) async {
    _isPasskeyAvailable = await _passkeyAuthService.isAvailable();
    if (notify) {
      notifyListeners();
    }
  }

  bool _isAccountNotActivatedError(ApiException error) {
    if (error.statusCode != 401) {
      return false;
    }

    final String normalized = error.message.toLowerCase();
    return normalized.contains('account not activated') ||
        normalized.contains('not activated');
  }

  /// Validates that a token has the basic JWT format (three parts separated by dots).
  bool _isValidJwtFormat(String token) {
    final parts = token.split('.');
    return parts.length == 3;
  }

  /// Checks if a JWT token is expired by decoding the payload and checking the 'exp' claim.
  /// Returns true if the token is expired or cannot be parsed.
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final Map<String, dynamic> claims = jsonDecode(payload);

      if (claims['exp'] == null) return false;

      final expiration =
          DateTime.fromMillisecondsSinceEpoch(claims['exp'] * 1000);
      return DateTime.now().isAfter(expiration);
    } catch (_) {
      return true; // Treat parsing errors as expired
    }
  }

  /// Checks if passkey attempts should be throttled based on rate limiting.
  bool _shouldThrottlePasskeyAttempt() {
    if (_lastPasskeyLoginAttempt == null) return false;

    final timeSinceLastAttempt =
        DateTime.now().difference(_lastPasskeyLoginAttempt!);

    if (timeSinceLastAttempt > _attemptWindowDuration) {
      _passkeyLoginAttempts = 0;
      return false;
    }

    return _passkeyLoginAttempts >= _maxAttemptsPerMinute;
  }

  /// Tracks a passkey attempt for rate limiting purposes.
  void _trackPasskeyAttempt() {
    final now = DateTime.now();
    if (_lastPasskeyLoginAttempt != null) {
      final timeSinceLastAttempt = now.difference(_lastPasskeyLoginAttempt!);
      if (timeSinceLastAttempt > _attemptWindowDuration) {
        _passkeyLoginAttempts = 0;
      }
    }

    _lastPasskeyLoginAttempt = now;
    _passkeyLoginAttempts++;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recheck passkey availability when app returns to foreground
      // This handles the case where user sets up biometrics while app is in background
      _refreshPasskeyAvailability();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
