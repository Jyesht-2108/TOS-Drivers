// Slide to confirm button widget

import 'package:flutter/material.dart';

class SlideButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onSlideComplete;
  final bool isLoading;

  const SlideButton({
    super.key,
    required this.text,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onSlideComplete,
    this.isLoading = false,
  });

  @override
  State<SlideButton> createState() => _SlideButtonState();
}

class _SlideButtonState extends State<SlideButton> with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  bool _isDragging = false;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  static const double _buttonHeight = 60.0;
  static const double _sliderSize = 52.0;
  static const double _threshold = 0.8; // 80% slide to complete

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resetAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() {
          _dragPosition = _resetAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (widget.isLoading) return;
    
    setState(() {
      _isDragging = true;
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double maxDrag) {
    if (widget.isLoading) return;

    final progress = _dragPosition / maxDrag;
    
    if (progress >= _threshold) {
      // Slide completed
      setState(() {
        _dragPosition = maxDrag;
      });
      widget.onSlideComplete();
    } else {
      // Reset to start
      _resetAnimation = Tween<double>(
        begin: _dragPosition,
        end: 0,
      ).animate(
        CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
      );
      _resetController.forward(from: 0);
    }
    
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _sliderSize - 8;
        final progress = maxDrag > 0 ? _dragPosition / maxDrag : 0.0;

        return Container(
          height: _buttonHeight,
          decoration: BoxDecoration(
            color: widget.backgroundColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(_buttonHeight / 2),
            border: Border.all(
              color: widget.backgroundColor,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Progress background
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_buttonHeight / 2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.backgroundColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Text
              Center(
                child: AnimatedOpacity(
                  opacity: widget.isLoading ? 0.5 : (1.0 - progress * 0.5),
                  duration: const Duration(milliseconds: 100),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.backgroundColor,
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.arrow_forward,
                          color: widget.backgroundColor,
                          size: 20,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: widget.backgroundColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Slider
              Positioned(
                left: _dragPosition + 4,
                top: 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _onHorizontalDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: (details) =>
                      _onHorizontalDragEnd(details, maxDrag),
                  child: Container(
                    width: _sliderSize,
                    height: _sliderSize,
                    decoration: BoxDecoration(
                      color: widget.isLoading 
                          ? Colors.grey 
                          : widget.backgroundColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.foregroundColor,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
