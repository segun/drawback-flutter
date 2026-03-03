import 'package:flutter/material.dart';

import '../../../../core/realtime/socket_service.dart';
import '../../../home/domain/home_models.dart';
import '../../models/drawing_models.dart';
import '../../widgets/drawing_canvas.dart';

/// Chat room screen with dual canvas drawing
class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    required this.chatRequestId,
    required this.chatRequest,
    required this.profile,
    required this.onNotice,
    super.key,
  });

  final String chatRequestId;
  final ChatRequest chatRequest;
  final UserProfile profile;
  final Function(String message, String type) onNotice;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final SocketService _socketService = SocketService();
  final List<DrawSegmentStroke> _localStrokes = <DrawSegmentStroke>[];
  final List<DrawSegmentStroke> _remoteStrokes = <DrawSegmentStroke>[];
  final List<AnimatedEmote> _localEmotes = <AnimatedEmote>[];
  final List<AnimatedEmote> _remoteEmotes = <AnimatedEmote>[];

  String _drawColor = '#be123c';
  final DrawStrokeStyle _drawStyle = DrawStrokeStyle.normal;
  double _drawWidth = 2.0;
  bool _peerPresent = false;
  bool _roomJoined = false;
  String _peerDisplayName = '';

  @override
  void initState() {
    super.initState();
    // Set peer display name from chat request
    _peerDisplayName = widget.profile.id == widget.chatRequest.fromUserId
        ? widget.chatRequest.toUser.displayName
        : widget.chatRequest.fromUser.displayName;
    debugPrint('Initializing chat room for ${widget.chatRequest.id} with peer $_peerDisplayName');
    _setupSocketListeners();
    _joinChatRoom();
  }

  @override
  void dispose() {
    _removeSocketListeners();
    super.dispose();
  }

  void _setupSocketListeners() {
    final socket = _socketService.socket;
    if (socket == null) {
      return;
    }

    socket.on('chat.joined', _onChatJoined);
    socket.on('draw.stroke', _onDrawStroke);
    socket.on('draw.clear', _onDrawClear);
    socket.on('draw.emote', _onDrawEmote);
    socket.on('draw.peer.joined', _onDrawPeerJoined);
    socket.on('draw.peer.left', _onDrawPeerLeft);
    socket.on('error', _onSocketError);
  }

  void _removeSocketListeners() {
    final socket = _socketService.socket;
    if (socket == null) {
      return;
    }

    socket.off('chat.joined', _onChatJoined);
    socket.off('draw.stroke', _onDrawStroke);
    socket.off('draw.clear', _onDrawClear);
    socket.off('draw.emote', _onDrawEmote);
    socket.off('draw.peer.joined', _onDrawPeerJoined);
    socket.off('draw.peer.left', _onDrawPeerLeft);
    socket.off('error', _onSocketError);
  }

  void _joinChatRoom() {
    _socketService.emitChatJoin(widget.chatRequestId);
  }

  void _onChatJoined(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return;
    }

    final ChatJoinedPayload payload = ChatJoinedPayload.fromJson(data);
    if (payload.requestId != widget.chatRequestId) {
      return;
    }

    setState(() {
      _roomJoined = true;
      _peerPresent = payload.peers.isNotEmpty;
    });

    if (_peerPresent) {
      widget.onNotice('Both peers joined. You can start drawing!', 'success');
    } else {
      widget.onNotice('Waiting for peer to join...', 'info');
    }
  }

  void _onDrawStroke(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return;
    }

    final DrawStrokePayload payload = DrawStrokePayload.fromJson(data);
    if (payload.requestId != widget.chatRequestId) {
      return;
    }

    if (!DrawSegmentStroke.isValid(payload.stroke)) {
      return;
    }

    final DrawSegmentStroke stroke = DrawSegmentStroke.fromJson(
      payload.stroke as Map<String, dynamic>,
    );

    setState(() {
      if (!_peerPresent) {
        _peerPresent = true;
      }
      _remoteStrokes.add(stroke);
    });
  }

  void _onDrawClear(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return;
    }

    final DrawClearPayload payload = DrawClearPayload.fromJson(data);
    if (payload.requestId != widget.chatRequestId) {
      return;
    }

    setState(() {
      if (!_peerPresent) {
        _peerPresent = true;
      }
      _remoteStrokes.clear();
    });
  }

  void _onDrawEmote(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return;
    }

    final DrawEmotePayload payload = DrawEmotePayload.fromJson(data);
    if (payload.requestId != widget.chatRequestId) {
      return;
    }

    setState(() {
      if (!_peerPresent) {
        _peerPresent = true;
      }

      final AnimatedEmote emote = AnimatedEmote(
        id: '${DateTime.now().millisecondsSinceEpoch}-${payload.emoji}',
        emoji: payload.emoji,
        x: 10 + (0.75 * 100 * (DateTime.now().millisecondsSinceEpoch % 100) / 100),
        startTime: DateTime.now(),
      );
      _remoteEmotes.add(emote);

      // Remove after animation completes
      Future<void>.delayed(const Duration(milliseconds: 4200), () {
        if (mounted) {
          setState(() {
            _remoteEmotes.removeWhere((AnimatedEmote e) => e.id == emote.id);
          });
        }
      });
    });
  }

  void _onDrawPeerJoined(dynamic data) {
    setState(() {
      _peerPresent = true;
    });
    widget.onNotice('Peer joined. Start drawing!', 'success');
  }

  void _onDrawPeerLeft(dynamic data) {
    setState(() {
      _peerPresent = false;
    });
    widget.onNotice('Peer left the room.', 'info');
  }

  void _onSocketError(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return;
    }

    final SocketErrorPayload payload = SocketErrorPayload.fromJson(data);
    widget.onNotice(payload.message, 'error');
  }

  void _handleLocalStrokeDrawn(DrawSegmentStroke stroke) {
    if (!_roomJoined || !_peerPresent) {
      return;
    }

    setState(() {
      _localStrokes.add(stroke);
    });

    _socketService.emitDrawStroke(
      widget.chatRequestId,
      stroke.toJson(),
      widget.profile.id,
    );
  }

  void _handleClearLocal() {
    if (!_roomJoined || !_peerPresent) {
      return;
    }

    setState(() {
      _localStrokes.clear();
    });

    _socketService.emitDrawClear(widget.chatRequestId, widget.profile.id);
  }

  void _handleSendEmote(String emoji) {
    if (!_roomJoined || !_peerPresent) {
      return;
    }

    _socketService.emitDrawEmote(widget.chatRequestId, emoji, widget.profile.id);

    // Show locally
    final AnimatedEmote emote = AnimatedEmote(
      id: '${DateTime.now().millisecondsSinceEpoch}-$emoji',
      emoji: emoji,
      x: 10 + (0.75 * 100 * (DateTime.now().millisecondsSinceEpoch % 100) / 100),
      startTime: DateTime.now(),
    );

    setState(() {
      _localEmotes.add(emote);
    });

    Future<void>.delayed(const Duration(milliseconds: 4200), () {
      if (mounted) {
        setState(() {
          _localEmotes.removeWhere((AnimatedEmote e) => e.id == emote.id);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Status bar
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFFFCE7F3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Icon(
                _peerPresent ? Icons.check_circle : Icons.pending,
                color: _peerPresent ? const Color(0xFF059669) : const Color(0xFF9F1239),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _peerPresent
                    ? 'Drawing with $_peerDisplayName'
                    : 'Waiting for $_peerDisplayName',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _peerPresent ? const Color(0xFF059669) : const Color(0xFF9F1239),
                ),
              ),
            ],
          ),
        ),

        // Drawing area with dual canvases
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: <Widget>[
                // Remote canvas (peer's drawing)
                Expanded(
                  child: _buildCanvasCard(
                    child: DrawingCanvas(
                      strokes: _remoteStrokes,
                      onStrokeDrawn: (_) {}, // Read-only
                      isEnabled: false,
                      color: _drawColor,
                      width: _drawWidth,
                      style: _drawStyle,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Local canvas (your drawing)
                Expanded(
                  child: _buildCanvasCard(
                    child: DrawingCanvas(
                      strokes: _localStrokes,
                      onStrokeDrawn: _handleLocalStrokeDrawn,
                      isEnabled: _roomJoined && _peerPresent,
                      color: _drawColor,
                      width: _drawWidth,
                      style: _drawStyle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Drawing controls
        _buildControls(),
      ],
    );
  }

  Widget _buildCanvasCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDA4AF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFFFDA4AF),
        border: Border(top: BorderSide(color: Color(0xFFFDA4AF))),
      ),
      child: Row(
        children: <Widget>[
          // Color picker
          _buildColorButton('#be123c'),
          const SizedBox(width: 4),
          _buildColorButton('#dc2626'),
          const SizedBox(width: 4),
          _buildColorButton('#ea580c'),
          const SizedBox(width: 4),
          _buildColorButton('#ca8a04'),
          const SizedBox(width: 4),
          _buildColorButton('#16a34a'),
          const SizedBox(width: 4),
          _buildColorButton('#2563eb'),
          const SizedBox(width: 4),
          _buildColorButton('#9333ea'),
          const SizedBox(width: 4),
          _buildColorButton('#000000'),

          const SizedBox(width: 16),

          // Eraser
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _drawColor = 'eraser';
              });
            },
            icon: const Icon(Icons.auto_fix_high, size: 16),
            label: const Text('Eraser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _drawColor == 'eraser'
                  ? const Color(0xFF9F1239)
                  : const Color(0xFFFCE7F3),
              foregroundColor: _drawColor == 'eraser'
                  ? Colors.white
                  : const Color(0xFF9F1239),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),

          const SizedBox(width: 16),

          // Width selector
          const Text(
            'Width:',
            style: TextStyle(fontSize: 12, color: Color(0xFF9F1239)),
          ),
          const SizedBox(width: 8),
          Slider(
            value: _drawWidth,
            min: 1,
            max: 10,
            divisions: 9,
            label: _drawWidth.toInt().toString(),
            activeColor: const Color(0xFF9F1239),
            onChanged: (double value) {
              setState(() {
                _drawWidth = value;
              });
            },
          ),

          const SizedBox(width: 16),

          // Clear button
          ElevatedButton.icon(
            onPressed: _handleClearLocal,
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),

          const Spacer(),

          // Emote picker (simplified)
          ElevatedButton.icon(
            onPressed: () => _showEmotePicker(),
            icon: const Icon(Icons.emoji_emotions, size: 16),
            label: const Text('Emote'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFCE7F3),
              foregroundColor: const Color(0xFF9F1239),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(String color) {
    final bool isSelected = _drawColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _drawColor = color;
        });
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Color(int.parse('FF${color.substring(1)}', radix: 16)),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF9F1239) : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }

  void _showEmotePicker() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick an Emote'),
          content: SizedBox(
            width: 300,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PresetEmotes.emotes.map((String emoji) {
                return GestureDetector(
                  onTap: () {
                    _handleSendEmote(emoji);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE7F3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
