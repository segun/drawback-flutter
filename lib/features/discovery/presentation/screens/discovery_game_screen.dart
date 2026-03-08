import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../drawing/models/drawing_models.dart';
import '../../../drawing/widgets/drawing_canvas.dart';
import '../discovery_controller.dart';

enum _DiscoveryGameState { instructions, drawing }

/// Discovery game screen with instructions and drawing canvas
class DiscoveryGameScreen extends StatefulWidget {
  const DiscoveryGameScreen({
    required this.controller,
    required this.onBackToChat,
    required this.onNavigateToSwipe,
    required this.onExitGame,
    super.key,
  });

  final DiscoveryController controller;
  final VoidCallback onBackToChat;
  final VoidCallback onNavigateToSwipe;
  final Future<void> Function() onExitGame;

  @override
  State<DiscoveryGameScreen> createState() => _DiscoveryGameScreenState();
}

class _DiscoveryGameScreenState extends State<DiscoveryGameScreen> {
  _DiscoveryGameState _currentState = _DiscoveryGameState.instructions;
  
  // Drawing state
  List<DrawSegmentStroke> _strokes = <DrawSegmentStroke>[];
  String _drawColor = '#be123c';
  DrawStrokeStyle _drawStyle = DrawStrokeStyle.normal;
  double _drawWidth = 2.0;
  
  // Tool sheet accordion states
  bool _strokeAccordionOpen = false;
  bool _colorAccordionOpen = false;
  bool _customColorAccordionOpen = false;

  static const List<String> _presetColors = <String>[
    '#e11d48',
    '#fb7185',
    '#f59e0b',
    '#10b981',
    '#0ea5e9',
  ];

  void _handleStrokeDrawn(DrawSegmentStroke stroke) {
    setState(() {
      _strokes.add(stroke);
    });
  }

  void _handleClearCanvas() {
    setState(() {
      _strokes.clear();
    });
  }

  String? _normalizeHexColor(String value) {
    final String normalized = value.trim().toLowerCase().replaceAll('#', '');
    final RegExp hexColorPattern = RegExp(r'^[0-9a-f]{6}$');
    if (!hexColorPattern.hasMatch(normalized)) {
      return null;
    }
    return '#$normalized';
  }

  Color _parseHexColor(String value) {
    final String? normalized = _normalizeHexColor(value);
    if (normalized == null) {
      return const Color(0xFFBE123C);
    }

    final String hex = normalized.substring(1);
    return Color(int.parse('FF$hex', radix: 16));
  }

  Future<String?> _showColorPaletteDialog() async {
    Color selectedColor = _parseHexColor(_drawColor);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: const Text(
            'Pick a color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFBE123C),
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: ColorPicker(
                  paletteType: PaletteType.hueWheel,
                  pickerColor: selectedColor,
                  onColorChanged: (Color color) {
                    setState(() {
                      selectedColor = color;
                    });
                  },
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFFBE123C)),
              ),
            ),
            FilledButton(
              onPressed: () {
                final String hex = '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase().padLeft(6, '0')}';
                Navigator.of(context).pop(hex.toLowerCase());
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1),
                ),
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
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            child: Row(
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBE123C),
                  ),
                ),
                const Spacer(),
                Icon(
                  isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 20,
                  color: const Color(0xFFBE123C),
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: child,
          ),
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildToolAccordionSection(
                        title: 'Stroke',
                        isOpen: _strokeAccordionOpen,
                        onToggle: () {
                          updateTools(() {
                            _strokeAccordionOpen = !_strokeAccordionOpen;
                          });
                        },
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
                                onChanged: (double value) {
                                  updateTools(() {
                                    _drawWidth = value.roundToDouble();
                                  });
                                },
                              ),
                            ),
                            Text(
                              _drawWidth.round().toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF9F1239),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildToolAccordionSection(
                        title: 'Color',
                        isOpen: _colorAccordionOpen,
                        onToggle: () {
                          updateTools(() {
                            _colorAccordionOpen = !_colorAccordionOpen;
                          });
                        },
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _presetColors.map((String color) {
                            final bool isSelected = _drawColor == color;
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                updateTools(() {
                                  _drawColor = color;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
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
                        onToggle: () {
                          updateTools(() {
                            _customColorAccordionOpen = !_customColorAccordionOpen;
                          });
                        },
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final String? selectedColor = await _showColorPaletteDialog();
                            if (!mounted || selectedColor == null) {
                              return;
                            }
                            updateTools(() {
                              _drawColor = selectedColor;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFDA4AF)),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.palette_outlined,
                                  size: 16,
                                  color: Color(0xFF9F1239),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Open color palette',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF9F1239),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _parseHexColor(_drawColor),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFDA4AF),
                                      width: 1.5,
                                    ),
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

  Future<void> _handleStartDiscoveryGame() async {
    if (_strokes.isEmpty) {
      return;
    }

    // Enter discovery game with drawing
    final bool success = await widget.controller.enterDiscoveryGameWithDrawing(_strokes);
    
    if (!success || !mounted) {
      return;
    }

    // Show success dialog
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success!'),
          content: const Text(
            'You are now in the discovery game. Start swiping to discover other users!',
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              child: const Text('Start Swiping'),
            ),
          ],
        );
      },
    );

    // Navigate to swipe screen
    if (mounted) {
      widget.onNavigateToSwipe();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, _) {
        switch (_currentState) {
          case _DiscoveryGameState.instructions:
            return _buildInstructionsView();
          case _DiscoveryGameState.drawing:
            return _buildDrawingView();
        }
      },
    );
  }

  Widget _buildInstructionsView() {
    return Container(
      color: const Color(0xFFFDA4AF),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Play the Discovery Game',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF9F1239),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),

              _buildStepCard(
                stepNumber: 1,
                title: 'Draw something that deeply represents you',
                description: 'Other people will see this drawing',
              ),
              const SizedBox(height: 16),

              _buildStepCard(
                stepNumber: 2,
                title: 'Press the "Start Discovery Game" button',
                description: 'This will submit your drawing to the game',
              ),
              const SizedBox(height: 16),

              _buildStepCard(
                stepNumber: 3,
                title: 'Start swiping',
                description: 'Discover other users through their drawings',
              ),
              const SizedBox(height: 40),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: widget.onBackToChat,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9F1239),
                      side: const BorderSide(color: Color(0xFF9F1239), width: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _currentState = _DiscoveryGameState.drawing;
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    child: const Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        border: Border.all(color: const Color(0xFFE11D48), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFE11D48),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9F1239),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9F1239),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingView() {
    final bool canStartGame = _strokes.isNotEmpty && !widget.controller.isBusy;

    return Container(
      color: const Color(0xFFFDA4AF),
      child: Column(
        children: <Widget>[
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF9F1239)),
                  onPressed: () {
                    setState(() {
                      _currentState = _DiscoveryGameState.instructions;
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Your Drawing',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9F1239),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.handyman_outlined, color: Color(0xFF9F1239)),
                  onPressed: _showToolsSheet,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFF9F1239)),
                  onPressed: _handleClearCanvas,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF9F1239)),
                  onPressed: widget.onBackToChat,
                ),
              ],
            ),
          ),

          // Canvas
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF9F1239), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: DrawingCanvas(
                  strokes: _strokes,
                  onStrokeDrawn: _handleStrokeDrawn,
                  isEnabled: !widget.controller.isBusy,
                  color: _drawColor,
                  width: _drawWidth,
                  style: _drawStyle,
                ),
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                OutlinedButton(
                  onPressed: widget.controller.isBusy ? null : widget.onBackToChat,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9F1239),
                    side: const BorderSide(color: Color(0xFF9F1239), width: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: canStartGame ? _handleStartDiscoveryGame : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    disabledBackgroundColor: const Color(0xFFFDA4AF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  child: widget.controller.isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Start Game',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
