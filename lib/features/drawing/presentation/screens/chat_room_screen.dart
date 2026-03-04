import 'dart:async';
import 'dart:math' as math;

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
    required this.onSaveChat,
    required this.isChatSaved,
    super.key,
  });

  final String chatRequestId;
  final ChatRequest chatRequest;
  final UserProfile profile;
  final Function(String message, String type) onNotice;
  final Future<void> Function() onSaveChat;
  final bool isChatSaved;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with SingleTickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  final ScrollController _emotePickerScrollController = ScrollController();
  List<DrawSegmentStroke> _localStrokes = <DrawSegmentStroke>[];
  late AnimationController _syncAnimationController;
  List<DrawSegmentStroke> _remoteStrokes = <DrawSegmentStroke>[];
  List<AnimatedEmote> _localEmotes = <AnimatedEmote>[];
  List<AnimatedEmote> _remoteEmotes = <AnimatedEmote>[];

  String _drawColor = '#be123c';
  final DrawStrokeStyle _drawStyle = DrawStrokeStyle.normal;
  double _drawWidth = 2.0;
  bool _peerPresent = false;
  bool _roomJoined = false;
  String _peerDisplayName = '';
  bool _isSavingChat = false;
  bool _isReconnecting = false;
  bool _showReconnectButton = false;
  Timer? _reconnectButtonTimer;
  Timer? _emoteAnimationTimer;

  @override
  void initState() {
    super.initState();
    // Set peer display name from chat request
    _peerDisplayName = widget.profile.id == widget.chatRequest.fromUserId
        ? widget.chatRequest.toUser.displayName
        : widget.chatRequest.fromUser.displayName;
    debugPrint('Initializing chat room for ${widget.chatRequest.id} with peer $_peerDisplayName');
    
    // Initialize sync animation controller
    _syncAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _setupSocketListeners();
    _joinChatRoom();
  }

  @override
  void dispose() {
    _reconnectButtonTimer?.cancel();
    _emoteAnimationTimer?.cancel();
    _emotePickerScrollController.dispose();
    _syncAnimationController.dispose();
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
      _startReconnectButtonTimer();
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
      _remoteStrokes = <DrawSegmentStroke>[];
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

    final AnimatedEmote emote = AnimatedEmote(
      id: '${DateTime.now().millisecondsSinceEpoch}-${payload.emoji}',
      emoji: payload.emoji,
      x: _randomEmoteXPercent(),
      startTime: DateTime.now(),
    );

    setState(() {
      if (!_peerPresent) {
        _peerPresent = true;
      }
      _remoteEmotes.add(emote);
    });

    _startEmoteAnimationTimer();

    // Remove after animation completes
    Future<void>.delayed(const Duration(milliseconds: 4200), () {
      if (mounted) {
        setState(() {
          _remoteEmotes.removeWhere((AnimatedEmote e) => e.id == emote.id);
        });
      }
    });
  }

  void _onDrawPeerJoined(dynamic data) {
    setState(() {
      _peerPresent = true;
      _showReconnectButton = false;
    });
    _reconnectButtonTimer?.cancel();
    widget.onNotice('Peer joined. Start drawing!', 'success');
  }

  void _onDrawPeerLeft(dynamic data) {
    setState(() {
      _peerPresent = false;
    });
    _startReconnectButtonTimer();
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
      _localStrokes = <DrawSegmentStroke>[];
    });

    _socketService.emitDrawClear(widget.chatRequestId, widget.profile.id);
  }

  void _startReconnectButtonTimer() {
    _reconnectButtonTimer?.cancel();
    _reconnectButtonTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_peerPresent && _roomJoined) {
        setState(() {
          _showReconnectButton = true;
        });
      }
    });
  }

  Future<void> _handleReconnectToRoom() async {
    if (_isReconnecting) {
      return;
    }

    setState(() {
      _isReconnecting = true;
      _showReconnectButton = false;
    });

    _reconnectButtonTimer?.cancel();
    _syncAnimationController.repeat();

    try {
      _socketService.emitChatJoin(widget.chatRequestId);

      // Stop spinning after 3 seconds like React
      await Future<void>.delayed(const Duration(milliseconds: 3000));
    } finally {
      if (mounted) {
        _syncAnimationController.stop();
        setState(() {
          _isReconnecting = false;
        });
      }
    }
  }

  Future<void> _handleSaveChat() async {
    if (_isSavingChat) {
      return;
    }

    setState(() {
      _isSavingChat = true;
    });

    try {
      await widget.onSaveChat();
    } finally {
      if (mounted) {
        setState(() {
          _isSavingChat = false;
        });
      }
    }
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
      x: _randomEmoteXPercent(),
      startTime: DateTime.now(),
    );

    setState(() {
      _localEmotes.add(emote);
    });

    _startEmoteAnimationTimer();

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
                    child: Stack(
                      children: <Widget>[
                        DrawingCanvas(
                          strokes: _remoteStrokes,
                          onStrokeDrawn: (_) {}, // Read-only
                          isEnabled: false,
                          color: _drawColor,
                          width: _drawWidth,
                          style: _drawStyle,
                        ),
                        ..._buildEmotesLayer(_remoteEmotes),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Local canvas (your drawing)
                Expanded(
                  child: _buildCanvasCard(
                    child: Column(
                      children: <Widget>[
                        _buildLocalQuickActions(),
                        Expanded(
                          child: Stack(
                            children: <Widget>[
                              DrawingCanvas(
                                strokes: _localStrokes,
                                onStrokeDrawn: _handleLocalStrokeDrawn,
                                isEnabled: _roomJoined && _peerPresent,
                                color: _drawColor,
                                width: _drawWidth,
                                style: _drawStyle,
                              ),
                              ..._buildEmotesLayer(_localEmotes),
                            ],
                          ),
                        ),
                      ],
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

  void _startEmoteAnimationTimer() {
    _emoteAnimationTimer?.cancel();
    _emoteAnimationTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_localEmotes.isEmpty && _remoteEmotes.isEmpty) {
        _emoteAnimationTimer?.cancel();
        _emoteAnimationTimer = null;
        return;
      }
      if (mounted) {
        setState(() {
          // Trigger rebuild for animation
        });
      }
    });
  }

  double _randomEmoteXPercent() {
    return 10 + (math.Random().nextDouble() * 75);
  }

  List<Widget> _buildEmotesLayer(List<AnimatedEmote> emotes) {
    if (emotes.isEmpty) {
      return const <Widget>[];
    }

    return <Widget>[
      Positioned.fill(
        child: IgnorePointer(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double canvasWidth = constraints.maxWidth;
              final double maxLeft = math.max(10.0, canvasWidth - 40.0);

              return Stack(
                children: emotes.map((AnimatedEmote emote) {
                  final Duration elapsed = DateTime.now().difference(emote.startTime);
                  final double progress = (elapsed.inMilliseconds / 4200).clamp(0.0, 1.0);

                  final double opacity = progress < 0.8 ? 1.0 : (1.0 - (progress - 0.8) / 0.2);
                  final double offsetY = (1.0 - progress) * 80.0;
                  final double left = ((emote.x.clamp(10.0, 85.0) / 100.0) * canvasWidth)
                      .clamp(10.0, maxLeft);

                  return Positioned(
                    left: left,
                    bottom: 20 + offsetY,
                    child: Opacity(
                      opacity: opacity,
                      child: Text(
                        emote.emoji,
                        style: const TextStyle(
                          fontSize: 32,
                          height: 1.0,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    ];
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

  Widget _buildLocalQuickActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      color: const Color(0xFFFFF1F2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _buildQuickActionButton(
            icon: Icons.cleaning_services_outlined,
            backgroundColor: const Color(0xFFFB7185),
            onPressed: (_roomJoined && _peerPresent) ? _handleClearLocal : null,
          ),
          const SizedBox(width: 8),
          if (!widget.isChatSaved)
            _buildQuickActionButton(
              icon: Icons.save_outlined,
              backgroundColor: const Color(0xFFE11D48),
              onPressed: _isSavingChat
                  ? null
                  : () {
                      unawaited(_handleSaveChat());
                    },
            ),
          if (!widget.isChatSaved) const SizedBox(width: 8),
          if (_showReconnectButton || _isReconnecting)
            _buildQuickActionButton(
              icon: Icons.sync,
              backgroundColor: const Color(0xFFF59E0B),
              onPressed: _isReconnecting ? null : () => unawaited(_handleReconnectToRoom()),
              isLoading: _isReconnecting,
            ),
          if (_showReconnectButton || _isReconnecting) const SizedBox(width: 8),
          _buildQuickActionButton(
            icon: Icons.emoji_emotions_outlined,
            backgroundColor: const Color(0xFFFBCFE8),
            iconColor: const Color(0xFF9F1239),
            onPressed: (_roomJoined && _peerPresent) ? _showEmotePicker : null,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback? onPressed,
    Color iconColor = Colors.white,
    bool isLoading = false,
  }) {
    final Color resolvedBackgroundColor =
        onPressed == null ? backgroundColor.withValues(alpha: 0.45) : backgroundColor;

    return SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: resolvedBackgroundColor,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: isLoading
              ? _buildSpinningIcon(icon, iconColor)
              : Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildSpinningIcon(IconData icon, Color color) {
    return RotationTransition(
      turns: _syncAnimationController,
      child: Icon(icon, size: 20, color: color),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            onPressed: (_roomJoined && _peerPresent) ? () => _showEmotePicker() : null,
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
        final double dialogWidth = math.min(MediaQuery.of(context).size.width * 0.86, 360);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.all(12),
          content: SizedBox(
            width: dialogWidth,
            height: 200,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
              child: Scrollbar(
                controller: _emotePickerScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                scrollbarOrientation: ScrollbarOrientation.bottom,
                child: GridView.builder(
                  controller: _emotePickerScrollController,
                  primary: false,
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: PresetEmotes.emotes.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String emoji = PresetEmotes.emotes[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        _handleSendEmote(emoji);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE7F3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28, height: 1.0),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
