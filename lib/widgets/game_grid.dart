import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'grid_cell_widget.dart';

class GameGrid extends StatefulWidget {
  const GameGrid({
    super.key
  });

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid> with TickerProviderStateMixin {
  late AnimationController _gridAnimationController;
  late Animation<double> _gridAnimation;
  final Map<String, bool> _shakingCells = {};

  @override
  void initState() {
    super.initState();
    _gridAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _gridAnimation = CurvedAnimation(
      parent: _gridAnimationController,
      curve: Curves.easeInOut,
    );

    _gridAnimationController.forward();
  }

  @override
  void dispose() {
    _gridAnimationController.dispose();
    super.dispose();
  }

  void _handleCellTap(int row, int col, GameState gameState) {
    final result = gameState.selectCell(row, col);

    if (result == MatchResult.invalid) {
      // Trigger shake animation for invalid match
      setState(() {
        _shakingCells['$row-$col'] = true;
        if (gameState.selectedCell != null) {
          final selected = gameState.selectedCell!;
          _shakingCells['${selected.row}-${selected.col}'] = true;
        }
      });

      // Clear shake animation after delay
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _shakingCells.clear();
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return AnimatedBuilder(
          animation: _gridAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _gridAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gameState.gridSize,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: gameState.gridSize * gameState.gridSize,
                    itemBuilder: (context, index) {
                      final row = index ~/ gameState.gridSize;
                      final col = index % gameState.gridSize;
                      final cell = gameState.grid[row][col];
                      final cellKey = '$row-$col';

                      return GridCellWidget(
                        key: ValueKey('${cell.row}-${cell.col}-${cell.value}'),
                        cell: cell,
                        onTap: () => _handleCellTap(row, col, gameState),
                        isAnimating: gameState.isAnimating,
                        showShakeAnimation: _shakingCells[cellKey] ?? false,
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}