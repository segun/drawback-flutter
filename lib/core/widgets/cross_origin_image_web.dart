// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Web implementation that creates an HTML img element with referrerPolicy="no-referrer"
Widget buildWebImage({
  required String imageUrl,
  BoxFit fit = BoxFit.contain,
  double? width,
  double? height,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  return _CrossOriginImageWeb(
    imageUrl: imageUrl,
    fit: fit,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );
}

class _CrossOriginImageWeb extends StatefulWidget {
  const _CrossOriginImageWeb({
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.errorBuilder,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  @override
  State<_CrossOriginImageWeb> createState() => _CrossOriginImageWebState();
}

class _CrossOriginImageWebState extends State<_CrossOriginImageWeb> {
  late String _viewType;
  bool _hasError = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'cross-origin-image-${widget.imageUrl.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
    _registerViewFactory();
  }

  @override
  void didUpdateWidget(_CrossOriginImageWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _viewType = 'cross-origin-image-${widget.imageUrl.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
      _hasError = false;
      _isLoaded = false;
      _registerViewFactory();
    }
  }

  void _registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final html.ImageElement img = html.ImageElement()
          ..src = widget.imageUrl
          ..referrerPolicy = 'no-referrer'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = _boxFitToCss(widget.fit);

        img.onLoad.listen((_) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        });

        img.onError.listen((_) {
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        });

        return img;
      },
    );
  }

  String _boxFitToCss(BoxFit fit) {
    switch (fit) {
      case BoxFit.contain:
        return 'contain';
      case BoxFit.cover:
        return 'cover';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.fitWidth:
        return 'contain';
      case BoxFit.fitHeight:
        return 'contain';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && widget.errorBuilder != null) {
      return widget.errorBuilder!(
        context,
        Exception('Failed to load image: ${widget.imageUrl}'),
        null,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: <Widget>[
          // Loading indicator
          if (!_isLoaded && !_hasError)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE11D48)),
              ),
            ),
          // The HTML image element
          HtmlElementView(viewType: _viewType),
        ],
      ),
    );
  }
}
