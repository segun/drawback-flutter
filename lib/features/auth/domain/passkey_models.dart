class PasskeyRelyingParty {
  const PasskeyRelyingParty({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory PasskeyRelyingParty.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('id')) {
      throw const FormatException('Missing required field: id');
    }
    if (!json.containsKey('name')) {
      throw const FormatException('Missing required field: name');
    }

    return PasskeyRelyingParty(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
      };
}

/// Represents user information for passkey registration.
class PasskeyUser {
  const PasskeyUser({
    required this.id,
    required this.name,
    required this.displayName,
  });

  final String id;
  final String name;
  final String displayName;

  factory PasskeyUser.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('id')) {
      throw const FormatException('Missing required field: id');
    }
    if (!json.containsKey('name')) {
      throw const FormatException('Missing required field: name');
    }
    if (!json.containsKey('displayName')) {
      throw const FormatException('Missing required field: displayName');
    }

    return PasskeyUser(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'displayName': displayName,
      };
}

/// Represents a credential descriptor for excluding or allowing specific credentials.
class PasskeyCredentialDescriptor {
  const PasskeyCredentialDescriptor({
    required this.id,
    required this.type,
    this.transports = const <String>[],
  });

  final String id;
  final String type;
  final List<String> transports;

  factory PasskeyCredentialDescriptor.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('id')) {
      throw const FormatException('Missing required field: id');
    }
    if (!json.containsKey('type')) {
      throw const FormatException('Missing required field: type');
    }

    final dynamic transportsValue = json['transports'];
    final List<String> transports = transportsValue is List
        ? transportsValue.whereType<String>().toList()
        : <String>[];

    return PasskeyCredentialDescriptor(
      id: json['id'] as String,
      type: json['type'] as String,
      transports: transports,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'transports': transports,
      };
}

/// Represents authenticator selection criteria for passkey registration.
class PasskeyAuthenticatorSelection {
  const PasskeyAuthenticatorSelection({
    this.authenticatorAttachment,
    this.requireResidentKey,
    this.residentKey,
    this.userVerification,
  });

  final String? authenticatorAttachment;
  final bool? requireResidentKey;
  final String? residentKey;
  final String? userVerification;

  factory PasskeyAuthenticatorSelection.fromJson(Map<String, dynamic> json) {
    return PasskeyAuthenticatorSelection(
      authenticatorAttachment: json['authenticatorAttachment'] as String?,
      requireResidentKey: json['requireResidentKey'] as bool?,
      residentKey: json['residentKey'] as String?,
      userVerification: json['userVerification'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = <String, dynamic>{};
    if (authenticatorAttachment != null) {
      result['authenticatorAttachment'] = authenticatorAttachment;
    }
    if (requireResidentKey != null) {
      result['requireResidentKey'] = requireResidentKey;
    }
    if (residentKey != null) {
      result['residentKey'] = residentKey;
    }
    if (userVerification != null) {
      result['userVerification'] = userVerification;
    }
    return result;
  }
}

/// Represents a public key credential parameter.
class PasskeyPublicKeyCredentialParameters {
  const PasskeyPublicKeyCredentialParameters({
    required this.type,
    required this.alg,
  });

  final String type;
  final int alg;

  factory PasskeyPublicKeyCredentialParameters.fromJson(
      Map<String, dynamic> json) {
    if (!json.containsKey('type')) {
      throw const FormatException('Missing required field: type');
    }
    if (!json.containsKey('alg')) {
      throw const FormatException('Missing required field: alg');
    }

    return PasskeyPublicKeyCredentialParameters(
      type: json['type'] as String,
      alg: json['alg'] as int,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'alg': alg,
      };
}

/// Represents options for passkey registration.
class PasskeyRegisterOptions {
  const PasskeyRegisterOptions({
    required this.rp,
    required this.user,
    required this.challenge,
    required this.excludeCredentials,
    this.pubKeyCredParams,
    this.timeout,
    this.attestation,
    this.authenticatorSelection,
  });

  final PasskeyRelyingParty rp;
  final PasskeyUser user;
  final String challenge;
  final List<PasskeyCredentialDescriptor> excludeCredentials;
  final List<PasskeyPublicKeyCredentialParameters>? pubKeyCredParams;
  final int? timeout;
  final String? attestation;
  final PasskeyAuthenticatorSelection? authenticatorSelection;

  factory PasskeyRegisterOptions.fromJson(Map<String, dynamic> json) {
    // Check for relying party (supports both 'rp' and 'relyingParty' field names)
    final dynamic rpValue = json['rp'] ?? json['relyingParty'];
    if (rpValue == null) {
      throw const FormatException(
          'Missing required field: rp or relyingParty');
    }

    if (!json.containsKey('user')) {
      throw const FormatException('Missing required field: user');
    }

    if (!json.containsKey('challenge')) {
      throw const FormatException('Missing required field: challenge');
    }

    final PasskeyRelyingParty rp = rpValue is Map<String, dynamic>
        ? PasskeyRelyingParty.fromJson(rpValue)
        : PasskeyRelyingParty.fromJson(
            (rpValue as Map).cast<String, dynamic>());

    final dynamic userValue = json['user'];
    final PasskeyUser user = userValue is Map<String, dynamic>
        ? PasskeyUser.fromJson(userValue)
        : PasskeyUser.fromJson((userValue as Map).cast<String, dynamic>());

    final List<PasskeyCredentialDescriptor> excludeCredentials =
        _parseCredentialList(json['excludeCredentials']);

    final List<PasskeyPublicKeyCredentialParameters>? pubKeyCredParams =
        json['pubKeyCredParams'] != null
            ? _parsePubKeyCredParams(json['pubKeyCredParams'])
            : null;

    // Support both 'authSelectionType' and 'authenticatorSelection'
    final dynamic authSelectionValue =
        json['authenticatorSelection'] ?? json['authSelectionType'];
    final PasskeyAuthenticatorSelection? authenticatorSelection =
        authSelectionValue != null
            ? (authSelectionValue is Map<String, dynamic>
                ? PasskeyAuthenticatorSelection.fromJson(authSelectionValue)
                : PasskeyAuthenticatorSelection.fromJson(
                    (authSelectionValue as Map).cast<String, dynamic>()))
            : null;

    return PasskeyRegisterOptions(
      rp: rp,
      user: user,
      challenge: json['challenge'] as String,
      excludeCredentials: excludeCredentials,
      pubKeyCredParams: pubKeyCredParams,
      timeout: json['timeout'] as int?,
      attestation: json['attestation'] as String?,
      authenticatorSelection: authenticatorSelection,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = <String, dynamic>{
      'rp': rp.toJson(),
      'user': user.toJson(),
      'challenge': challenge,
      'excludeCredentials':
          excludeCredentials.map((e) => e.toJson()).toList(),
    };

    if (pubKeyCredParams != null) {
      result['pubKeyCredParams'] = pubKeyCredParams!.map((e) => e.toJson()).toList();
    }
    if (timeout != null) {
      result['timeout'] = timeout;
    }
    if (attestation != null) {
      result['attestation'] = attestation;
    }
    if (authenticatorSelection != null) {
      result['authenticatorSelection'] = authenticatorSelection!.toJson();
    }

    return result;
  }

  static List<PasskeyCredentialDescriptor> _parseCredentialList(
      dynamic value) {
    if (value == null || value is! List) {
      return <PasskeyCredentialDescriptor>[];
    }

    return value
        .map((dynamic item) {
          if (item is Map<String, dynamic>) {
            return PasskeyCredentialDescriptor.fromJson(item);
          } else if (item is Map) {
            return PasskeyCredentialDescriptor.fromJson(
                item.cast<String, dynamic>());
          }
          return null;
        })
        .whereType<PasskeyCredentialDescriptor>()
        .toList();
  }

  static List<PasskeyPublicKeyCredentialParameters> _parsePubKeyCredParams(
      dynamic value) {
    if (value == null || value is! List) {
      return <PasskeyPublicKeyCredentialParameters>[];
    }

    return value
        .map((dynamic item) {
          if (item is Map<String, dynamic>) {
            return PasskeyPublicKeyCredentialParameters.fromJson(item);
          } else if (item is Map) {
            return PasskeyPublicKeyCredentialParameters.fromJson(
                item.cast<String, dynamic>());
          }
          return null;
        })
        .whereType<PasskeyPublicKeyCredentialParameters>()
        .toList();
  }
}

/// Represents options for passkey authentication.
class PasskeyAuthenticateOptions {
  const PasskeyAuthenticateOptions({
    required this.rpId,
    required this.challenge,
    required this.allowCredentials,
    this.timeout,
    this.userVerification,
  });

  final String rpId;
  final String challenge;
  final List<PasskeyCredentialDescriptor> allowCredentials;
  final int? timeout;
  final String? userVerification;

  factory PasskeyAuthenticateOptions.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('rpId')) {
      throw const FormatException('Missing required field: rpId');
    }

    if (!json.containsKey('challenge')) {
      throw const FormatException('Missing required field: challenge');
    }

    final List<PasskeyCredentialDescriptor> allowCredentials =
        PasskeyRegisterOptions._parseCredentialList(
            json['allowCredentials']);

    return PasskeyAuthenticateOptions(
      rpId: json['rpId'] as String,
      challenge: json['challenge'] as String,
      allowCredentials: allowCredentials,
      timeout: json['timeout'] as int?,
      userVerification: json['userVerification'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = <String, dynamic>{
      'rpId': rpId,
      'challenge': challenge,
      'allowCredentials':
          allowCredentials.map((e) => e.toJson()).toList(),
    };

    if (timeout != null) {
      result['timeout'] = timeout;
    }
    if (userVerification != null) {
      result['userVerification'] = userVerification;
    }

    return result;
  }
}
