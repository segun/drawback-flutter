import 'dart:ui';

/// Normalized point with coordinates in range [0, 1]
class NormalizedPoint {
  const NormalizedPoint({required this.x, required this.y});

  factory NormalizedPoint.fromJson(Map<String, dynamic> json) {
    return NormalizedPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  final double x;
  final double y;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'x': x,
      'y': y,
    };
  }

  /// Convert normalized point to canvas coordinates
  Offset toOffset(Size canvasSize) {
    return Offset(
      x * canvasSize.width,
      y * canvasSize.height,
    );
  }

  /// Create normalized point from canvas coordinates
  static NormalizedPoint fromOffset(Offset offset, Size canvasSize) {
    if (canvasSize.width == 0 || canvasSize.height == 0) {
      return const NormalizedPoint(x: 0, y: 0);
    }

    final double normalizedX = (offset.dx / canvasSize.width).clamp(0.0, 1.0);
    final double normalizedY = (offset.dy / canvasSize.height).clamp(0.0, 1.0);

    return NormalizedPoint(x: normalizedX, y: normalizedY);
  }
}

/// Drawing stroke style
enum DrawStrokeStyle {
  normal,
  brush;

  String toJson() => name;

  static DrawStrokeStyle fromJson(String value) {
    return DrawStrokeStyle.values.firstWhere(
      (DrawStrokeStyle e) => e.name == value,
      orElse: () => DrawStrokeStyle.normal,
    );
  }
}

/// Type-safe stroke width (1-10)
class DrawStrokeWidth {
  const DrawStrokeWidth(this.value)
      : assert(value >= 1 && value <= 10, 'Stroke width must be between 1 and 10');

  final int value;

  static const DrawStrokeWidth w1 = DrawStrokeWidth(1);
  static const DrawStrokeWidth w2 = DrawStrokeWidth(2);
  static const DrawStrokeWidth w3 = DrawStrokeWidth(3);
  static const DrawStrokeWidth w4 = DrawStrokeWidth(4);
  static const DrawStrokeWidth w5 = DrawStrokeWidth(5);
  static const DrawStrokeWidth w6 = DrawStrokeWidth(6);
  static const DrawStrokeWidth w7 = DrawStrokeWidth(7);
  static const DrawStrokeWidth w8 = DrawStrokeWidth(8);
  static const DrawStrokeWidth w9 = DrawStrokeWidth(9);
  static const DrawStrokeWidth w10 = DrawStrokeWidth(10);

  int toJson() => value;

  static DrawStrokeWidth fromJson(int value) {
    return DrawStrokeWidth(value.clamp(1, 10));
  }
}

/// Drawing segment stroke (basic shape for drawing)
class DrawSegmentStroke {
  const DrawSegmentStroke({
    required this.from,
    required this.to,
    required this.color,
    required this.width,
    this.style = DrawStrokeStyle.normal,
  });

  factory DrawSegmentStroke.fromJson(Map<String, dynamic> json) {
    return DrawSegmentStroke(
      from: NormalizedPoint.fromJson(json['from'] as Map<String, dynamic>),
      to: NormalizedPoint.fromJson(json['to'] as Map<String, dynamic>),
      color: json['color'] as String,
      width: (json['width'] as num).toDouble(),
      style: json['style'] != null
          ? DrawStrokeStyle.fromJson(json['style'] as String)
          : DrawStrokeStyle.normal,
    );
  }

  final NormalizedPoint from;
  final NormalizedPoint to;
  final String color; // Color hex or 'eraser'
  final double width;
  final DrawStrokeStyle style;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'kind': 'segment',
      'from': from.toJson(),
      'to': to.toJson(),
      'color': color,
      'width': width,
      'style': style.toJson(),
    };
  }

  /// Validate if a JSON object is a valid DrawSegmentStroke
  static bool isValid(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return false;
    }

    if (json['kind'] != 'segment') {
      return false;
    }

    try {
      final dynamic fromData = json['from'];
      final dynamic toData = json['to'];

      if (fromData is! Map<String, dynamic> || toData is! Map<String, dynamic>) {
        return false;
      }

      final double? fromX = (fromData['x'] as num?)?.toDouble();
      final double? fromY = (fromData['y'] as num?)?.toDouble();
      final double? toX = (toData['x'] as num?)?.toDouble();
      final double? toY = (toData['y'] as num?)?.toDouble();

      if (fromX == null ||
          fromY == null ||
          toX == null ||
          toY == null ||
          !fromX.isFinite ||
          !fromY.isFinite ||
          !toX.isFinite ||
          !toY.isFinite) {
        return false;
      }

      if (json['color'] is! String) {
        return false;
      }

      final num? width = json['width'] as num?;
      if (width == null || !width.toDouble().isFinite) {
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Animated emote that floats up from the canvas
class AnimatedEmote {
  AnimatedEmote({
    required this.id,
    required this.emoji,
    required this.x,
    required this.startTime,
  });

  final String id;
  final String emoji;
  final double x; // Horizontal position percentage (0-100)
  final DateTime startTime;

  bool get isExpired {
    return DateTime.now().difference(startTime).inMilliseconds > 4200;
  }
}

/// Preset emotes for quick selection
class PresetEmotes {
  static const List<String> emotes = <String>[
    '❤️', '😂', '🔥', '👏', '😮', '💡', '🎉', '💯', '👍', '🥳',
    '😊', '😍', '🤗', '😎', '🤔', '😇', '🥺', '😢', '😭', '😡',
    '🤩', '😱', '🤯', '😴', '🤓', '🥰', '😘', '😜', '😋', '🤪',
    '🙌', '👋', '🤝', '💪', '🙏', '✨', '⭐', '🌟', '💫', '☀️',
    '🌈', '🎈', '🎊', '🎁', '🏆', '🥇', '💝', '💖', '💗', '💓',
    '✅', '❌', '⚡', '🚀', '🌺', '🌸', '🌻', '🌹', '🍕', '🍰',
  ];
}
