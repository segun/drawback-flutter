import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../../core/network/api_exception.dart';
import '../../drawing/models/drawing_models.dart';
import '../../drawing/widgets/drawing_canvas.dart';
import '../../home/data/social_api.dart';
import '../../home/domain/home_models.dart';

/// State controller for discovery game functionality
class DiscoveryController extends ChangeNotifier {
  DiscoveryController({
    required SocialApi socialApi,
    required this.onProfileUpdate,
  }) : _socialApi = socialApi;

  final SocialApi _socialApi;
  final void Function(UserProfile profile) onProfileUpdate;

  bool _isInDiscoveryGame = false;
  bool _isBusy = false;
  bool _lastDiscoveryFetchAccessDenied = false;
  String? _error;
  String? _notice;

  // Getters
  bool get isInDiscoveryGame => _isInDiscoveryGame;
  bool get isBusy => _isBusy;
  bool get lastDiscoveryFetchAccessDenied => _lastDiscoveryFetchAccessDenied;
  String? get error => _error;
  String? get notice => _notice;

  /// Initialize discovery game status from user profile
  void setInitialStatus(bool isInGame) {
    _isInDiscoveryGame = isInGame;
    notifyListeners();
  }

  /// Enter the discovery game
  Future<bool> enterDiscoveryGame() async {
    return _runGuarded<bool>(() async {
      final UserProfile profile = await _socialApi.updateDiscoveryGameStatus(
        appearInDiscoveryGame: true,
      );
      _isInDiscoveryGame = true;
      _notice = 'You are now in the discovery game!';
      onProfileUpdate(profile);
      return true;
    }, fallback: false);
  }

  /// Enter the discovery game with a drawing
  Future<bool> enterDiscoveryGameWithDrawing(List<DrawSegmentStroke> strokes) async {
    if (strokes.isEmpty) {
      _error = 'No drawing to save';
      notifyListeners();
      return false;
    }

    return _runGuarded<bool>(() async {
      // Convert strokes to base64 PNG image
      final String imageBase64 = await _strokesToBase64Image(strokes);
      
      // Submit to server with both status and image
      final UserProfile profile = await _socialApi.updateDiscoveryGameStatus(
        appearInDiscoveryGame: true,
        base64Image: imageBase64,
      );
      
      _isInDiscoveryGame = true;
      _notice = 'You are now in the discovery game!';
      onProfileUpdate(profile);
      return true;
    }, fallback: false);
  }

  /// Exit the discovery game
  Future<bool> exitDiscoveryGame() async {
    return _runGuarded<bool>(() async {
      final UserProfile profile = await _socialApi.updateDiscoveryGameStatus(
        appearInDiscoveryGame: false,
      );
      _isInDiscoveryGame = false;
      _notice = 'You have left the discovery game.';
      onProfileUpdate(profile);
      return true;
    }, fallback: false);
  }

  /// Get a random discovery user
  Future<DiscoveryUser?> getRandomDiscoveryUser() async {
    try {
      _isBusy = true;
      _error = null;
      _notice = null;
      _lastDiscoveryFetchAccessDenied = false;
      notifyListeners();

      final DiscoveryUser? user = await _socialApi.getRandomDiscoveryUser();
      return user;
    } on ApiException catch (e) {
      _error = e.message;
      _lastDiscoveryFetchAccessDenied = e.statusCode == 403;
      return null;
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      _lastDiscoveryFetchAccessDenied = false;
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Convert strokes to base64-encoded PNG image
  Future<String> _strokesToBase64Image(List<DrawSegmentStroke> strokes) async {
    // Create a fixed-size canvas (800x800)
    const double canvasWidth = 800.0;
    const double canvasHeight = 800.0;
    final ui.Size canvasSize = ui.Size(canvasWidth, canvasHeight);

    // Create picture recorder
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Fill background with white
    final Paint backgroundPaint = Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      backgroundPaint,
    );

    // Draw strokes using the existing painter
    final DrawingCanvasPainter painter = DrawingCanvasPainter(strokes: strokes);
    painter.paint(canvas, canvasSize);

    // Convert to image
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(
      canvasWidth.toInt(),
      canvasHeight.toInt(),
    );

    // Convert to PNG bytes
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw Exception('Failed to convert image to bytes');
    }

    // Convert to base64
    final Uint8List pngBytes = byteData.buffer.asUint8List();
    final String base64String = base64Encode(pngBytes);

    return base64String;
  }

  /// Clear messages
  void clearMessages() {
    _error = null;
    _notice = null;
    notifyListeners();
  }

  /// Helper to run guarded async operations
  Future<T> _runGuarded<T>(
    Future<T> Function() operation, {
    required T fallback,
  }) async {
    try {
      _isBusy = true;
      _error = null;
      _notice = null;
      notifyListeners();

      final T result = await operation();
      return result;
    } on ApiException catch (e) {
      _error = e.message;
      return fallback;
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      return fallback;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
