import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ignore: avoid_web_libraries_in_flutter
import 'cross_origin_image_stub.dart'
    if (dart.library.html) 'cross_origin_image_web.dart' as platform;

/// A cross-platform image widget that handles CORS issues on web
/// by setting referrerPolicy="no-referrer" for HTML img elements.
class CrossOriginImage extends StatelessWidget {
  const CrossOriginImage({
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.errorBuilder,
    super.key,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return platform.buildWebImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    }

    // For mobile/desktop, use standard Image.network
    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }
}
