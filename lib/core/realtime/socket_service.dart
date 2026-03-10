import 'package:socket_io_client/socket_io_client.dart' as io;

/// Payload for incoming chat request notification
class ChatRequestedPayload {
  const ChatRequestedPayload({
    required this.requestId,
    required this.fromUser,
    required this.message,
  });

  factory ChatRequestedPayload.fromJson(Map<String, dynamic> json) {
    return ChatRequestedPayload(
      requestId: json['requestId'] as String,
      fromUser: FromUser.fromJson(json['fromUser'] as Map<String, dynamic>),
      message: json['message'] as String,
    );
  }

  final String requestId;
  final FromUser fromUser;
  final String message;
}

class FromUser {
  const FromUser({
    required this.id,
    required this.displayName,
  });

  factory FromUser.fromJson(Map<String, dynamic> json) {
    return FromUser(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
    );
  }

  final String id;
  final String displayName;
}

/// Payload for chat response (accept/reject)
class ChatResponsePayload {
  const ChatResponsePayload({
    required this.requestId,
    required this.accepted,
    this.roomId,
    this.requesterUserId,
    this.responderUserId,
  });

  factory ChatResponsePayload.fromJson(Map<String, dynamic> json) {
    return ChatResponsePayload(
      requestId: json['requestId'] as String,
      accepted: json['accepted'] as bool,
      roomId: json['roomId'] as String?,
      requesterUserId: json['requesterUserId'] as String?,
      responderUserId: json['responderUserId'] as String?,
    );
  }

  final String requestId;
  final bool accepted;
  final String? roomId;
  final String? requesterUserId;
  final String? responderUserId;
}

/// Payload when both peers have joined the chat room
class ChatJoinedPayload {
  const ChatJoinedPayload({
    required this.roomId,
    required this.requestId,
    required this.peers,
  });

  factory ChatJoinedPayload.fromJson(Map<String, dynamic> json) {
    return ChatJoinedPayload(
      roomId: json['roomId'] as String,
      requestId: json['requestId'] as String,
      peers: (json['peers'] as List<dynamic>).cast<String>(),
    );
  }

  final String roomId;
  final String requestId;
  final List<String> peers;
}

/// Payload for socket error messages
class SocketErrorPayload {
  const SocketErrorPayload({
    required this.message,
    this.status,
  });

  factory SocketErrorPayload.fromJson(Map<String, dynamic> json) {
    return SocketErrorPayload(
      message: json['message'] as String,
      status: json['status'] as int?,
    );
  }

  final String message;
  final int? status;
}

/// Payload for draw stroke events
class DrawStrokePayload {
  const DrawStrokePayload({
    required this.requestId,
    required this.stroke,
    required this.userId,
  });

  factory DrawStrokePayload.fromJson(Map<String, dynamic> json) {
    return DrawStrokePayload(
      requestId: json['requestId'] as String,
      stroke: json['stroke'],
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'requestId': requestId,
      'stroke': stroke,
      'userId': userId,
    };
  }

  final String requestId;
  final dynamic stroke;
  final String userId;
}

/// Payload for clear canvas events
class DrawClearPayload {
  const DrawClearPayload({
    required this.requestId,
    required this.userId,
  });

  factory DrawClearPayload.fromJson(Map<String, dynamic> json) {
    return DrawClearPayload(
      requestId: json['requestId'] as String,
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'requestId': requestId,
      'userId': userId,
    };
  }

  final String requestId;
  final String userId;
}

/// Payload for emote events
class DrawEmotePayload {
  const DrawEmotePayload({
    required this.requestId,
    required this.emoji,
    required this.userId,
  });

  factory DrawEmotePayload.fromJson(Map<String, dynamic> json) {
    return DrawEmotePayload(
      requestId: json['requestId'] as String,
      emoji: json['emoji'] as String,
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'requestId': requestId,
      'emoji': emoji,
      'userId': userId,
    };
  }

  final String requestId;
  final String emoji;
  final String userId;
}

/// Payload for peer presence events
class DrawPeerJoinedPayload {
  const DrawPeerJoinedPayload({required this.userId});

  factory DrawPeerJoinedPayload.fromJson(Map<String, dynamic> json) {
    return DrawPeerJoinedPayload(
      userId: json['userId'] as String,
    );
  }

  final String userId;
}

class DrawPeerLeftPayload {
  const DrawPeerLeftPayload({required this.userId});

  factory DrawPeerLeftPayload.fromJson(Map<String, dynamic> json) {
    return DrawPeerLeftPayload(
      userId: json['userId'] as String,
    );
  }

  final String userId;
}

class DrawPeerWaitingPayload {
  const DrawPeerWaitingPayload({
    required this.requestId,
  });

  factory DrawPeerWaitingPayload.fromJson(Map<String, dynamic> json) {
    return DrawPeerWaitingPayload(
      requestId: json['requestId'] as String? ?? '',
    );
  }

  final String requestId;
}

/// Socket service singleton for managing Socket.IO connection
class SocketService {
  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  static final SocketService _instance = SocketService._internal();

  io.Socket? _socket;
  String? _currentToken;
  void Function()? _onUnauthorized;
  bool _hasTriggeredUnauthorized = false;

  io.Socket? get socket => _socket;

  bool get isConnected => _socket?.connected ?? false;

  /// Get or create a Socket.IO connection to the /drawback namespace
  io.Socket getOrCreateSocket(
    String baseUrl,
    String token, {
    void Function()? onUnauthorized,
  }) {
    _onUnauthorized = onUnauthorized ?? _onUnauthorized;

    if (token.trim().isEmpty) {
      throw Exception('Missing access token. Cannot initialize WebSocket connection.');
    }

    if (_socket != null && _currentToken == token) {
      if (!_socket!.connected) {
        _socket!.connect();
      }
      return _socket!;
    }

    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }

    _currentToken = token;
    _hasTriggeredUnauthorized = false;

    final String namespaceUrl = _buildNamespaceUrl(baseUrl);

    _socket = io.io(
      namespaceUrl,
      io.OptionBuilder()
          .setTransports(<String>['websocket'])
          .setAuth(<String, dynamic>{'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    _attachAuthFailureListeners(_socket!);

    return _socket!;
  }

  void _attachAuthFailureListeners(io.Socket socket) {
    socket.on('connect_error', (dynamic error) {
      if (_isUnauthorizedPayload(error)) {
        _triggerUnauthorizedHandler();
      }
    });

    socket.on('error', (dynamic error) {
      if (_isUnauthorizedPayload(error)) {
        _triggerUnauthorizedHandler();
      }
    });
  }

  bool _isUnauthorizedPayload(dynamic payload) {
    if (payload is SocketErrorPayload) {
      if (payload.status == 401) {
        return true;
      }
      final String message = payload.message.toLowerCase();
      return message.contains('401') || message.contains('unauthorized');
    }

    if (payload is Map<String, dynamic>) {
      return _mapIndicatesUnauthorized(payload);
    }

    if (payload is Map) {
      try {
        return _mapIndicatesUnauthorized(Map<String, dynamic>.from(payload));
      } catch (_) {
        // no-op
      }
    }

    final String text = payload?.toString().toLowerCase() ?? '';
    return text.contains('401') || text.contains('unauthorized');
  }

  bool _mapIndicatesUnauthorized(Map<String, dynamic> data) {
    final dynamic status = data['status'] ?? data['statusCode'] ?? data['code'];
    if (_statusCodeIsUnauthorized(status)) {
      return true;
    }

    final dynamic message = data['message'] ?? data['error'];
    if (message is String) {
      final String normalized = message.toLowerCase();
      return normalized.contains('401') || normalized.contains('unauthorized');
    }

    if (message is List) {
      for (final dynamic item in message) {
        if (item is String) {
          final String normalized = item.toLowerCase();
          if (normalized.contains('401') || normalized.contains('unauthorized')) {
            return true;
          }
        }
      }
    }

    return false;
  }

  bool _statusCodeIsUnauthorized(dynamic status) {
    if (status is int) {
      return status == 401;
    }

    if (status is String) {
      final String normalized = status.trim().toLowerCase();
      return normalized == '401' || normalized == 'unauthorized';
    }

    return false;
  }

  void _triggerUnauthorizedHandler() {
    if (_hasTriggeredUnauthorized) {
      return;
    }

    _hasTriggeredUnauthorized = true;
    _onUnauthorized?.call();
  }

  String _buildNamespaceUrl(String baseUrl) {
    final String normalized = baseUrl.trim().replaceAll(RegExp(r'/$'), '');
    if (normalized.isEmpty) {
      throw Exception('Missing backend URL. Cannot initialize WebSocket connection.');
    }

    try {
      final Uri uri = Uri.parse(normalized);
      return '${uri.origin}/drawback';
    } catch (_) {
      return '$normalized/drawback';
    }
  }

  /// Emit chat.join event
  void emitChatJoin(String requestId) {
    if (_socket == null || requestId.trim().isEmpty) {
      return;
    }
    _socket!.emit('chat.join', <String, dynamic>{'requestId': requestId});
  }

  /// Emit draw.leave event
  void emitDrawLeave() {
    if (_socket == null) {
      return;
    }
    _socket!.emit('draw.leave');
  }

  /// Emit draw.stroke event
  void emitDrawStroke(String requestId, dynamic stroke, String userId) {
    if (_socket == null || requestId.trim().isEmpty) {
      return;
    }
    _socket!.emit('draw.stroke', <String, dynamic>{
      'requestId': requestId,
      'stroke': stroke,
      'userId': userId,
    });
  }

  /// Emit draw.clear event
  void emitDrawClear(String requestId, String userId) {
    if (_socket == null || requestId.trim().isEmpty) {
      return;
    }
    _socket!.emit('draw.clear', <String, dynamic>{
      'requestId': requestId,
      'userId': userId,
    });
  }

  /// Emit draw.emote event
  void emitDrawEmote(String requestId, String emoji, String userId) {
    if (_socket == null || requestId.trim().isEmpty) {
      return;
    }
    _socket!.emit('draw.emote', <String, dynamic>{
      'requestId': requestId,
      'emoji': emoji,
      'userId': userId,
    });
  }

  /// Disconnect and clean up socket
  void disconnect() {
    if (_socket == null) {
      return;
    }
    _socket!.disconnect();
    _socket = null;
    _currentToken = null;
    _onUnauthorized = null;
    _hasTriggeredUnauthorized = false;
  }
}
