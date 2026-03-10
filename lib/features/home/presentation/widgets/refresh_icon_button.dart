import 'package:flutter/material.dart';

/// Refresh icon button that spins while an async refresh is in flight.
class RefreshIconButton extends StatefulWidget {
  const RefreshIconButton({
    required this.onRefresh,
    required this.tooltip,
    this.color = const Color(0xFF9F1239),
    this.size = 20,
    super.key,
  });

  final Future<void> Function() onRefresh;
  final String tooltip;
  final Color color;
  final double size;

  @override
  State<RefreshIconButton> createState() => _RefreshIconButtonState();
}

class _RefreshIconButtonState extends State<RefreshIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });
    _rotationController.repeat();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _rotationController.stop();
        _rotationController.reset();
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: RotationTransition(
        turns: _rotationController,
        child: Icon(Icons.refresh, size: widget.size),
      ),
      onPressed: _handleRefresh,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
      color: widget.color,
      tooltip: widget.tooltip,
    );
  }
}