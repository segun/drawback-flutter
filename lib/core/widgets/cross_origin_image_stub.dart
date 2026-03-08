import 'package:flutter/material.dart';

/// Stub implementation for non-web platforms.
/// This should never be called since we check kIsWeb first.
Widget buildWebImage({
  required String imageUrl,
  BoxFit fit = BoxFit.contain,
  double? width,
  double? height,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  // Fallback to standard Image.network on non-web platforms
  return Image.network(
    imageUrl,
    fit: fit,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );
}
