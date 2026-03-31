import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../../core/realtime/socket_service.dart';
import '../../../home/domain/group_chat_models.dart';
import '../../../home/domain/home_models.dart';
import '../../models/drawing_models.dart';
import '../../widgets/drawing_canvas.dart';

/// Group drawing room screen.
///
/// Top area: mini-canvas grid (one per active peer) or focused single-peer
/// canvas when a mini canvas is tapped.
/// Bottom area: local canvas — identical to the 1-to-1 ChatRoomScreen.
class GroupRoomScreen extends StatefulWidget {
  const GroupRoomScreen({
    required this.groupId,
    required this.groupChat,
    required this.profile,
    required this.onNotice,
    required this.onCloseRoom,
    required this.onRefreshGroupChat,
    super.key,
  });

  final String groupId;
  final GroupChat groupChat;
  final UserProfile profile;
  final void Function(String message, String type) onNotice;
  final VoidCallback onCloseRoom;
  final Future<void> Function() onRefreshGroupChat;

  @override
  State<GroupRoomScreen> createState() => _GroupRoomScreenState();
}

class _GroupRoomScreenState extends State<GroupRoomScreen>
    with TickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  final ScrollController _emotePickerScrollController = ScrollController();

  // Local drawing state
  List<DrawSegmentStroke> _localStrokes = <DrawSegmentStroke>[];

  // Per-peer remote strokes
  final Map<String, List<DrawSegmentStroke>> _remoteStrokesByUserId =
      <String, List<DrawSegmentStroke>>{};

  final List<AnimatedEmote> _localEmotes = <AnimatedEmote>[];
  final Map<String, List<AnimatedEmote>> _remoteEmotesByUserId =
      <String, List<AnimatedEmote>>{};

  Set<String> _activePeerIds = <String>{};
  bool _roomJoined = false;
  bool _isReconnecting = false;
  bool _showReconnectButton = false;
  bool _hasHandledNotInRoomError = false;
  bool _groupDeletedHandled = false;
  Timer? _reconnectButtonTimer;

  /// null = mini-canvas grid mode; non-null = focused on a single peer
  String? _focusedPeerId;

  // Drawing tool state
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

  late AnimationController _syncAnimationController;
  late AnimationController _chevronAnimationController;
  late Animation<double> _chevronAnimation;
  final ScrollController _gridScrollController = ScrollController();
  bool _showScrollDown = false;
  bool _showScrollUp = false;
  Timer? _emoteAnimationTimer;

  @override
  void initState() {
    super.initState();
    _syncAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chevronAnimationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat(reverse: true);
    _chevronAnimation = CurvedAnimation(
      parent: _chevronAnimationController,
      curve: Curves.easeInOut,
    );
    _gridScrollController.addListener(_onGridScroll);
    _setupSocketListeners();
    _joinGroupRoom();
  }

  @override
  void dispose() {
    _emoteAnimationTimer?.cancel();
    _reconnectButtonTimer?.cancel();
    _emotePickerScrollController.dispose();
    _syncAnimationController.dispose();
    _chevronAnimationController.dispose();
    _gridScrollController.dispose();
    _removeSocketListeners();
    super.dispose();
  }

  // ─── Socket ────────────────────────────────────────────────────────────────

  void _setupSocketListeners() {
    final socket = _socketService.socket;
    if (socket == null) return;

    socket.on('group.joined', _onGroupJoined);
    socket.on('group.member.joined', _onGroupMemberJoined);
    socket.on('group.member.left', _onGroupMemberLeft);
    socket.on('draw.peer.left', _onDrawPeerLeft);
    socket.on('draw.stroke', _onDrawStroke);
    socket.on('draw.clear', _onDrawClear);
    socket.on('draw.emote', _onDrawEmote);
    socket.on('group.removed', _onGroupRemoved);
    socket.on('group.deleted', _onGroupDeleted);
    socket.on('draw.room.closed', _onDrawRoomClosed);
    socket.on('error', _onSocketError);
    socket.on('connect_error', _onSocketError);
  }

  void _removeSocketListeners() {
    final socket = _socketService.socket;
    if (socket == null) return;

    socket.off('group.joined', _onGroupJoined);
    socket.off('group.member.joined', _onGroupMemberJoined);
    socket.off('group.member.left', _onGroupMemberLeft);
    socket.off('draw.peer.left', _onDrawPeerLeft);
    socket.off('draw.stroke', _onDrawStroke);
    socket.off('draw.clear', _onDrawClear);
    socket.off('draw.emote', _onDrawEmote);
    socket.off('group.removed', _onGroupRemoved);
    socket.off('group.deleted', _onGroupDeleted);
    socket.off('draw.room.closed', _onDrawRoomClosed);
    socket.off('error', _onSocketError);
    socket.off('connect_error', _onSocketError);
  }

  void _joinGroupRoom() {
    _socketService.emitGroupJoin(widget.groupId);
  }

  void _onGroupJoined(dynamic data) {
    if (data is! Map<String, dynamic>) return;
    final GroupJoinedPayload payload = GroupJoinedPayload.fromJson(data);
    if (payload.groupId != widget.groupId) return;
    final Set<String> peers = payload.peers
        .where((String id) => id != widget.profile.id)
        .toSet();
    setState(() {
      _roomJoined = true;
      _activePeerIds = peers;
    });
    if (peers.isEmpty) {
      _startReconnectButtonTimer();
    } else {
      _reconnectButtonTimer?.cancel();
      setState(() {
        _showReconnectButton = false;
      });
    }
    widget.onNotice('Joined group room', 'success');
    _refreshIfMembersStale(peers);
    _scheduleScrollCheck();
  }

  void _onGroupMemberJoined(dynamic data) {
    if (data is! Map<String, dynamic>) return;
    final GroupMemberEventPayload payload =
        GroupMemberEventPayload.fromJson(data);
    if (payload.userId == widget.profile.id) return;
    setState(() {
      _activePeerIds.add(payload.userId);
      _showReconnectButton = false;
    });
    _refreshIfMembersStale(<String>{payload.userId});
    _reconnectButtonTimer?.cancel();
    _scheduleScrollCheck();
  }

  void _onGroupMemberLeft(dynamic data) {
    if (data is! Map<String, dynamic>) return;
    final GroupMemberEventPayload payload =
        GroupMemberEventPayload.fromJson(data);
    setState(() {
      _activePeerIds.remove(payload.userId);
      _remoteStrokesByUserId.remove(payload.userId);
      _remoteEmotesByUserId.remove(payload.userId);
      if (_focusedPeerId == payload.userId) {
        _focusedPeerId = null;
      }
    });
    if (_activePeerIds.isEmpty) {
      _startReconnectButtonTimer();
    }
    _scheduleScrollCheck();
  }

  void _onDrawPeerLeft(dynamic data) {
    // Same handling as group.member.left for group context
    _onGroupMemberLeft(data);
  }

  void _onDrawStroke(dynamic data) {
    if (data is! Map<String, dynamic>) return;

    // Only handle group strokes (those without requestId or with groupId)
    final String? groupId = data['groupId'] as String?;
    final String? requestId = data['requestId'] as String?;
    if (requestId != null && groupId == null) return;
    if (groupId != null && groupId != widget.groupId) return;

    final dynamic strokeData = data['stroke'];
    final String? userId = data['userId'] as String?;
    if (userId == null || userId == widget.profile.id) return;
    if (!DrawSegmentStroke.isValid(strokeData)) return;

    final DrawSegmentStroke stroke = DrawSegmentStroke.fromJson(
      strokeData as Map<String, dynamic>,
    );

    setState(() {
      _activePeerIds.add(userId);
      _remoteStrokesByUserId.putIfAbsent(userId, () => <DrawSegmentStroke>[]);
      _remoteStrokesByUserId[userId]!.add(stroke);
    });
  }

  void _onDrawClear(dynamic data) {
    if (data is! Map<String, dynamic>) return;

    final String? groupId = data['groupId'] as String?;
    final String? requestId = data['requestId'] as String?;
    if (requestId != null && groupId == null) return;
    if (groupId != null && groupId != widget.groupId) return;

    final String? userId = data['userId'] as String?;
    if (userId == null || userId == widget.profile.id) return;

    setState(() {
      _remoteStrokesByUserId[userId] = <DrawSegmentStroke>[];
    });
  }

  void _onDrawEmote(dynamic data) {
    if (data is! Map<String, dynamic>) return;

    final String? groupId = data['groupId'] as String?;
    final String? requestId = data['requestId'] as String?;
    if (requestId != null && groupId == null) return;
    if (groupId != null && groupId != widget.groupId) return;

    final String? emoji = data['emoji'] as String?;
    final String? userId = data['userId'] as String?;
    if (emoji == null || userId == null || userId == widget.profile.id) return;

    final AnimatedEmote emote = AnimatedEmote(
      id: '${DateTime.now().millisecondsSinceEpoch}-$emoji',
      emoji: emoji,
      x: _randomEmoteXPercent(),
      startTime: DateTime.now(),
    );

    setState(() {
      _remoteEmotesByUserId.putIfAbsent(userId, () => <AnimatedEmote>[]);
      _remoteEmotesByUserId[userId]!.add(emote);
    });

    _startEmoteAnimationTimer();

    Future<void>.delayed(const Duration(milliseconds: 4200), () {
      if (mounted) {
        setState(() {
          _remoteEmotesByUserId[userId]
              ?.removeWhere((AnimatedEmote e) => e.id == emote.id);
        });
      }
    });
  }

  void _onGroupRemoved(dynamic data) {
    String reason = 'You were removed from the group.';
    if (data is Map<String, dynamic>) {
      try {
        final GroupRemovedPayload payload = GroupRemovedPayload.fromJson(data);
        if (payload.reason.isNotEmpty) reason = payload.reason;
      } catch (_) {}
    }
    widget.onNotice(reason, 'error');
    widget.onCloseRoom();
  }

  void _onGroupDeleted(dynamic data) {
    // Verify this event is for our group when the payload carries a groupId.
    if (data is Map<String, dynamic>) {
      final String? gid = data['groupId'] as String?;
      if (gid != null && gid.isNotEmpty && gid != widget.groupId) return;
    }
    _groupDeletedHandled = true;
    widget.onNotice('This group was deleted by the owner.', 'error');
    widget.onCloseRoom();
  }

  void _onDrawRoomClosed(dynamic data) {
    // No-op if group.deleted was already handled for this group.
    if (_groupDeletedHandled) return;
    widget.onNotice('This group was deleted.', 'error');
    widget.onCloseRoom();
  }

  void _onSocketError(dynamic data) {
    if (_socketService.isConnectivityError(data)) {
      widget.onNotice(SocketService.offlineConnectionMessage, 'error');
      return;
    }
    if (data is Map<String, dynamic>) {
      try {
        final SocketErrorPayload payload = SocketErrorPayload.fromJson(data);
        // "Not in a room" fires repeatedly — only handle it once
        if (payload.status == 403 &&
            payload.message.toLowerCase().contains('not in a room')) {
          if (_hasHandledNotInRoomError) return;
          _reconnectButtonTimer?.cancel();
          setState(() {
            _hasHandledNotInRoomError = true;
            _roomJoined = false;
            _showReconnectButton = true;
          });
          widget.onNotice('Not in a room. Tap sync to rejoin.', 'error');
          return;
        }
        widget.onNotice(payload.message, 'error');
      } catch (_) {}
    }
  }

  void _startReconnectButtonTimer() {
    _reconnectButtonTimer?.cancel();
    _reconnectButtonTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && (_activePeerIds.isEmpty || !_roomJoined)) {
        setState(() {
          _showReconnectButton = true;
        });
      }
    });
  }

  Future<void> _handleRejoinRoom() async {
    if (_isReconnecting) return;
    setState(() {
      _isReconnecting = true;
      _showReconnectButton = false;
      _hasHandledNotInRoomError = false;
    });
    _reconnectButtonTimer?.cancel();
    _syncAnimationController.repeat();

    try {
      _socketService.emitGroupJoin(widget.groupId);
      await Future<void>.delayed(const Duration(milliseconds: 3000));
    } finally {
      if (mounted) {
        _syncAnimationController.stop();
        setState(() {
          _isReconnecting = false;
        });
        _reconnectButtonTimer?.cancel();
        _reconnectButtonTimer = Timer(const Duration(seconds: 60), () {
          if (mounted && (_activePeerIds.isEmpty || !_roomJoined)) {
            setState(() {
              _showReconnectButton = true;
            });
          }
        });
      }
    }
  }

  void _refreshIfMembersStale(Set<String> peerIds) {
    final Set<String> knownIds =
        widget.groupChat.members.map((GroupMember m) => m.userId).toSet();
    if (peerIds.any((String id) => !knownIds.contains(id))) {
      unawaited(widget.onRefreshGroupChat());
    }
  }

  void _onGridScroll() {
    if (!_gridScrollController.hasClients) return;
    final ScrollPosition pos = _gridScrollController.position;
    final bool canScrollDown = pos.pixels < pos.maxScrollExtent - 4;
    final bool canScrollUp = pos.pixels > 4;
    if (canScrollDown != _showScrollDown || canScrollUp != _showScrollUp) {
      setState(() {
        _showScrollDown = canScrollDown;
        _showScrollUp = canScrollUp;
      });
    }
  }

  void _scheduleScrollCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onGridScroll();
    });
  }

  // ─── Local drawing ─────────────────────────────────────────────────────────

  void _handleLocalStrokeDrawn(DrawSegmentStroke stroke) {
    if (!_roomJoined || _activePeerIds.isEmpty) return;
    setState(() {
      _localStrokes.add(stroke);
    });
    _socketService.emitGroupDrawStroke(
      widget.groupId,
      stroke.toJson(),
      widget.profile.id,
    );
  }

  void _handleClearLocal() {
    if (!_roomJoined || _activePeerIds.isEmpty) return;
    setState(() {
      _localStrokes = <DrawSegmentStroke>[];
    });
    _socketService.emitGroupDrawClear(widget.groupId, widget.profile.id);
  }

  void _handleSendEmote(String emoji) {
    if (!_roomJoined) return;
    _socketService.emitGroupDrawEmote(
        widget.groupId, emoji, widget.profile.id);

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

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _displayNameForPeer(String userId) {
    for (final GroupMember m in widget.groupChat.members) {
      if (m.userId == userId) return m.user.displayName;
    }
    return userId.substring(0, math.min(8, userId.length));
  }

  double _randomEmoteXPercent() => 10 + (math.Random().nextDouble() * 75);

  void _startEmoteAnimationTimer() {
    _emoteAnimationTimer?.cancel();
    _emoteAnimationTimer =
        Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_localEmotes.isEmpty &&
          _remoteEmotesByUserId.values
              .every((List<AnimatedEmote> l) => l.isEmpty)) {
        _emoteAnimationTimer?.cancel();
        _emoteAnimationTimer = null;
        return;
      }
      if (mounted) setState(() {});
    });
  }

  List<Widget> _buildEmotesLayer(List<AnimatedEmote> emotes) {
    if (emotes.isEmpty) return const <Widget>[];
    return <Widget>[
      Positioned.fill(
        child: IgnorePointer(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double canvasWidth = constraints.maxWidth;
              final double maxLeft = math.max(10.0, canvasWidth - 40.0);
              return Stack(
                children: emotes.map((AnimatedEmote emote) {
                  final Duration elapsed =
                      DateTime.now().difference(emote.startTime);
                  final double progress =
                      (elapsed.inMilliseconds / 4200).clamp(0.0, 1.0);
                  final double opacity =
                      progress < 0.8 ? 1.0 : (1.0 - (progress - 0.8) / 0.2);
                  final double offsetY = (1.0 - progress) * 80.0;
                  final double left =
                      ((emote.x.clamp(10.0, 85.0) / 100.0) * canvasWidth)
                          .clamp(10.0, maxLeft);
                  return Positioned(
                    left: left,
                    bottom: 20 + offsetY,
                    child: Opacity(
                      opacity: opacity,
                      child: Text(
                        emote.emoji,
                        style: const TextStyle(fontSize: 32, height: 1.0),
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

  Color _parseHexColor(String value) {
    if (value == 'eraser') return const Color(0xFF15803D);
    try {
      final String hex = value.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFFBE123C);
  }

  Future<String?> _showColorPaletteDialog() async {
    final String currentColor =
        _drawColor == 'eraser' ? '#be123c' : _drawColor;
    Color selectedColor = _parseHexColor(currentColor);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text('Pick a color',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFBE123C))),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: ColorPicker(
                  paletteType: PaletteType.hueWheel,
                  pickerColor: selectedColor,
                  onColorChanged: (Color color) =>
                      setState(() => selectedColor = color),
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFFBE123C))),
            ),
            FilledButton(
              onPressed: () {
                final String hex =
                    '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase().padLeft(6, '0')}';
                Navigator.of(context).pop(hex.toLowerCase());
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(1)),
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
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            child: Row(
              children: <Widget>[
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFBE123C))),
                const Spacer(),
                Icon(isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    size: 20, color: const Color(0xFFBE123C)),
              ],
            ),
          ),
        ),
        if (isOpen)
          Padding(padding: const EdgeInsets.only(bottom: 10), child: child),
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
                  borderRadius: BorderRadius.circular(8)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildToolAccordionSection(
                        title: 'Brush',
                        isOpen: _brushAccordionOpen,
                        onToggle: () => updateTools(
                            () => _brushAccordionOpen = !_brushAccordionOpen),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => updateTools(() {
                                  _drawStyle = DrawStrokeStyle.normal;
                                  if (_drawColor == 'eraser') {
                                    _drawColor = '#be123c';
                                  }
                                }),
                                icon: const Icon(Icons.edit_outlined,
                                    size: 16),
                                label: const Text('Pen'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF9F1239),
                                  backgroundColor:
                                      _drawStyle == DrawStrokeStyle.normal
                                          ? const Color(0xFFFBCFE8)
                                          : const Color(0xFFFFF1F2),
                                  side: BorderSide(
                                    color:
                                        _drawStyle == DrawStrokeStyle.normal
                                            ? const Color(0xFFE11D48)
                                            : const Color(0xFFFDA4AF),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(1)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => updateTools(() {
                                  _drawStyle = DrawStrokeStyle.brush;
                                  if (_drawColor == 'eraser') {
                                    _drawColor = '#be123c';
                                  }
                                }),
                                icon: const Icon(Icons.brush_outlined,
                                    size: 16),
                                label: const Text('Brush'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF9F1239),
                                  backgroundColor:
                                      _drawStyle == DrawStrokeStyle.brush
                                          ? const Color(0xFFFBCFE8)
                                          : const Color(0xFFFFF1F2),
                                  side: BorderSide(
                                    color: _drawStyle ==
                                            DrawStrokeStyle.brush
                                        ? const Color(0xFFE11D48)
                                        : const Color(0xFFFDA4AF),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(1)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildToolAccordionSection(
                        title: 'Stroke',
                        isOpen: _strokeAccordionOpen,
                        onToggle: () => updateTools(() =>
                            _strokeAccordionOpen = !_strokeAccordionOpen),
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
                                onChanged: (double v) => updateTools(
                                    () => _drawWidth = v.roundToDouble()),
                              ),
                            ),
                            Text(_drawWidth.round().toString(),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF9F1239))),
                          ],
                        ),
                      ),
                      _buildToolAccordionSection(
                        title: 'Eraser',
                        isOpen: _eraserAccordionOpen,
                        onToggle: () => updateTools(() =>
                            _eraserAccordionOpen = !_eraserAccordionOpen),
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              updateTools(() => _drawColor = 'eraser'),
                          icon: const Icon(Icons.auto_fix_high_outlined,
                              size: 16),
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
                            minimumSize: const Size(double.infinity, 36),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(1)),
                          ),
                        ),
                      ),
                      _buildToolAccordionSection(
                        title: 'Color',
                        isOpen: _colorAccordionOpen,
                        onToggle: () => updateTools(
                            () => _colorAccordionOpen = !_colorAccordionOpen),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _presetColors.map((String color) {
                            final bool isSelected = _drawColor == color;
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  updateTools(() => _drawColor = color),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 120),
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
                        onToggle: () => updateTools(() =>
                            _customColorAccordionOpen =
                                !_customColorAccordionOpen),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final String? selected =
                                await _showColorPaletteDialog();
                            if (!mounted || selected == null) return;
                            updateTools(() => _drawColor = selected);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFFDA4AF)),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.palette_outlined,
                                    size: 16, color: Color(0xFF9F1239)),
                                const SizedBox(width: 8),
                                const Text('Open color palette',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF9F1239))),
                                const Spacer(),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _parseHexColor(_drawColor),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFFFDA4AF),
                                        width: 1.5),
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

  void _showEmotePicker() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final double dialogWidth =
            math.min(MediaQuery.of(context).size.width * 0.86, 360);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.zero,
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
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
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
                        child: Text(emoji,
                            style: const TextStyle(
                                fontSize: 28, height: 1.0)),
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

  Widget _buildQuickActionButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback? onPressed,
    Color iconColor = Colors.white,
    bool isLoading = false,
  }) {
    final Color resolved = onPressed == null
        ? backgroundColor.withValues(alpha: 0.45)
        : backgroundColor;
    return SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: resolved,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: iconColor),
                )
              : Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildLocalQuickActions() {
    final bool canDraw = _roomJoined && _activePeerIds.isNotEmpty;
    final bool showSync = _showReconnectButton || _isReconnecting;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      color: const Color(0xFFFFF1F2),
      child: Row(
        children: <Widget>[
          _buildQuickActionButton(
            icon: Icons.cleaning_services_outlined,
            backgroundColor: const Color(0xFFFB7185),
            onPressed: canDraw ? _handleClearLocal : null,
          ),
          const SizedBox(width: 8),
          _buildQuickActionButton(
            icon: Icons.emoji_emotions_outlined,
            backgroundColor: const Color(0xFFFBCFE8),
            iconColor: const Color(0xFF9F1239),
            onPressed:
                _roomJoined ? _showEmotePicker : null,
          ),
          if (showSync) const SizedBox(width: 8),
          if (showSync)
            _buildQuickActionButton(
              icon: Icons.sync,
              backgroundColor: const Color(0xFFF59E0B),
              onPressed:
                  _isReconnecting ? null : () => unawaited(_handleRejoinRoom()),
              isLoading: _isReconnecting,
            ),
          const Spacer(),
          _buildQuickActionButton(
            icon: Icons.handyman_outlined,
            backgroundColor: const Color(0xFFFBCFE8),
            iconColor: const Color(0xFF9F1239),
            onPressed: () => unawaited(_showToolsSheet()),
          ),
        ],
      ),
    );
  }

  // ─── Top area builders ─────────────────────────────────────────────────────

  Widget _buildMiniCanvasGrid() {
    final List<String> peers = _activePeerIds.toList();

    if (peers.isEmpty) {
      return Center(
        child: Text(
          _roomJoined
              ? 'Waiting for others to join…'
              : _hasHandledNotInRoomError
                  ? 'Not in room. Tap sync to rejoin.'
                  : 'Connecting to group room…',
          style: const TextStyle(
            color: Color(0xFF9F1239),
            fontSize: 13,
          ),
        ),
      );
    }

    return Stack(
      children: <Widget>[
        LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // 2×2 grid: each tile is half the available height
        final double tileHeight = constraints.maxHeight / 2;

        return GridView.builder(
          controller: _gridScrollController,
          physics: const ClampingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: constraints.maxWidth / 2 / tileHeight,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
          ),
          itemCount: peers.length,
          itemBuilder: (BuildContext context, int index) {
            final String userId = peers[index];
            final List<DrawSegmentStroke> strokes =
                _remoteStrokesByUserId[userId] ?? <DrawSegmentStroke>[];
            final String displayName = _displayNameForPeer(userId);

            return Padding(
              padding: const EdgeInsets.all(2),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _focusedPeerId = userId),
                child: _buildCanvasCard(
                    child: Stack(
                      children: <Widget>[
                        DrawingCanvas(
                          key: ValueKey<String>('mini-$userId'),
                          strokes: strokes,
                          onStrokeDrawn: (_) {},
                          isEnabled: false,
                          color: _drawColor,
                          width: _drawWidth,
                          style: _drawStyle,
                        ),
                        ..._buildEmotesLayer(
                          _remoteEmotesByUserId[userId] ?? <AnimatedEmote>[],
                        ),
                        // Display name label
                        Positioned(
                          top: 4,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        // Tap-to-expand hint overlay (bottom-right)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.open_in_full,
                                size: 12, color: Colors.white),
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
    ),
        if (_showScrollUp)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildScrollChevron(up: true),
          ),
        if (_showScrollDown)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildScrollChevron(up: false),
          ),
      ],
    );
  }

  Widget _buildScrollChevron({required bool up}) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _chevronAnimation,
        builder: (BuildContext context, Widget? child) {
          final double offsetY = up
              ? -(4.0 * _chevronAnimation.value)
              : 4.0 * _chevronAnimation.value;
          return Transform.translate(
            offset: Offset(0, offsetY),
            child: child,
          );
        },
        child: SizedBox(
          height: 28,
          child: Center(
            child: Icon(
              up ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: const Color(0xFF9F1239).withValues(alpha: 0.99),
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusedCanvas() {
    final String userId = _focusedPeerId!;
    final List<DrawSegmentStroke> strokes =
        _remoteStrokesByUserId[userId] ?? <DrawSegmentStroke>[];
    final String displayName = _displayNameForPeer(userId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Header with back button
        Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
          color: const Color(0xFFFCE7F3),
          child: Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.grid_view,
                    size: 20, color: Color(0xFF9F1239)),
                onPressed: () {
                  setState(() => _focusedPeerId = null);
                  _scheduleScrollCheck();
                },
                tooltip: 'Back to all canvases',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9F1239),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: _buildCanvasCard(
              child: Stack(
                children: <Widget>[
                  DrawingCanvas(
                    key: ValueKey<String>('focused-$userId'),
                    strokes: strokes,
                    onStrokeDrawn: (_) {},
                    isEnabled: false,
                    color: _drawColor,
                    width: _drawWidth,
                    style: _drawStyle,
                  ),
                  ..._buildEmotesLayer(
                    _remoteEmotesByUserId[userId] ?? <AnimatedEmote>[],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Status bar
        Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 12, 4),
          color: const Color(0xFFFCE7F3),
          child: Row(
            children: <Widget>[
              Icon(
                _roomJoined ? Icons.check_circle : Icons.pending,
                color: _roomJoined
                    ? const Color(0xFF059669)
                    : const Color(0xFF9F1239),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _roomJoined
                      ? '${widget.groupChat.name}  ·  ${_activePeerIds.length} ${_activePeerIds.length == 1 ? 'peer' : 'peers'} online'
                      : 'Joining ${widget.groupChat.name}…',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _roomJoined
                        ? const Color(0xFF059669)
                        : const Color(0xFF9F1239),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Drawing area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
            child: Column(
              children: <Widget>[
                // Top: peers' canvases
                Expanded(
                  child: _focusedPeerId != null
                      ? _buildFocusedCanvas()
                      : _buildMiniCanvasGrid(),
                ),

                const SizedBox(height: 12),

                // Bottom: local canvas
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
                                isEnabled: _roomJoined && _activePeerIds.isNotEmpty,
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
      ],
    );
  }
}
