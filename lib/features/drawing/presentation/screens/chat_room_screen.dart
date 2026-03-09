import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
    required this.onCloseChat,
    required this.isChatSaved,
    super.key,
  });

  final String chatRequestId;
  final ChatRequest chatRequest;
  final UserProfile profile;
  final Function(String message, String type) onNotice;
  final Future<void> Function() onSaveChat;
  final VoidCallback onCloseChat;
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
  final List<AnimatedEmote> _localEmotes = <AnimatedEmote>[];
  final List<AnimatedEmote> _remoteEmotes = <AnimatedEmote>[];

  static const List<String> _presetColors = <String>[
    '#e11d48',
    '#fb7185',
    '#f59e0b',
    '#10b981',
    '#0ea5e9',
  ];

  String _drawColor = '#be123c';
  DrawStrokeStyle _drawStyle = DrawStrokeStyle.normal;
  double _drawWidth = 2.0;
  bool _brushAccordionOpen = false;
  bool _strokeAccordionOpen = false;
  bool _eraserAccordionOpen = false;
  bool _colorAccordionOpen = false;
  bool _customColorAccordionOpen = false;
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
    if (data is! Map<String, dynamic>) {
      return;
    }

    final DrawPeerLeftPayload payload = DrawPeerLeftPayload.fromJson(data);
    
    // Determine who the peer is
    final String peerId = widget.profile.id == widget.chatRequest.fromUserId
        ? widget.chatRequest.toUserId
        : widget.chatRequest.fromUserId;
    
    // Only process if the user who left is our peer
    if (payload.userId != peerId) {
      return;
    }

    setState(() {
      _peerPresent = false;
      // Clear both canvases when peer leaves
      _localStrokes = <DrawSegmentStroke>[];
      _remoteStrokes = <DrawSegmentStroke>[];
    });
    _startReconnectButtonTimer();
    widget.onNotice('Peer left the room.', 'info');
  }

  void _onSocketError(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return;
    }

    final SocketErrorPayload payload = SocketErrorPayload.fromJson(data);
    
    // If we get "Not in a room" error, close the chat
    if (payload.status == 403 && 
        payload.message.toLowerCase().contains('not in a room')) {
      widget.onCloseChat();
      widget.onNotice('The other user has left the room.', 'error');
      return;
    }
    
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

  String? _normalizeHexColor(String value) {
    final String normalized = value.trim().toLowerCase().replaceAll('#', '');
    final RegExp hexColorPattern = RegExp(r'^[0-9a-f]{6}$');
    if (!hexColorPattern.hasMatch(normalized)) {
      return null;
    }
    return '#$normalized';
  }

  Color _parseHexColor(String value) {
    if (value == 'eraser') {
      return const Color(0xFF15803D);
    }

    final String? normalized = _normalizeHexColor(value);
    if (normalized == null) {
      return const Color(0xFFBE123C);
    }

    final String hex = normalized.substring(1);
    return Color(int.parse('FF$hex', radix: 16));
  }

  Future<String?> _showColorPaletteDialog() async {
    final String currentColor = _drawColor == 'eraser' ? '#be123c' : _drawColor;
    Color selectedColor = _parseHexColor(currentColor);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: const Text(
            'Pick a color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFBE123C),
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: ColorPicker(
                  paletteType: PaletteType.hueWheel,
                  pickerColor: selectedColor,
                  onColorChanged: (Color color) {
                    setState(() {
                      selectedColor = color;
                    });
                  },
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFFBE123C)),
              ),
            ),
            FilledButton(
              onPressed: () {
                final String hex = '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase().padLeft(6, '0')}';
                Navigator.of(context).pop(hex.toLowerCase());
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolAccordionSection({
    required String title,
    required bool isOpen,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            child: Row(
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBE123C),
                  ),
                ),
                const Spacer(),
                Icon(
                  isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 20,
                  color: const Color(0xFFBE123C),
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: child,
          ),
        const Divider(height: 1, color: Color(0xFFFDA4AF)),
      ],
    );
  }

  Future<void> _showToolsSheet() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            void updateTools(VoidCallback update) {
              setState(update);
              modalSetState(() {});
            }

            return Dialog(
              backgroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildToolAccordionSection(
                        title: 'Brush',
                        isOpen: _brushAccordionOpen,
                        onToggle: () {
                          updateTools(() {
                            _brushAccordionOpen = !_brushAccordionOpen;
                          });
                        },
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  updateTools(() {
                                    _drawStyle = DrawStrokeStyle.normal;
                                    if (_drawColor == 'eraser') {
                                      _drawColor = '#be123c';
                                    }
                                  });
                                },
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Pen'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF9F1239),
                                  backgroundColor: _drawStyle == DrawStrokeStyle.normal
                                      ? const Color(0xFFFBCFE8)
                                      : const Color(0xFFFFF1F2),
                                  side: BorderSide(
                                    color: _drawStyle == DrawStrokeStyle.normal
                                        ? const Color(0xFFE11D48)
                                        : const Color(0xFFFDA4AF),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  updateTools(() {
                                    _drawStyle = DrawStrokeStyle.brush;
                                    if (_drawColor == 'eraser') {
                                      _drawColor = '#be123c';
                                    }
                                  });
                                },
                                icon: const Icon(Icons.brush_outlined, size: 16),
                                label: const Text('Brush'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF9F1239),
                                  backgroundColor: _drawStyle == DrawStrokeStyle.brush
                                      ? const Color(0xFFFBCFE8)
                                      : const Color(0xFFFFF1F2),
                                  side: BorderSide(
                                    color: _drawStyle == DrawStrokeStyle.brush
                                        ? const Color(0xFFE11D48)
                                        : const Color(0xFFFDA4AF),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildToolAccordionSection(
                        title: 'Stroke',
                        isOpen: _strokeAccordionOpen,
                        onToggle: () {
                          updateTools(() {
                            _strokeAccordionOpen = !_strokeAccordionOpen;
                          });
                        },
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Slider(
                                value: _drawWidth,
                                min: 1,
                                max: 10,
                                divisions: 9,
                                label: _drawWidth.round().toString(),
                                activeColor: const Color(0xFFBE123C),
                                onChanged: (double value) {
                                  updateTools(() {
                                    _drawWidth = value.roundToDouble();
                                  });
                                },
                              ),
                            ),
                            Text(
                              _drawWidth.round().toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF9F1239),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildToolAccordionSection(
                        title: 'Eraser',
                        isOpen: _eraserAccordionOpen,
                        onToggle: () {
                          updateTools(() {
                            _eraserAccordionOpen = !_eraserAccordionOpen;
                          });
                        },
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  updateTools(() {
                                    _drawColor = 'eraser';
                                  });
                                },
                                icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                                label: const Text('Use eraser'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF166534),
                                  backgroundColor: _drawColor == 'eraser'
                                      ? const Color(0xFFD1FAE5)
                                      : const Color(0xFFF0FDF4),
                                  side: BorderSide(
                                    color: _drawColor == 'eraser'
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFF86EFAC),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildToolAccordionSection(
                        title: 'Color',
                        isOpen: _colorAccordionOpen,
                        onToggle: () {
                          updateTools(() {
                            _colorAccordionOpen = !_colorAccordionOpen;
                          });
                        },
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _presetColors.map((String color) {
                            final bool isSelected = _drawColor == color;
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                updateTools(() {
                                  _drawColor = color;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _parseHexColor(color),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFBE123C)
                                        : const Color(0xFFFDA4AF),
                                    width: isSelected ? 2.5 : 1.5,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      _buildToolAccordionSection(
                        title: 'Custom color',
                        isOpen: _customColorAccordionOpen,
                        onToggle: () {
                          updateTools(() {
                            _customColorAccordionOpen = !_customColorAccordionOpen;
                          });
                        },
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final String? selectedColor = await _showColorPaletteDialog();
                            if (!mounted || selectedColor == null) {
                              return;
                            }
                            updateTools(() {
                              _drawColor = selectedColor;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFDA4AF)),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.palette_outlined,
                                  size: 16,
                                  color: Color(0xFF9F1239),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Open color palette',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF9F1239),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _parseHexColor(_drawColor),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFDA4AF),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleToolsTap() {
    unawaited(_showToolsSheet());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Status bar
        Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 12, 4),
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
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
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
        // _buildControls(),
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
          const Spacer(),
          _buildQuickActionButton(
            icon: Icons.handyman_outlined,
            backgroundColor: const Color(0xFFFBCFE8),
            iconColor: const Color(0xFF9F1239),
            onPressed: _handleToolsTap,
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

  void _showEmotePicker() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final double dialogWidth = math.min(MediaQuery.of(context).size.width * 0.86, 360);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.all(0),
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
