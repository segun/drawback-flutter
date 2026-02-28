import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    required this.child,
    this.maxWidth = 460,
    this.padding = const EdgeInsets.all(16),
    this.withScrollbar = false,
    this.scrollPhysics = const ClampingScrollPhysics(),
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final bool withScrollbar;
  final ScrollPhysics scrollPhysics;

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    // Wrap with scrollbar if needed
    if (withScrollbar) {
      content = Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          primary: true,
          physics: scrollPhysics,
          child: content,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCE7F3),
      extendBodyBehindAppBar: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFFFCE7F3),
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFFFCE7F3),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          child: content,
        ),
      ),
    );
  }
}
