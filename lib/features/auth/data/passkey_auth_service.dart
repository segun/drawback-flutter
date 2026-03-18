import 'package:drawback_flutter/features/auth/data/device_helper.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/availability.dart';
import 'package:passkeys/types.dart' hide PasskeyAuthCancelledException;
import '../domain/passkey_exceptions.dart';
import '../domain/passkey_models.dart';

class PasskeyAuthService {
  PasskeyAuthService({PasskeyAuthenticator? authenticator})
      : _authenticator = authenticator ?? PasskeyAuthenticator();

  final PasskeyAuthenticator _authenticator;

  Future<bool> isAvailable() async {
    try {
      final GetAvailability availabilityChecker = _authenticator.getAvailability();    
      final String platform = DeviceHelper.getPlatformName();
      switch (platform) {
        case 'android':
          return (await availabilityChecker.android()).hasPasskeySupport;
        case 'ios':
          return (await availabilityChecker.iOS()).hasPasskeySupport;
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> createRegistrationCredential(
    Map<String, dynamic> options,
  ) async {
    try {
      final RegisterRequestType request = RegisterRequestType.fromJson(
        _normalizeRegisterOptions(options),
      );

      final RegisterResponseType response =
          await _authenticator.register(request);

      return <String, dynamic>{
        'id': response.id,
        'rawId': response.rawId,
        'type': 'public-key',
        'response': <String, dynamic>{
          'clientDataJSON': response.clientDataJSON,
          'attestationObject': response.attestationObject,
          'transports': response.transports.whereType<String>().toList(),
        },
        'clientExtensionResults': <String, dynamic>{},
      };
    } catch (error) {
      throw _convertPasskeyError(error);
    }
  }

  Future<Map<String, dynamic>> createAuthenticationCredential(
    Map<String, dynamic> options,
  ) async {
    try {
      final AuthenticateRequestType request = AuthenticateRequestType.fromJson(
        _normalizeAuthenticateOptions(options),
        // Allow hybrid/cross-device credentials when no immediate local
        // credential is available on this device.
        preferImmediatelyAvailableCredentials: false,
      );
      final AuthenticateResponseType response =
          await _authenticator.authenticate(request);
      return <String, dynamic>{
        'id': response.id,
        'rawId': response.rawId,
        'type': 'public-key',
        'response': <String, dynamic>{
          'authenticatorData': response.authenticatorData,
          'clientDataJSON': response.clientDataJSON,
          'signature': response.signature,
          'userHandle': response.userHandle.isEmpty ? null : response.userHandle,
        },
        'clientExtensionResults': <String, dynamic>{},
      };
    } catch (error) {
      throw _convertPasskeyError(error);
    }
  }

  Map<String, dynamic> _normalizeRegisterOptions(Map<String, dynamic> options) {
    try {
      // Use strongly-typed model for validation
      final PasskeyRegisterOptions passkeyOptions =
          PasskeyRegisterOptions.fromJson(options);
      // Convert back to JSON for the authenticator
      return passkeyOptions.toJson();
    } on FormatException catch (e) {
      throw PasskeyPlatformException(
          'Invalid passkey registration options: ${e.message}');
    } catch (e) {
      // Fallback to legacy normalization for backward compatibility
      return _legacyNormalizeRegisterOptions(options);
    }
  }

  Map<String, dynamic> _normalizeAuthenticateOptions(
    Map<String, dynamic> options,
  ) {
    try {
      // Use strongly-typed model for validation
      final PasskeyAuthenticateOptions passkeyOptions =
          PasskeyAuthenticateOptions.fromJson(options);
      // Convert back to JSON for the authenticator
      return passkeyOptions.toJson();
    } on FormatException catch (e) {
      throw PasskeyPlatformException(
          'Invalid passkey authentication options: ${e.message}');
    } catch (e) {
      // Fallback to legacy normalization for backward compatibility
      return _legacyNormalizeAuthenticateOptions(options);
    }
  }

  /// Legacy normalization method for backward compatibility.
  Map<String, dynamic> _legacyNormalizeRegisterOptions(
      Map<String, dynamic> options) {
    final Map<String, dynamic> relyingParty = _toMap(options['relyingParty']) ??
        _toMap(options['rp']) ??
        <String, dynamic>{};
    final Map<String, dynamic> user =
        _toMap(options['user']) ?? <String, dynamic>{};
    final List<Map<String, dynamic>> excludeCredentials =
        _toCredentialList(options['excludeCredentials']);
    final List<Map<String, dynamic>> pubKeyCredParams =
        _toMapList(options['pubKeyCredParams']);

    final Map<String, dynamic> normalized = <String, dynamic>{
      'challenge': options['challenge'],
      'rp': relyingParty,
      'user': user,
      'excludeCredentials': excludeCredentials,
    };

    final Map<String, dynamic>? authSelection =
        _toMap(options['authSelectionType']) ??
            _toMap(options['authenticatorSelection']);
    if (authSelection != null) {
      normalized['authenticatorSelection'] = authSelection;
    }
    if (pubKeyCredParams.isNotEmpty) {
      normalized['pubKeyCredParams'] = pubKeyCredParams;
    }
    if (options['timeout'] != null) {
      normalized['timeout'] = options['timeout'];
    }
    if (options['attestation'] != null) {
      normalized['attestation'] = options['attestation'];
    }

    return normalized;
  }

  /// Legacy normalization method for backward compatibility.
  Map<String, dynamic> _legacyNormalizeAuthenticateOptions(
    Map<String, dynamic> options,
  ) {
    final List<Map<String, dynamic>> allowCredentials =
        _toCredentialList(options['allowCredentials']);

    final Map<String, dynamic> normalized = <String, dynamic>{
      'rpId': options['rpId'],
      'challenge': options['challenge'],
      'allowCredentials': allowCredentials,
    };

    if (options['timeout'] != null) {
      normalized['timeout'] = options['timeout'];
    }
    if (options['userVerification'] != null) {
      normalized['userVerification'] = options['userVerification'];
    }

    return normalized;
  }

  Map<String, dynamic>? _toMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return null;
  }

  List<Map<String, dynamic>> _toMapList(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .map<Map<String, dynamic>?>((dynamic item) => _toMap(item))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  List<Map<String, dynamic>> _toCredentialList(dynamic value) {
    final List<Map<String, dynamic>> rawCredentials = _toMapList(value);
    return rawCredentials.map((Map<String, dynamic> credential) {
      final dynamic transportsValue = credential['transports'];
      final List<String> transports = transportsValue is List
          ? transportsValue.whereType<String>().toList()
          : <String>[];

      return <String, dynamic>{
        ...credential,
        'transports': transports,
      };
    }).toList();
  }

  /// Converts platform-specific passkey errors to typed exceptions.
  Exception _convertPasskeyError(dynamic error) {
    final String errorString = error.toString().toLowerCase();

    // Check for cancellation
    if (errorString.contains('cancel') ||
        errorString.contains('user cancel') ||
        errorString.contains('abort')) {
      return const PasskeyAuthCancelledException();
    }

    // Check for no credential found
    if (errorString.contains('nocredentialexception') ||
        errorString.contains('no credential') ||
        errorString.contains('cannot find a matching credential')) {
      return const PasskeyNoCredentialException();
    }

    // Check for not supported
    if (errorString.contains('not supported') ||
        errorString.contains('unsupported') ||
        errorString.contains('not available')) {
      return const PasskeyNotSupportedException();
    }

    // Check for security issues
    if (errorString.contains('security') ||
        errorString.contains('integrity') ||
        errorString.contains('verification failed')) {
      return const PasskeySecurityException();
    }

    // Check for timeout
    if (errorString.contains('timeout') ||
        errorString.contains('timed out')) {
      return const PasskeyTimeoutException();
    }

    // If it's already one of our exceptions, rethrow it
    if (error is PasskeyAuthCancelledException ||
        error is PasskeyNoCredentialException ||
        error is PasskeyNotSupportedException ||
        error is PasskeySecurityException ||
        error is PasskeyPlatformException ||
        error is PasskeyTimeoutException) {
      return error as Exception;
    }

    // Default to platform exception for unknown errors
    return PasskeyPlatformException(error.toString());
  }
}
