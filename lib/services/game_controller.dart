import 'dart:async';
import 'dart:math';
import '../models/cells.dart';
import '../models/level.dart';
import '../models/game_state.dart';

class GameController {
  Timer? _gameTimer;

  // Matching logic - now requires path connectivity
  static bool canMatch(int value1, int value2) {
    return value1 == value2 || value1 + value2 == 10;
  }

  // Check if two cells can be matched (with path validation)
  static bool canCellsMatch(Cell cell1, Cell cell2, List<List<Cell>> grid) {
    // Can't match with itself or already matched cells
    if (cell1 == cell2 || cell1.isMatched || cell2.isMatched) {
      return false;
    }

    // Check if values can match
    if (!canMatch(cell1.value, cell2.value)) {
      return false;
    }

    // Check if there's a valid path between the cells
    return hasValidPath(cell1, cell2, grid);
  }

  // Check if there's a valid path between two cells
  static bool hasValidPath(Cell cell1, Cell cell2, List<List<Cell>> grid) {
    // Try to find a path with at most 2 turns (L-shaped or straight line)
    return _findPathWithMaxTurns(cell1, cell2, grid, 2);
  }

  // Find path between cells with maximum number of turns allowed
  static bool _findPathWithMaxTurns(Cell start, Cell end, List<List<Cell>> grid, int maxTurns) {
    if (start == end) return false;

    // Try direct paths first (0 turns)
    if (hasDirectPath(start, end, grid)) {
      return true;
    }

    if (maxTurns <= 0) return false;

    // Try paths with one turn (L-shaped)
    if (maxTurns >= 1 && hasLShapedPath(start, end, grid)) {
      return true;
    }

    // Try paths with two turns (U-shaped)
    if (maxTurns >= 2 && _hasUShapedPath(start, end, grid)) {
      return true;
    }

    return false;
  }

  // Check for direct horizontal or vertical path - PUBLIC VERSION
  static bool hasDirectPath(Cell start, Cell end, List<List<Cell>> grid) {
    // Same row (horizontal path)
    if (start.row == end.row) {
      return _isHorizontalPathClear(start, end, grid);
    }

    // Same column (vertical path)
    if (start.col == end.col) {
      return _isVerticalPathClear(start, end, grid);
    }

    return false;
  }

  // Check for L-shaped path (1 turn) - PUBLIC VERSION
  static bool hasLShapedPath(Cell start, Cell end, List<List<Cell>> grid) {
    // Try corner at (start.row, end.col)
    final corner1 = Cell(value: 0, row: start.row, col: end.col);
    if (_isValidCorner(corner1, grid) &&
        _isHorizontalPathClear(start, corner1, grid) &&
        _isVerticalPathClear(corner1, end, grid)) {
      return true;
    }

    // Try corner at (end.row, start.col)
    final corner2 = Cell(value: 0, row: end.row, col: start.col);
    if (_isValidCorner(corner2, grid) &&
        _isVerticalPathClear(start, corner2, grid) &&
        _isHorizontalPathClear(corner2, end, grid)) {
      return true;
    }

    return false;
  }

  // Check if horizontal path is clear
  static bool _isHorizontalPathClear(Cell start, Cell end, List<List<Cell>> grid) {
    final row = start.row;
    final minCol = min(start.col, end.col);
    final maxCol = max(start.col, end.col);

    // Check all cells between start and end
    for (int col = minCol + 1; col < maxCol; col++) {
      if (!grid[row][col].isMatched) {
        return false; // Path blocked by unmatched cell
      }
    }
    return true;
  }

  // Check if vertical path is clear
  static bool _isVerticalPathClear(Cell start, Cell end, List<List<Cell>> grid) {
    final col = start.col;
    final minRow = min(start.row, end.row);
    final maxRow = max(start.row, end.row);

    // Check all cells between start and end
    for (int row = minRow + 1; row < maxRow; row++) {
      if (!grid[row][col].isMatched) {
        return false; // Path blocked by unmatched cell
      }
    }
    return true;
  }

  // Check for U-shaped path (2 turns)
  static bool _hasUShapedPath(Cell start, Cell end, List<List<Cell>> grid) {
    final gridSize = grid.length;

    // Try extending horizontally from start, then vertically, then horizontally to end
    for (int extendCol = 0; extendCol < gridSize; extendCol++) {
      if (extendCol == start.col && extendCol == end.col) continue;

      final corner1 = Cell(value: 0, row: start.row, col: extendCol);
      final corner2 = Cell(value: 0, row: end.row, col: extendCol);

      if (_isValidCorner(corner1, grid) && _isValidCorner(corner2, grid) &&
          _isHorizontalPathClear(start, corner1, grid) &&
          _isVerticalPathClear(corner1, corner2, grid) &&
          _isHorizontalPathClear(corner2, end, grid)) {
        return true;
      }
    }

    // Try extending vertically from start, then horizontally, then vertically to end
    for (int extendRow = 0; extendRow < gridSize; extendRow++) {
      if (extendRow == start.row && extendRow == end.row) continue;

      final corner1 = Cell(value: 0, row: extendRow, col: start.col);
      final corner2 = Cell(value: 0, row: extendRow, col: end.col);

      if (_isValidCorner(corner1, grid) && _isValidCorner(corner2, grid) &&
          _isVerticalPathClear(start, corner1, grid) &&
          _isHorizontalPathClear(corner1, corner2, grid) &&
          _isVerticalPathClear(corner2, end, grid)) {
        return true;
      }
    }

    return false;
  }

  // Check if a corner position is valid (matched cell or boundary)
  static bool _isValidCorner(Cell corner, List<List<Cell>> grid) {
    // Corner can be outside grid boundaries (conceptually)
    if (corner.row < 0 || corner.row >= grid.length ||
        corner.col < 0 || corner.col >= grid[0].length) {
      return true; // Boundary is always passable
    }

    // Corner must be a matched cell to be passable
    return grid[corner.row][corner.col].isMatched;
  }

  // Start the game timer
  void startTimer(GameState gameState) {
    stopTimer(); // Stop any existing timer

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (gameState.status == GameStatus.playing) {
        gameState.decrementTime();

        // Check if time is up
        if (gameState.timeRemaining <= 0) {
          stopTimer();
        }
      }
    });
  }

  // Stop the game timer
  void stopTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  // Pause the timer
  void pauseTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  // Resume the timer
  void resumeTimer(GameState gameState) {
    if (gameState.status == GameStatus.playing) {
      startTimer(gameState);
    }
  }

  // Get all possible matches on the current grid (with path validation)
  static List<MatchPair> getAllPossibleMatches(List<List<Cell>> grid) {
    List<MatchPair> matches = [];

    for (int i = 0; i < grid.length; i++) {
      for (int j = 0; j < grid[i].length; j++) {
        if (grid[i][j].isMatched) continue;

        for (int x = i; x < grid.length; x++) {
          int startY = (x == i) ? j + 1 : 0;
          for (int y = startY; y < grid[x].length; y++) {
            if (grid[x][y].isMatched) continue;

            // Check both value match and path connectivity
            if (canCellsMatch(grid[i][j], grid[x][y], grid)) {
              matches.add(MatchPair(grid[i][j], grid[x][y]));
            }
          }
        }
      }
    }

    return matches;
  }

  // Get hint for next possible match
  static MatchPair? getHint(List<List<Cell>> grid) {
    final matches = getAllPossibleMatches(grid);
    if (matches.isEmpty) return null;

    // Return a random match from available matches
    final random = Random();
    return matches[random.nextInt(matches.length)];
  }

  // Check if the level is solvable (has enough matches)
  static bool isLevelSolvable(List<List<Cell>> grid, int targetMatches) {
    return getAllPossibleMatches(grid).length >= targetMatches;
  }

  // Generate a balanced grid for a specific level (with numbers 1-9 only)
  static List<List<Cell>> generateBalancedGrid(Level level) {
    List<List<Cell>> grid;
    int attempts = 0;
    const maxAttempts = 100;

    do {
      grid = _generateRandomGrid(level);
      attempts++;
    } while (!isLevelSolvable(grid, level.targetMatches) && attempts < maxAttempts);

    if (attempts >= maxAttempts) {
      // Fallback: ensure we have at least the target matches
      grid = _generateGuaranteedSolvableGrid(level);
    }

    return grid;
  }

  static List<List<Cell>> _generateRandomGrid(Level level) {
    final random = Random();
    // Limit numbers to 1-9 only
    final limitedNumbers = level.availableNumbers.where((num) => num >= 1 && num <= 9).toList();
    if (limitedNumbers.isEmpty) {
      limitedNumbers.addAll([1, 2, 3, 4, 5, 6, 7, 8, 9]);
    }

    return List.generate(
      level.gridSize,
          (row) => List.generate(
        level.gridSize,
            (col) {
          final value = limitedNumbers[random.nextInt(limitedNumbers.length)];
          return Cell(value: value, row: row, col: col);
        },
      ),
    );
  }

  static List<List<Cell>> _generateGuaranteedSolvableGrid(Level level) {
    final grid = List.generate(
      level.gridSize,
          (row) => List.generate(
        level.gridSize,
            (col) => Cell(value: 1, row: row, col: col),
      ),
    );

    final random = Random();
    final matchesNeeded = level.targetMatches;

    // Limit numbers to 1-9 only
    final limitedNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    // Place guaranteed matches in adjacent positions
    int matchesPlaced = 0;
    List<List<int>> positions = [];

    // Create list of all positions
    for (int i = 0; i < level.gridSize; i++) {
      for (int j = 0; j < level.gridSize; j++) {
        positions.add([i, j]);
      }
    }
    positions.shuffle(random);

    // Place matches in adjacent pairs
    for (int i = 0; i < positions.length - 1 && matchesPlaced < matchesNeeded; i += 2) {
      final pos1 = positions[i];
      final pos2 = positions[i + 1];

      // Generate a matching pair
      final value = limitedNumbers[random.nextInt(limitedNumbers.length)];

      if (random.nextBool()) {
        // Equal match
        grid[pos1[0]][pos1[1]] = Cell(value: value, row: pos1[0], col: pos1[1]);
        grid[pos2[0]][pos2[1]] = Cell(value: value, row: pos2[0], col: pos2[1]);
      } else {
        // Sum to 10 match
        final complement = 10 - value;
        if (complement > 0 && complement <= 9) {
          grid[pos1[0]][pos1[1]] = Cell(value: value, row: pos1[0], col: pos1[1]);
          grid[pos2[0]][pos2[1]] = Cell(value: complement, row: pos2[0], col: pos2[1]);
        } else {
          // Fallback to equal match
          grid[pos1[0]][pos1[1]] = Cell(value: value, row: pos1[0], col: pos1[1]);
          grid[pos2[0]][pos2[1]] = Cell(value: value, row: pos2[0], col: pos2[1]);
        }
      }

      matchesPlaced++;
    }

    // Fill remaining cells with random values (1-9)
    for (int i = 0; i < level.gridSize; i++) {
      for (int j = 0; j < level.gridSize; j++) {
        if (grid[i][j].value == 1 && matchesPlaced * 2 <= i * level.gridSize + j) {
          final value = limitedNumbers[random.nextInt(limitedNumbers.length)];
          grid[i][j] = Cell(value: value, row: i, col: j);
        }
      }
    }

    return grid;
  }

  // Calculate difficulty score for a grid
  static double calculateDifficulty(List<List<Cell>> grid) {
    final matches = getAllPossibleMatches(grid);
    final totalCells = grid.length * grid[0].length;
    final availableCells = totalCells - grid.expand((row) => row).where((cell) => cell.isMatched).length;

    if (availableCells <= 1) return 0.0;

    // More matches = easier, fewer matches = harder
    final matchRatio = matches.length / (availableCells * (availableCells - 1) / 2);
    return 1.0 - matchRatio; // Invert so higher score = more difficult
  }

  // Get the path between two cells for visualization
  static List<Cell>? getPath(Cell start, Cell end, List<List<Cell>> grid) {
    if (!hasValidPath(start, end, grid)) return null;

    // Try direct path first
    if (hasDirectPath(start, end, grid)) {
      return _getDirectPath(start, end);
    }

    // Try L-shaped path
    final lPath = _getLShapedPath(start, end, grid);
    if (lPath != null) return lPath;

    // Try U-shaped path
    final uPath = _getUShapedPath(start, end, grid);
    if (uPath != null) return uPath;

    return null;
  }

  static List<Cell> _getDirectPath(Cell start, Cell end) {
    List<Cell> path = [start];

    if (start.row == end.row) {
      // Horizontal path
      final step = start.col < end.col ? 1 : -1;

      for (int col = start.col + step; col != end.col; col += step) {
        path.add(Cell(value: 0, row: start.row, col: col));
      }
    } else {
      // Vertical path
      final step = start.row < end.row ? 1 : -1;

      for (int row = start.row + step; row != end.row; row += step) {
        path.add(Cell(value: 0, row: row, col: start.col));
      }
    }

    path.add(end);
    return path;
  }

  static List<Cell>? _getLShapedPath(Cell start, Cell end, List<List<Cell>> grid) {
    // Try corner at (start.row, end.col)
    final corner1 = Cell(value: 0, row: start.row, col: end.col);
    if (_isValidCorner(corner1, grid) &&
        _isHorizontalPathClear(start, corner1, grid) &&
        _isVerticalPathClear(corner1, end, grid)) {
      List<Cell> path = [start];

      // Add horizontal segment
      final hStep = start.col < end.col ? 1 : -1;
      for (int col = start.col + hStep; col != end.col; col += hStep) {
        path.add(Cell(value: 0, row: start.row, col: col));
      }

      // Add corner if not start or end position
      if (corner1.row != start.row || corner1.col != start.col) {
        path.add(corner1);
      }

      // Add vertical segment
      final vStep = start.row < end.row ? 1 : -1;
      for (int row = start.row + vStep; row != end.row; row += vStep) {
        path.add(Cell(value: 0, row: row, col: end.col));
      }

      path.add(end);
      return path;
    }

    // Try corner at (end.row, start.col)
    final corner2 = Cell(value: 0, row: end.row, col: start.col);
    if (_isValidCorner(corner2, grid) &&
        _isVerticalPathClear(start, corner2, grid) &&
        _isHorizontalPathClear(corner2, end, grid)) {
      List<Cell> path = [start];

      // Add vertical segment
      final vStep = start.row < end.row ? 1 : -1;
      for (int row = start.row + vStep; row != end.row; row += vStep) {
        path.add(Cell(value: 0, row: row, col: start.col));
      }

      // Add corner if not start or end position
      if (corner2.row != start.row || corner2.col != start.col) {
        path.add(corner2);
      }

      // Add horizontal segment
      final hStep = start.col < end.col ? 1 : -1;
      for (int col = start.col + hStep; col != end.col; col += hStep) {
        path.add(Cell(value: 0, row: end.row, col: col));
      }

      path.add(end);
      return path;
    }

    return null;
  }

  static List<Cell>? _getUShapedPath(Cell start, Cell end, List<List<Cell>> grid) {
    final gridSize = grid.length;

    // Try extending horizontally first
    for (int extendCol = 0; extendCol < gridSize; extendCol++) {
      if (extendCol == start.col && extendCol == end.col) continue;

      final corner1 = Cell(value: 0, row: start.row, col: extendCol);
      final corner2 = Cell(value: 0, row: end.row, col: extendCol);

      if (_isValidCorner(corner1, grid) && _isValidCorner(corner2, grid) &&
          _isHorizontalPathClear(start, corner1, grid) &&
          _isVerticalPathClear(corner1, corner2, grid) &&
          _isHorizontalPathClear(corner2, end, grid)) {

        List<Cell> path = [start];

        // Horizontal to first corner
        final h1Step = start.col < extendCol ? 1 : -1;
        for (int col = start.col + h1Step; col != extendCol; col += h1Step) {
          path.add(Cell(value: 0, row: start.row, col: col));
        }
        path.add(corner1);

        // Vertical between corners
        final vStep = start.row < end.row ? 1 : -1;
        for (int row = start.row + vStep; row != end.row; row += vStep) {
          path.add(Cell(value: 0, row: row, col: extendCol));
        }
        if (corner2.row != corner1.row || corner2.col != corner1.col) {
          path.add(corner2);
        }

        // Horizontal to end
        final h2Step = extendCol < end.col ? 1 : -1;
        for (int col = extendCol + h2Step; col != end.col; col += h2Step) {
          path.add(Cell(value: 0, row: end.row, col: col));
        }

        path.add(end);
        return path;
      }
    }

    return null;
  }

  // Cleanup resources
  void dispose() {
    stopTimer();
  }
}

// Helper class for match pairs
class MatchPair {
  final Cell cell1;
  final Cell cell2;

  MatchPair(this.cell1, this.cell2);

  @override
  String toString() {
    return 'MatchPair(${cell1.value} at (${cell1.row},${cell1.col}) + ${cell2.value} at (${cell2.row},${cell2.col}))';
  }
}