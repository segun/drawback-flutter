import 'package:flutter/material.dart';

class AuthTopBar extends StatelessWidget {
  const AuthTopBar({
    super.key,
    this.leftChildren = const <Widget>[],
    this.centerChildren = const <Widget>[],
    this.rightChildren = const <Widget>[],
    this.padding = EdgeInsets.zero,
    this.slotSpacing = 8,
  });

  final List<Widget> leftChildren;
  final List<Widget> centerChildren;
  final List<Widget> rightChildren;
  final EdgeInsetsGeometry padding;
  final double slotSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildChildren(leftChildren),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: _buildChildren(centerChildren),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildChildren(rightChildren),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildren(List<Widget> children) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    if (children.length == 1) {
      return children.first;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _withSpacing(children),
    );
  }

  List<Widget> _withSpacing(List<Widget> children) {
    final List<Widget> result = <Widget>[];

    for (int index = 0; index < children.length; index++) {
      if (index > 0) {
        result.add(SizedBox(width: slotSpacing));
      }
      result.add(children[index]);
    }

    return result;
  }
}