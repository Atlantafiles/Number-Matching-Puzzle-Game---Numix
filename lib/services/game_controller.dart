import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import '../models/cells.dart';
import '../models/level.dart';
import '../models/game_state.dart';

class GameController {
  Timer? _gameTimer;

  // Cache for path finding results to avoid repeated calculations
  static final Map<String, bool> _pathCache = {};
  static final Map<String, List<Cell>?> _fullPathCache = {};

  // Clear cache when grid changes
  static void clearCache() {
    _pathCache.clear();
    _fullPathCache.clear();
  }

  // Matching logic - now requires path connectivity
  static bool canMatch(int value1, int value2) {
    return value1 == value2 || value1 + value2 == 10;
  }

  // Check if two cells can be matched (with path validation and caching)
  static bool canCellsMatch(Cell cell1, Cell cell2, List<List<Cell>> grid) {
    // Can't match with itself or already matched cells
    if (cell1 == cell2 || cell1.isMatched || cell2.isMatched) {
      return false;
    }

    // Check if values can match first (fastest check)
    if (!canMatch(cell1.value, cell2.value)) {
      return false;
    }

    // Use cache for path validation
    final cacheKey = '${cell1.row},${cell1.col}-${cell2.row},${cell2.col}';
    if (_pathCache.containsKey(cacheKey)) {
      return _pathCache[cacheKey]!;
    }

    // Check if there's a valid path between the cells
    final hasPath = hasValidPath(cell1, cell2, grid);
    _pathCache[cacheKey] = hasPath;
    return hasPath;
  }

  // Optimized path validation with early returns
  static bool hasValidPath(Cell cell1, Cell cell2, List<List<Cell>> grid) {
    if (cell1 == cell2) return false;

    // Try direct paths first (fastest)
    if (hasDirectPath(cell1, cell2, grid)) {
      return true;
    }

    // Try L-shaped paths (moderate cost)
    if (hasLShapedPath(cell1, cell2, grid)) {
      return true;
    }

    // Try U-shaped paths (most expensive)
    return _hasUShapedPath(cell1, cell2, grid);
  }

  // Optimized direct path check
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

  // Optimized L-shaped path check
  static bool hasLShapedPath(Cell start, Cell end, List<List<Cell>> grid) {
    // Quick boundary checks
    final gridSize = grid.length;

    // Try corner at (start.row, end.col)
    if (_isValidPosition(start.row, end.col, gridSize) &&
        _isValidCornerFast(start.row, end.col, grid) &&
        _isHorizontalPathClearFast(start.row, start.col, end.col, grid) &&
        _isVerticalPathClearFast(end.col, start.row, end.row, grid)) {
      return true;
    }

    // Try corner at (end.row, start.col)
    if (_isValidPosition(end.row, start.col, gridSize) &&
        _isValidCornerFast(end.row, start.col, grid) &&
        _isVerticalPathClearFast(start.col, start.row, end.row, grid) &&
        _isHorizontalPathClearFast(end.row, start.col, end.col, grid)) {
      return true;
    }

    return false;
  }

  // Fast position validation
  static bool _isValidPosition(int row, int col, int gridSize) {
    return row >= 0 && row < gridSize && col >= 0 && col < gridSize;
  }

  // Fast corner validation
  static bool _isValidCornerFast(int row, int col, List<List<Cell>> grid) {
    // Corner can be outside grid boundaries
    if (row < 0 || row >= grid.length || col < 0 || col >= grid[0].length) {
      return true;
    }
    return grid[row][col].isMatched;
  }

  // Optimized horizontal path checking
  static bool _isHorizontalPathClearFast(int row, int startCol, int endCol, List<List<Cell>> grid) {
    final minCol = math.min(startCol, endCol);
    final maxCol = math.max(startCol, endCol);

    // Early exit if invalid row
    if (row < 0 || row >= grid.length) return true;

    for (int col = minCol + 1; col < maxCol; col++) {
      if (col >= 0 && col < grid[row].length && !grid[row][col].isMatched) {
        return false;
      }
    }
    return true;
  }

  // Optimized vertical path checking
  static bool _isVerticalPathClearFast(int col, int startRow, int endRow, List<List<Cell>> grid) {
    final minRow = math.min(startRow, endRow);
    final maxRow = math.max(startRow, endRow);

    // Early exit if invalid column
    if (col < 0 || col >= grid[0].length) return true;

    for (int row = minRow + 1; row < maxRow; row++) {
      if (row >= 0 && row < grid.length && !grid[row][col].isMatched) {
        return false;
      }
    }
    return true;
  }

  // Legacy methods for compatibility
  static bool _isHorizontalPathClear(Cell start, Cell end, List<List<Cell>> grid) {
    return _isHorizontalPathClearFast(start.row, start.col, end.col, grid);
  }

  static bool _isVerticalPathClear(Cell start, Cell end, List<List<Cell>> grid) {
    return _isVerticalPathClearFast(start.col, start.row, end.row, grid);
  }

  static bool _isValidCorner(Cell corner, List<List<Cell>> grid) {
    return _isValidCornerFast(corner.row, corner.col, grid);
  }

  // Optimized U-shaped path check with early exits
  static bool _hasUShapedPath(Cell start, Cell end, List<List<Cell>> grid) {
    final gridSize = grid.length;

    // Try extending horizontally first (limit search space)
    final maxExtend = math.max(gridSize, 10); // Limit search to reasonable bounds
    for (int extendCol = 0; extendCol < maxExtend && extendCol < gridSize; extendCol++) {
      if (extendCol == start.col && extendCol == end.col) continue;

      if (_isValidCornerFast(start.row, extendCol, grid) &&
          _isValidCornerFast(end.row, extendCol, grid) &&
          _isHorizontalPathClearFast(start.row, start.col, extendCol, grid) &&
          _isVerticalPathClearFast(extendCol, start.row, end.row, grid) &&
          _isHorizontalPathClearFast(end.row, extendCol, end.col, grid)) {
        return true;
      }
    }

    // Try extending vertically (limit search space)
    for (int extendRow = 0; extendRow < maxExtend && extendRow < gridSize; extendRow++) {
      if (extendRow == start.row && extendRow == end.row) continue;

      if (_isValidCornerFast(extendRow, start.col, grid) &&
          _isValidCornerFast(extendRow, end.col, grid) &&
          _isVerticalPathClearFast(start.col, start.row, extendRow, grid) &&
          _isHorizontalPathClearFast(extendRow, start.col, end.col, grid) &&
          _isVerticalPathClearFast(end.col, extendRow, end.row, grid)) {
        return true;
      }
    }

    return false;
  }

  // Optimized match finding with early exits and batching
  static List<MatchPair> getAllPossibleMatches(List<List<Cell>> grid) {
    final matches = <MatchPair>[];
    final gridSize = grid.length;

    // Pre-collect unmatched cells for faster iteration
    final unmatchedCells = <Cell>[];
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (!grid[i][j].isMatched) {
          unmatchedCells.add(grid[i][j]);
        }
      }
    }

    // Check combinations of unmatched cells only
    for (int i = 0; i < unmatchedCells.length; i++) {
      final cell1 = unmatchedCells[i];
      for (int j = i + 1; j < unmatchedCells.length; j++) {
        final cell2 = unmatchedCells[j];

        // Quick value check first
        if (canMatch(cell1.value, cell2.value)) {
          // Then check path (this uses caching)
          if (hasValidPath(cell1, cell2, grid)) {
            matches.add(MatchPair(cell1, cell2));
          }
        }
      }
    }

    return matches;
  }

  // Optimized hint system
  static MatchPair? getHint(List<List<Cell>> grid) {
    // Try to find a match quickly without generating all matches
    final gridSize = grid.length;
    final random = Random();

    // Collect unmatched cells
    final unmatchedCells = <Cell>[];
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (!grid[i][j].isMatched) {
          unmatchedCells.add(grid[i][j]);
        }
      }
    }

    if (unmatchedCells.length < 2) return null;

    // Try random combinations for fast hint (limit attempts)
    final maxAttempts = math.min(20, unmatchedCells.length * 2);
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final cell1 = unmatchedCells[random.nextInt(unmatchedCells.length)];
      final cell2 = unmatchedCells[random.nextInt(unmatchedCells.length)];

      if (cell1 != cell2 && canCellsMatch(cell1, cell2, grid)) {
        return MatchPair(cell1, cell2);
      }
    }

    // Fallback to systematic search if random didn't work
    final matches = getAllPossibleMatches(grid);
    return matches.isEmpty ? null : matches[random.nextInt(matches.length)];
  }

  // Optimized solvability check
  static bool isLevelSolvable(List<List<Cell>> grid, int targetMatches) {
    final matches = getAllPossibleMatches(grid);
    return matches.length >= targetMatches;
  }

  // Optimized grid generation
  static List<List<Cell>> generateBalancedGrid(Level level) {
    clearCache(); // Clear cache for new grid

    List<List<Cell>> grid;
    int attempts = 0;
    const maxAttempts = 50; // Reduced for faster generation

    do {
      grid = _generateRandomGrid(level);
      attempts++;
    } while (!isLevelSolvable(grid, level.targetMatches) && attempts < maxAttempts);

    if (attempts >= maxAttempts) {
      grid = _generateGuaranteedSolvableGrid(level);
    }

    return grid;
  }

  static List<List<Cell>> _generateRandomGrid(Level level) {
    final random = Random();
    final limitedNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];

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
    final limitedNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    final matchesNeeded = level.targetMatches;

    // Place guaranteed matches efficiently
    int matchesPlaced = 0;
    final positions = <List<int>>[];

    for (int i = 0; i < level.gridSize; i++) {
      for (int j = 0; j < level.gridSize; j++) {
        positions.add([i, j]);
      }
    }
    positions.shuffle(random);

    // Place matches in pairs
    for (int i = 0; i < positions.length - 1 && matchesPlaced < matchesNeeded; i += 2) {
      final pos1 = positions[i];
      final pos2 = positions[i + 1];
      final value = limitedNumbers[random.nextInt(limitedNumbers.length)];

      if (random.nextBool() && value <= 5) {
        // Sum to 10 match
        final complement = 10 - value;
        grid[pos1[0]][pos1[1]] = Cell(value: value, row: pos1[0], col: pos1[1]);
        grid[pos2[0]][pos2[1]] = Cell(value: complement, row: pos2[0], col: pos2[1]);
      } else {
        // Equal match
        grid[pos1[0]][pos1[1]] = Cell(value: value, row: pos1[0], col: pos1[1]);
        grid[pos2[0]][pos2[1]] = Cell(value: value, row: pos2[0], col: pos2[1]);
      }

      matchesPlaced++;
    }

    // Fill remaining cells
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

  // Fast difficulty calculation
  static double calculateDifficulty(List<List<Cell>> grid) {
    final matches = getAllPossibleMatches(grid);
    final totalCells = grid.length * grid[0].length;
    final unmatchedCount = grid.expand((row) => row).where((cell) => !cell.isMatched).length;

    if (unmatchedCount <= 1) return 0.0;

    final possiblePairs = unmatchedCount * (unmatchedCount - 1) / 2;
    final matchRatio = matches.length / possiblePairs;
    return (1.0 - matchRatio).clamp(0.0, 1.0);
  }

  // Optimized path visualization with caching
  static List<Cell>? getPath(Cell start, Cell end, List<List<Cell>> grid) {
    final cacheKey = '${start.row},${start.col}-${end.row},${end.col}-path';

    if (_fullPathCache.containsKey(cacheKey)) {
      return _fullPathCache[cacheKey];
    }

    if (!hasValidPath(start, end, grid)) {
      _fullPathCache[cacheKey] = null;
      return null;
    }

    List<Cell>? path;

    // Try direct path first
    if (hasDirectPath(start, end, grid)) {
      path = _getDirectPath(start, end);
    } else {
      // Try L-shaped path
      path = _getLShapedPath(start, end, grid);

      if (path == null) {
        // Try U-shaped path
        path = _getUShapedPath(start, end, grid);
      }
    }

    _fullPathCache[cacheKey] = path;
    return path;
  }

  // Optimized path generation methods
  static List<Cell> _getDirectPath(Cell start, Cell end) {
    final path = <Cell>[start];

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
    if (_isValidCornerFast(start.row, end.col, grid) &&
        _isHorizontalPathClearFast(start.row, start.col, end.col, grid) &&
        _isVerticalPathClearFast(end.col, start.row, end.row, grid)) {

      final path = <Cell>[start];

      // Horizontal segment
      final hStep = start.col < end.col ? 1 : -1;
      for (int col = start.col + hStep; col != end.col; col += hStep) {
        path.add(Cell(value: 0, row: start.row, col: col));
      }

      // Corner
      if (start.row != end.row) {
        path.add(Cell(value: 0, row: start.row, col: end.col));
      }

      // Vertical segment
      final vStep = start.row < end.row ? 1 : -1;
      for (int row = start.row + vStep; row != end.row; row += vStep) {
        path.add(Cell(value: 0, row: row, col: end.col));
      }

      path.add(end);
      return path;
    }

    // Try corner at (end.row, start.col)
    if (_isValidCornerFast(end.row, start.col, grid) &&
        _isVerticalPathClearFast(start.col, start.row, end.row, grid) &&
        _isHorizontalPathClearFast(end.row, start.col, end.col, grid)) {

      final path = <Cell>[start];

      // Vertical segment
      final vStep = start.row < end.row ? 1 : -1;
      for (int row = start.row + vStep; row != end.row; row += vStep) {
        path.add(Cell(value: 0, row: row, col: start.col));
      }

      // Corner
      if (start.col != end.col) {
        path.add(Cell(value: 0, row: end.row, col: start.col));
      }

      // Horizontal segment
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

    // Limit search space for performance
    final maxExtend = math.min(gridSize, 15);

    for (int extendCol = 0; extendCol < maxExtend; extendCol++) {
      if (extendCol == start.col && extendCol == end.col) continue;

      if (_isValidCornerFast(start.row, extendCol, grid) &&
          _isValidCornerFast(end.row, extendCol, grid) &&
          _isHorizontalPathClearFast(start.row, start.col, extendCol, grid) &&
          _isVerticalPathClearFast(extendCol, start.row, end.row, grid) &&
          _isHorizontalPathClearFast(end.row, extendCol, end.col, grid)) {

        final path = <Cell>[start];

        // Horizontal to first corner
        final h1Step = start.col < extendCol ? 1 : -1;
        for (int col = start.col + h1Step; col != extendCol; col += h1Step) {
          path.add(Cell(value: 0, row: start.row, col: col));
        }
        path.add(Cell(value: 0, row: start.row, col: extendCol));

        // Vertical between corners
        final vStep = start.row < end.row ? 1 : -1;
        for (int row = start.row + vStep; row != end.row; row += vStep) {
          path.add(Cell(value: 0, row: row, col: extendCol));
        }
        path.add(Cell(value: 0, row: end.row, col: extendCol));

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

  // Timer methods remain the same
  void startTimer(GameState gameState) {
    stopTimer();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (gameState.status == GameStatus.playing) {
        gameState.decrementTime();
        if (gameState.timeRemaining <= 0) {
          stopTimer();
        }
      }
    });
  }

  void stopTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  void pauseTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  void resumeTimer(GameState gameState) {
    if (gameState.status == GameStatus.playing) {
      startTimer(gameState);
    }
  }

  void dispose() {
    stopTimer();
    clearCache(); // Clean up cache on disposal
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MatchPair &&
              runtimeType == other.runtimeType &&
              ((cell1 == other.cell1 && cell2 == other.cell2) ||
                  (cell1 == other.cell2 && cell2 == other.cell1));

  @override
  int get hashCode => cell1.hashCode ^ cell2.hashCode;
}