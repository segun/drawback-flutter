import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/drawing_models.dart';

const double eraserWidth = 40.0;

/// Custom painter for drawing strokes on canvas
class DrawingCanvasPainter extends CustomPainter {
  const DrawingCanvasPainter({required this.strokes});

  final List<DrawSegmentStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final DrawSegmentStroke stroke in strokes) {
      _drawStroke(canvas, size, stroke);
    }
  }

  void _drawStroke(Canvas canvas, Size size, DrawSegmentStroke stroke) {
    final Offset from = stroke.from.toOffset(size);
    final Offset to = stroke.to.toOffset(size);

    if (stroke.color == 'eraser') {
      // Eraser mode - clear pixels
      final Paint eraserPaint = Paint()
        ..blendMode = BlendMode.clear
        ..color = Colors.transparent
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawLine(from, to, eraserPaint);
    } else if (stroke.style == DrawStrokeStyle.brush) {
      // Brush style - multi-layer effect
      _drawBrushStroke(canvas, from, to, stroke);
    } else {
      // Normal style - simple line
      final Paint paint = Paint()
        ..color = _parseColor(stroke.color)
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawLine(from, to, paint);
    }
  }

  void _drawBrushStroke(Canvas canvas, Offset from, Offset to, DrawSegmentStroke stroke) {
    final Color color = _parseColor(stroke.color);
    final double dx = to.dx - from.dx;
    final double dy = to.dy - from.dy;
    final double distance = math.sqrt(dx * dx + dy * dy);
    final double unitX = distance > 0 ? dx / distance : 0;
    final double unitY = distance > 0 ? dy / distance : 0;
    final double trailingOffset = math.min(stroke.width * 0.6, 10);

    // Layer 1: Wide, translucent base
    final Paint basePaint = Paint()
      ..color = color.withAlpha((255 * 0.25).toInt())
      ..strokeWidth = stroke.width * 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(from, to, basePaint);

    // Layer 2: Main stroke
    final Paint mainPaint = Paint()
      ..color = color.withAlpha((255 * 0.95).toInt())
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(from, to, mainPaint);

    // Layer 3: Trailing effect
    final Paint trailPaint = Paint()
      ..color = color.withAlpha((255 * 0.18).toInt())
      ..strokeWidth = math.max(1, stroke.width * 0.7)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Offset trailFrom = Offset(
      from.dx - unitX * trailingOffset,
      from.dy - unitY * trailingOffset,
    );
    final Offset trailTo = Offset(
      to.dx - unitX * trailingOffset,
      to.dy - unitY * trailingOffset,
    );
    canvas.drawLine(trailFrom, trailTo, trailPaint);
  }

  Color _parseColor(String colorString) {
    try {
      // Handle hex colors like '#be123c'
      if (colorString.startsWith('#')) {
        final String hex = colorString.substring(1);
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      }
      // Fallback to black
      return Colors.black;
    } catch (_) {
      return Colors.black;
    }
  }

  @override
  bool shouldRepaint(covariant DrawingCanvasPainter oldDelegate) {
    return strokes.length != oldDelegate.strokes.length || strokes != oldDelegate.strokes;
  }
}

/// Interactive drawing canvas widget
class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    required this.onStrokeDrawn,
    required this.isEnabled,
    required this.color,
    required this.width,
    required this.style,
    this.strokes = const <DrawSegmentStroke>[],
    super.key,
  });

  final List<DrawSegmentStroke> strokes;
  final Function(DrawSegmentStroke) onStrokeDrawn;
  final bool isEnabled;
  final String color; // Hex color or 'eraser'
  final double width;
  final DrawStrokeStyle style;

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  NormalizedPoint? _lastPoint;

  void _handlePanStart(DragStartDetails details, Size canvasSize) {
    if (!widget.isEnabled) {
      return;
    }

    _lastPoint = NormalizedPoint.fromOffset(details.localPosition, canvasSize);
  }

  void _handlePanUpdate(DragUpdateDetails details, Size canvasSize) {
    if (!widget.isEnabled || _lastPoint == null) {
      return;
    }

    final NormalizedPoint nextPoint =
        NormalizedPoint.fromOffset(details.localPosition, canvasSize);

    final DrawSegmentStroke stroke = DrawSegmentStroke(
      from: _lastPoint!,
      to: nextPoint,
      color: widget.color,
      width: widget.color == 'eraser' ? eraserWidth : widget.width,
      style: widget.style,
    );

    widget.onStrokeDrawn(stroke);

    _lastPoint = nextPoint;
  }

  void _handlePanEnd(DragEndDetails details) {
    _lastPoint = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onPanStart: (DragStartDetails details) => _handlePanStart(details, canvasSize),
          onPanUpdate: (DragUpdateDetails details) => _handlePanUpdate(details, canvasSize),
          onPanEnd: _handlePanEnd,
          child: CustomPaint(
            size: canvasSize,
            painter: DrawingCanvasPainter(strokes: widget.strokes),
          ),
        );
      },
    );
  }
}
