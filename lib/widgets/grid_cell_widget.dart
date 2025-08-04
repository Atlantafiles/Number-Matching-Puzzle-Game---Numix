import 'package:flutter/material.dart';
import '../models/cells.dart';

class GridCellWidget extends StatefulWidget {
  final Cell cell;
  final VoidCallback onTap;
  final bool isAnimating;
  final bool showShakeAnimation;

  const GridCellWidget({
    super.key,
    required this.cell,
    required this.onTap,
    this.isAnimating = false,
    this.showShakeAnimation = false,
  });

  @override
  State<GridCellWidget> createState() => _GridCellWidgetState();
}

class _GridCellWidgetState extends State<GridCellWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _shakeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  @override
  void didUpdateWidget(GridCellWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.cell.isSelected && !oldWidget.cell.isSelected) {
      _scaleController.forward();
    } else if (!widget.cell.isSelected && oldWidget.cell.isSelected) {
      _scaleController.reverse();
    }

    if (widget.showShakeAnimation && !oldWidget.showShakeAnimation) {
      _shakeController.forward().then((_) {
        _shakeController.reset();
      });
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Color _getCellColor() {
    if (widget.cell.isMatched) {
      return Colors.grey[300]!;
    }

    // Color mapping based on value (similar to 2048 style)
    switch (widget.cell.value) {
      case 1:
        return const Color(0xFFFF6B6B); // Light red/pink
      case 2:
        return const Color(0xFFFF8E53); // Orange-red
      case 3:
        return const Color(0xFF686DE0); // Light Purple
      case 4:
        return const Color(0xFFFF9F43); // Orange
      case 5:
        return const Color(0xFFFECA57); // Yellow-orange
      case 6:
        return const Color(0xFF48CAE4); // Light blue
      case 7:
        return const Color(0xFF2D3436); // Dark gray
      case 8:
        return const Color(0xFFFFD93D); // Yellow
      case 9:
        return const Color(0xFF6BCF7F); // Light green
      default:
        return _getGradientColor(widget.cell.value);
    }
  }

  Color _getGradientColor(int value) {
    // Generate colors based on value for numbers > 15
    final hue = (value * 137.508) % 360; // Golden angle for good distribution
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.9).toColor();
  }

  Color _getTextColor() {
    if (widget.cell.isMatched) {
      return Colors.grey[600]!;
    }

    // White text for darker colors, dark text for lighter colors
    final color = _getCellColor();
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _shakeAnimation]),
      builder: (context, child) {
        double shakeOffset = 0.0;
        if (widget.showShakeAnimation) {
          shakeOffset = _shakeAnimation.value * 10 *
              (widget.showShakeAnimation ? 1 : 0) *
              (0.5 - (widget.cell.row + widget.cell.col) % 2).sign;
        }

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.isAnimating ? null : widget.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: _getCellColor(),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: widget.cell.isSelected
                      ? [
                    BoxShadow(
                      color: _getCellColor().withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                      : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: _getFontSize(),
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(),
                    ),
                    child: Text(
                      widget.cell.value.toString(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _getFontSize() {
    // Adjust font size based on number of digits
    if (widget.cell.value >= 1000) return 16;
    if (widget.cell.value >= 100) return 18;
    if (widget.cell.value >= 10) return 22;
    return 24;
  }
}