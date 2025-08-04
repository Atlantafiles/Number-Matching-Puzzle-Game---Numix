import 'dart:math';
import '../models/cells.dart';
import '../models/level.dart';
import '../services/game_controller.dart';

class LevelGenerator {
  static final Random _random = Random();

  // Numbers limited to 1-9 for all generation
  static const List<int> allowedNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  // Generate a grid for a specific level with path-based matching in mind
  static List<List<Cell>> generateLevelGrid(Level level) {
    List<List<Cell>> grid;
    int attempts = 0;
    const maxAttempts = 50;

    do {
      grid = _createPathFriendlyGrid(level);
      attempts++;
    } while (!_isGridValidForPathMatching(grid, level) && attempts < maxAttempts);

    if (attempts >= maxAttempts) {
      // Fallback to a simpler but guaranteed valid grid
      grid = _createSimplePathValidGrid(level);
    }

    return grid;
  }

  // Create a grid designed for path-based matching
  static List<List<Cell>> _createPathFriendlyGrid(Level level) {
    final grid = List.generate(
      level.gridSize,
          (row) => List.generate(
        level.gridSize,
            (col) => Cell(value: 1, row: row, col: col), // Placeholder
      ),
    );

    // Strategy 1: Place some cells that will be matched early to create paths
    _placeInitialMatches(grid, level);

    // Strategy 2: Place strategic matches with path considerations
    _placePathFriendlyMatches(grid, level);

    // Strategy 3: Fill remaining cells with balanced distribution
    _fillRemainingCellsBalanced(grid, level);

    return grid;
  }

  // Place initial matches that will create paths when matched
  static void _placeInitialMatches(List<List<Cell>> grid, Level level) {
    final positions = _getAvailablePositions(grid);
    final targetInitialMatches = (level.targetMatches * 0.2).ceil(); // 20% for path creation

    int placedMatches = 0;
    while (placedMatches < targetInitialMatches && positions.length >= 2) {
      // Place matches that are easily accessible (adjacent or near edges)
      final pos1 = positions.removeAt(_random.nextInt(positions.length));
      final pos2 = _findNearbyPosition(positions, pos1, level.gridSize);

      if (pos2 != null) {
        positions.remove(pos2);
        final value = allowedNumbers[_random.nextInt(allowedNumbers.length)];

        grid[pos1.row][pos1.col] = Cell(value: value, row: pos1.row, col: pos1.col);
        grid[pos2.row][pos2.col] = Cell(value: value, row: pos2.row, col: pos2.col);

        placedMatches++;
      }
    }
  }

  // Find a nearby position for creating easy matches
  static Cell? _findNearbyPosition(List<Cell> positions, Cell reference, int gridSize) {
    // Look for positions in the same row or column (direct path)
    for (final pos in positions) {
      if (pos.row == reference.row || pos.col == reference.col) {
        return pos;
      }
    }

    // Look for positions that would create L-shaped paths
    for (final pos in positions) {
      final rowDiff = (pos.row - reference.row).abs();
      final colDiff = (pos.col - reference.col).abs();
      if (rowDiff <= 2 && colDiff <= 2) {
        return pos;
      }
    }

    // Fallback to any position
    return positions.isNotEmpty ? positions.first : null;
  }

  // Place matches considering path connectivity
  static void _placePathFriendlyMatches(List<List<Cell>> grid, Level level) {
    final positions = _getAvailablePositions(grid);
    final targetMatches = (level.targetMatches * 0.6).ceil(); // 60% main matches

    // Define complementary pairs that sum to 10
    final sumPairs = <List<int>>[
      [1, 9], [2, 8], [3, 7], [4, 6], [5, 5]
    ];

    int placedMatches = 0;
    while (placedMatches < targetMatches && positions.length >= 2) {
      final pos1 = positions.removeAt(_random.nextInt(positions.length));
      final pos2 = positions.removeAt(_random.nextInt(positions.length));

      if (_random.nextBool()) {
        // Place equal match
        final value = allowedNumbers[_random.nextInt(allowedNumbers.length)];
        grid[pos1.row][pos1.col] = Cell(value: value, row: pos1.row, col: pos1.col);
        grid[pos2.row][pos2.col] = Cell(value: value, row: pos2.row, col: pos2.col);
      } else {
        // Place sum-to-10 match
        final pair = sumPairs[_random.nextInt(sumPairs.length)];
        grid[pos1.row][pos1.col] = Cell(value: pair[0], row: pos1.row, col: pos1.col);
        grid[pos2.row][pos2.col] = Cell(value: pair[1], row: pos2.row, col: pos2.col);
      }

      placedMatches++;
    }
  }

  // Fill remaining cells with balanced values
  static void _fillRemainingCellsBalanced(List<List<Cell>> grid, Level level) {
    for (int i = 0; i < level.gridSize; i++) {
      for (int j = 0; j < level.gridSize; j++) {
        if (grid[i][j].value == 1) { // Still has placeholder value
          final value = _getBalancedRandomValue(grid);
          grid[i][j] = Cell(value: value, row: i, col: j);
        }
      }
    }
  }

  // Get a random value that maintains balance in the grid
  static int _getBalancedRandomValue(List<List<Cell>> grid) {
    // Count existing values
    final valueCounts = <int, int>{};
    for (final row in grid) {
      for (final cell in row) {
        if (cell.value != 1) { // Not placeholder
          valueCounts[cell.value] = (valueCounts[cell.value] ?? 0) + 1;
        }
      }
    }

    // Find underrepresented values
    final underrepresented = allowedNumbers.where((int num) =>
    (valueCounts[num] ?? 0) < 2).toList();

    if (underrepresented.isNotEmpty) {
      return underrepresented[_random.nextInt(underrepresented.length)];
    }

    // If all numbers are well represented, return random
    return allowedNumbers[_random.nextInt(allowedNumbers.length)];
  }

  // Get all available (empty) positions in the grid
  static List<Cell> _getAvailablePositions(List<List<Cell>> grid) {
    final positions = <Cell>[];
    for (int i = 0; i < grid.length; i++) {
      for (int j = 0; j < grid[i].length; j++) {
        if (grid[i][j].value == 1) { // Placeholder value means available
          positions.add(Cell(value: 0, row: i, col: j));
        }
      }
    }
    return positions;
  }

  // Check if the generated grid is valid for path-based matching
  static bool _isGridValidForPathMatching(List<List<Cell>> grid, Level level) {
    final possibleMatches = GameController.getAllPossibleMatches(grid);

    // Must have at least the target number of matches
    if (possibleMatches.length < level.targetMatches) {
      return false;
    }

    // Should have a good distribution of match types
    int equalMatches = 0;
    int sumMatches = 0;

    for (final match in possibleMatches) {
      if (match.cell1.value == match.cell2.value) {
        equalMatches++;
      } else if (match.cell1.value + match.cell2.value == 10) {
        sumMatches++;
      }
    }

    // Ensure we have both types of matches for variety
    return equalMatches > 0 && sumMatches > 0;
  }

  // Create a simple but guaranteed valid grid as fallback
  static List<List<Cell>> _createSimplePathValidGrid(Level level) {
    final grid = List.generate(
      level.gridSize,
          (row) => List.generate(
        level.gridSize,
            (col) => Cell(value: 1, row: row, col: col),
      ),
    );

    // Create a pattern that ensures path-based matches
    final positions = <List<int>>[];
    for (int i = 0; i < level.gridSize; i++) {
      for (int j = 0; j < level.gridSize; j++) {
        positions.add([i, j]);
      }
    }
    positions.shuffle(_random);

    // Place guaranteed matches
    int matchesPlaced = 0;
    for (int i = 0; i < positions.length - 1 && matchesPlaced < level.targetMatches; i += 2) {
      final pos1 = positions[i];
      final pos2 = positions[i + 1];

      final value = allowedNumbers[_random.nextInt(allowedNumbers.length)];

      grid[pos1[0]][pos1[1]] = Cell(value: value, row: pos1[0], col: pos1[1]);
      grid[pos2[0]][pos2[1]] = Cell(value: value, row: pos2[0], col: pos2[1]);

      matchesPlaced++;
    }

    // Fill remaining cells
    for (int i = 0; i < level.gridSize; i++) {
      for (int j = 0; j < level.gridSize; j++) {
        if (grid[i][j].value == 1) {
          final value = allowedNumbers[_random.nextInt(allowedNumbers.length)];
          grid[i][j] = Cell(value: value, row: i, col: j);
        }
      }
    }

    return grid;
  }

  // Generate multiple grid options and pick the best one
  static List<List<Cell>> generateOptimalGrid(Level level) {
    List<List<Cell>> bestGrid = generateLevelGrid(level);
    double bestScore = _evaluateGridQuality(bestGrid, level);

    // Generate multiple candidates and pick the best
    for (int attempt = 0; attempt < 5; attempt++) {
      final candidate = generateLevelGrid(level);
      final score = _evaluateGridQuality(candidate, level);

      if (score > bestScore) {
        bestScore = score;
        bestGrid = candidate;
      }
    }

    return bestGrid;
  }

  // Evaluate the quality of a generated grid for path-based matching
  static double _evaluateGridQuality(List<List<Cell>> grid, Level level) {
    final matches = GameController.getAllPossibleMatches(grid);

    if (matches.length < level.targetMatches) {
      return 0.0; // Invalid grid
    }

    double score = 0.0;

    // Factor 1: Number of available matches (more is better, up to a point)
    final matchRatio = matches.length / level.targetMatches;
    score += (matchRatio > 2.0) ? 2.0 - (matchRatio - 2.0) * 0.1 : matchRatio;

    // Factor 2: Variety of match types
    int equalMatches = 0;
    int sumMatches = 0;
    int directPaths = 0;
    int lShapedPaths = 0;

    for (final match in matches) {
      if (match.cell1.value == match.cell2.value) {
        equalMatches++;
      } else {
        sumMatches++;
      }

      // Analyze path complexity
      if (GameController.hasDirectPath(match.cell1, match.cell2, grid)) {
        directPaths++;
      } else if (GameController.hasLShapedPath(match.cell1, match.cell2, grid)) {
        lShapedPaths++;
      }
    }

    final equalRatio = equalMatches / matches.length;
    final sumRatio = sumMatches / matches.length;

    // Prefer balanced mix (around 50-50)
    score += 1.0 - (equalRatio - 0.5).abs() - (sumRatio - 0.5).abs();

    // Factor 3: Path variety (prefer mix of direct and L-shaped paths)
    final directRatio = directPaths / matches.length;
    score += 1.0 - (directRatio - 0.4).abs(); // Prefer ~40% direct paths

    // Factor 4: Number variety (avoid too many duplicates)
    final valueCounts = <int, int>{};
    for (final row in grid) {
      for (final cell in row) {
        valueCounts[cell.value] = (valueCounts[cell.value] ?? 0) + 1;
      }
    }

    final maxCount = valueCounts.values.reduce((a, b) => a > b ? a : b);
    final totalCells = level.gridSize * level.gridSize;
    score += 1.0 - (maxCount / totalCells); // Penalize too many duplicates

    return score;
  }

  // Generate grid with guaranteed minimum matches for path-based system
  static List<List<Cell>> generateGuaranteedGrid(Level level, {int extraMatches = 5}) {
    final targetWithBuffer = level.targetMatches + extraMatches;
    List<List<Cell>> grid;

    do {
      grid = _createPathFriendlyGrid(level);
    } while (GameController.getAllPossibleMatches(grid).length < targetWithBuffer);

    return grid;
  }

  // Analyze grid for path-based matching
  static GridAnalysis analyzeGrid(List<List<Cell>> grid, Level level) {
    final matches = GameController.getAllPossibleMatches(grid);
    final valueCounts = <int, int>{};
    final matchTypes = <String, int>{'equal': 0, 'sum': 0};
    final pathTypes = <String, int>{'direct': 0, 'lshaped': 0, 'ushaped': 0};

    // Count value frequency
    for (final row in grid) {
      for (final cell in row) {
        if (!cell.isMatched) {
          valueCounts[cell.value] = (valueCounts[cell.value] ?? 0) + 1;
        }
      }
    }

    // Analyze match and path types
    for (final match in matches) {
      if (match.cell1.value == match.cell2.value) {
        matchTypes['equal'] = matchTypes['equal']! + 1;
      } else {
        matchTypes['sum'] = matchTypes['sum']! + 1;
      }

      // Analyze path type
      if (GameController.hasDirectPath(match.cell1, match.cell2, grid)) {
        pathTypes['direct'] = pathTypes['direct']! + 1;
      } else if (GameController.hasLShapedPath(match.cell1, match.cell2, grid)) {
        pathTypes['lshaped'] = pathTypes['lshaped']! + 1;
      } else {
        pathTypes['ushaped'] = pathTypes['ushaped']! + 1;
      }
    }

    return GridAnalysis(
      totalMatches: matches.length,
      equalMatches: matchTypes['equal']!,
      sumMatches: matchTypes['sum']!,
      directPaths: pathTypes['direct']!,
      lShapedPaths: pathTypes['lshaped']!,
      uShapedPaths: pathTypes['ushaped']!,
      valueCounts: valueCounts,
      isSolvable: matches.length >= level.targetMatches,
      difficultyScore: GameController.calculateDifficulty(grid),
      qualityScore: _evaluateGridQuality(grid, level),
    );
  }

  // Generate themed grids for path-based matching
  static List<List<Cell>> generateThemedGrid(Level level, GridTheme theme) {
    switch (theme) {
      case GridTheme.mathematical:
        return _generateMathematicalPathGrid(level);
      case GridTheme.sequential:
        return _generateSequentialPathGrid(level);
      case GridTheme.symmetric:
        return _generateSymmetricPathGrid(level);
      case GridTheme.random:
        return generateLevelGrid(level);
    }
  }

  // Mathematical theme for path-based matching
  static List<List<Cell>> _generateMathematicalPathGrid(Level level) {
    final grid = List.generate(
      level.gridSize,
          (row) => List.generate(
        level.gridSize,
            (col) => Cell(value: 1, row: row, col: col),
      ),
    );

    // Place Fibonacci sequence along edges for easy paths
    final fibonacci = [1, 1, 2, 3, 5, 8];
    int fibIndex = 0;

    // Top and bottom rows
    for (int col = 0; col < level.gridSize && fibIndex < fibonacci.length; col++) {
      if (fibIndex < fibonacci.length) {
        grid[0][col] = Cell(value: fibonacci[fibIndex], row: 0, col: col);
        fibIndex++;
      }
      if (fibIndex < fibonacci.length && level.gridSize > 1) {
        grid[level.gridSize - 1][col] = Cell(value: fibonacci[fibIndex], row: level.gridSize - 1, col: col);
        fibIndex++;
      }
    }

    _fillRemainingCellsBalanced(grid, level);
    return grid;
  }

  // Sequential theme for path-based matching
  static List<List<Cell>> _generateSequentialPathGrid(Level level) {
    final grid = List.generate(
      level.gridSize,
          (row) => List.generate(
        level.gridSize,
            (col) => Cell(value: ((row + col) % allowedNumbers.length) + 1, row: row, col: col),
      ),
    );

    // Add strategic duplicates for matches
    _addStrategicDuplicatesForPaths(grid, level);
    return grid;
  }

  // Symmetric theme for path-based matching
  static List<List<Cell>> _generateSymmetricPathGrid(Level level) {
    final grid = List.generate(
      level.gridSize,
          (row) => List.generate(
        level.gridSize,
            (col) => Cell(value: 1, row: row, col: col),
      ),
    );

    // Fill with symmetric pattern that creates good paths
    for (int i = 0; i < level.gridSize; i++) {
      for (int j = 0; j <= level.gridSize ~/ 2; j++) {
        final value = allowedNumbers[_random.nextInt(allowedNumbers.length)];
        grid[i][j] = Cell(value: value, row: i, col: j);

        // Mirror to create matching opportunities
        final mirrorJ = level.gridSize - 1 - j;
        if (mirrorJ != j) {
          grid[i][mirrorJ] = Cell(value: value, row: i, col: mirrorJ);
        }
      }
    }

    return grid;
  }

  // Add strategic duplicates considering path connectivity
  static void _addStrategicDuplicatesForPaths(List<List<Cell>> grid, Level level) {
    final allPositions = <List<int>>[];
    for (int i = 0; i < level.gridSize; i++) {
      for (int j = 0; j < level.gridSize; j++) {
        allPositions.add([i, j]);
      }
    }

    // Create some guaranteed matches with good path connectivity
    for (int matches = 0; matches < level.targetMatches && allPositions.length >= 2; matches++) {
      allPositions.shuffle(_random);

      final pos1 = allPositions.removeAt(0);
      final pos2 = allPositions.removeAt(0);

      final value = allowedNumbers[_random.nextInt(allowedNumbers.length)];

      grid[pos1[0]][pos1[1]] = Cell(value: value, row: pos1[0], col: pos1[1]);
      grid[pos2[0]][pos2[1]] = Cell(value: value, row: pos2[0], col: pos2[1]);
    }
  }

  // Create custom level with path-based considerations
  static Level createCustomLevel({
    required int levelNumber,
    required int gridSize,
    required int targetMatches,
    int timeLimit = 120,
    String? description,
  }) {
    return Level(
      levelNumber: levelNumber,
      gridSize: gridSize,
      availableNumbers: allowedNumbers, // Always use 1-9
      description: description ?? 'Custom Level $levelNumber',
      timeLimit: timeLimit,
      targetMatches: targetMatches,
    );
  }

  // Validate level for path-based matching
  static bool validateLevelForPaths(Level level) {
    // Check if target matches is achievable with path constraints
    final maxPossibleMatches = (level.gridSize * level.gridSize) ~/ 2;
    if (level.targetMatches > maxPossibleMatches) {
      return false;
    }

    // Generate test grid and verify it meets requirements
    final testGrid = generateLevelGrid(level);
    final matches = GameController.getAllPossibleMatches(testGrid);

    return matches.length >= level.targetMatches;
  }

  // Get difficulty rating considering path complexity
  static String getDifficultyRating(Level level) {
    final testGrid = generateLevelGrid(level);
    final analysis = analyzeGrid(testGrid, level);

    final directRatio = analysis.directPaths / analysis.totalMatches;
    final matchRatio = analysis.totalMatches / level.targetMatches;

    // Consider both match availability and path complexity
    double difficultyScore = 0.0;

    // Fewer matches = harder
    if (matchRatio >= 2.5) difficultyScore += 1.0;
    else if (matchRatio >= 1.8) difficultyScore += 2.0;
    else if (matchRatio >= 1.3) difficultyScore += 3.0;
    else difficultyScore += 4.0;

    // More complex paths = harder
    if (directRatio >= 0.6) difficultyScore += 1.0; // Easy paths
    else if (directRatio >= 0.4) difficultyScore += 2.0; // Mixed paths
    else difficultyScore += 3.0; // Complex paths

    // Grid size factor
    if (level.gridSize >= 6) difficultyScore += 1.0;

    if (difficultyScore <= 3.0) return 'Easy';
    if (difficultyScore <= 5.0) return 'Medium';
    if (difficultyScore <= 7.0) return 'Hard';
    return 'Expert';
  }

  // Optimize grid for better path-based gameplay
  static List<List<Cell>> optimizeGridForPaths(List<List<Cell>> originalGrid, Level level) {
    var bestGrid = originalGrid;
    var bestScore = _evaluateGridQuality(originalGrid, level);

    // Try swapping cells to improve path connectivity
    for (int attempt = 0; attempt < 30; attempt++) {
      final testGrid = originalGrid.map((row) =>
          row.map((cell) => Cell(
            value: cell.value,
            row: cell.row,
            col: cell.col,
            state: cell.state,
          )).toList()).toList();

      // Swap cells to potentially create better paths
      final pos1 = _getRandomPosition(level.gridSize);
      final pos2 = _getRandomPosition(level.gridSize);

      final tempValue = testGrid[pos1.row][pos1.col].value;
      testGrid[pos1.row][pos1.col] = testGrid[pos1.row][pos1.col].copyWith(
          value: testGrid[pos2.row][pos2.col].value);
      testGrid[pos2.row][pos2.col] = testGrid[pos2.row][pos2.col].copyWith(
          value: tempValue);

      final score = _evaluateGridQuality(testGrid, level);
      if (score > bestScore) {
        bestScore = score;
        bestGrid = testGrid;
      }
    }

    return bestGrid;
  }

  // Get random position in grid
  static Cell _getRandomPosition(int gridSize) {
    return Cell(
      value: 0,
      row: _random.nextInt(gridSize),
      col: _random.nextInt(gridSize),
    );
  }

  // Generate progressive difficulty grids
  static List<List<Cell>> generateProgressiveGrid(Level level, double difficultyMultiplier) {
    // Adjust target matches and complexity based on difficulty
    final adjustedLevel = Level(
      levelNumber: level.levelNumber,
      gridSize: level.gridSize,
      availableNumbers: allowedNumbers,
      description: level.description,
      timeLimit: level.timeLimit,
      targetMatches: (level.targetMatches * difficultyMultiplier).ceil(),
    );

    return generateOptimalGrid(adjustedLevel);
  }

  // Check if grid has deadlock potential
  static bool hasDeadlockRisk(List<List<Cell>> grid, Level level) {
    // Simulate partial gameplay to check for potential deadlocks
    final testGrid = grid.map((row) => row.map((cell) => Cell(
      value: cell.value,
      row: cell.row,
      col: cell.col,
      state: cell.state,
    )).toList()).toList();

    // Remove some matches and check if remaining grid is still solvable
    final matches = GameController.getAllPossibleMatches(testGrid);
    if (matches.length < level.targetMatches * 1.5) return true;

    // Simulate removing 30% of available matches
    final matchesToRemove = (matches.length * 0.3).floor();
    for (int i = 0; i < matchesToRemove && i < matches.length; i++) {
      final match = matches[i];
      testGrid[match.cell1.row][match.cell1.col] =
          match.cell1.copyWith(state: CellState.matched);
      testGrid[match.cell2.row][match.cell2.col] =
          match.cell2.copyWith(state: CellState.matched);
    }

    final remainingMatches = GameController.getAllPossibleMatches(testGrid);
    return remainingMatches.length < (level.targetMatches - matchesToRemove);
  }

  // Generate tutorial-friendly grid
  static List<List<Cell>> generateTutorialGrid(Level level) {
    final grid = List.generate(
      level.gridSize,
          (row) => List.generate(
        level.gridSize,
            (col) => Cell(value: 1, row: row, col: col),
      ),
    );

    // Place obvious matches for tutorial
    // Direct horizontal matches
    if (level.gridSize >= 4) {
      grid[0][0] = Cell(value: 2, row: 0, col: 0);
      grid[0][1] = Cell(value: 2, row: 0, col: 1);

      // Sum to 10 match
      grid[1][0] = Cell(value: 3, row: 1, col: 0);
      grid[1][1] = Cell(value: 7, row: 1, col: 1);
    }

    // Fill remaining with balanced values
    _fillRemainingCellsBalanced(grid, level);

    return grid;
  }

  // Generate challenge grid with complex paths
  static List<List<Cell>> generateChallengeGrid(Level level) {
    List<List<Cell>> grid;
    int attempts = 0;

    do {
      grid = _createPathFriendlyGrid(level);
      attempts++;
    } while (_getAveragePathComplexity(grid) < 1.5 && attempts < 20);

    return grid;
  }

  // Calculate average path complexity
  static double _getAveragePathComplexity(List<List<Cell>> grid) {
    final matches = GameController.getAllPossibleMatches(grid);
    if (matches.isEmpty) return 0.0;

    int totalComplexity = 0;
    for (final match in matches) {
      if (GameController.hasDirectPath(match.cell1, match.cell2, grid)) {
        totalComplexity += 1;
      } else if (GameController.hasLShapedPath(match.cell1, match.cell2, grid)) {
        totalComplexity += 2;
      } else {
        totalComplexity += 3; // U-shaped path
      }
    }

    return totalComplexity / matches.length;
  }

  // Generate grid with specific path distribution
  static List<List<Cell>> generateGridWithPathDistribution(
      Level level, {
        double directPathRatio = 0.4,
        double lShapedRatio = 0.4,
        double uShapedRatio = 0.2,
      }) {
    List<List<Cell>> bestGrid = generateLevelGrid(level);
    double bestScore = 0.0;

    for (int attempt = 0; attempt < 10; attempt++) {
      final grid = generateLevelGrid(level);
      final analysis = analyzeGrid(grid, level);

      if (analysis.totalMatches == 0) continue;

      final actualDirectRatio = analysis.directPaths / analysis.totalMatches;
      final actualLRatio = analysis.lShapedPaths / analysis.totalMatches;
      final actualURatio = analysis.uShapedPaths / analysis.totalMatches;

      // Calculate how close this is to desired distribution
      final score = 1.0 -
          (actualDirectRatio - directPathRatio).abs() -
          (actualLRatio - lShapedRatio).abs() -
          (actualURatio - uShapedRatio).abs();

      if (score > bestScore) {
        bestScore = score;
        bestGrid = grid;
      }
    }

    return bestGrid;
  }
}

// Enhanced analysis result class for path-based matching
class GridAnalysis {
  final int totalMatches;
  final int equalMatches;
  final int sumMatches;
  final int directPaths;
  final int lShapedPaths;
  final int uShapedPaths;
  final Map<int, int> valueCounts;
  final bool isSolvable;
  final double difficultyScore;
  final double qualityScore;

  GridAnalysis({
    required this.totalMatches,
    required this.equalMatches,
    required this.sumMatches,
    required this.directPaths,
    required this.lShapedPaths,
    required this.uShapedPaths,
    required this.valueCounts,
    required this.isSolvable,
    required this.difficultyScore,
    required this.qualityScore,
  });

  // Additional computed properties
  double get directPathRatio => totalMatches > 0 ? directPaths / totalMatches : 0.0;
  double get lShapedPathRatio => totalMatches > 0 ? lShapedPaths / totalMatches : 0.0;
  double get uShapedPathRatio => totalMatches > 0 ? uShapedPaths / totalMatches : 0.0;
  double get equalMatchRatio => totalMatches > 0 ? equalMatches / totalMatches : 0.0;
  double get sumMatchRatio => totalMatches > 0 ? sumMatches / totalMatches : 0.0;

  double get pathComplexityScore {
    return (directPaths * 1.0 + lShapedPaths * 2.0 + uShapedPaths * 3.0) / totalMatches;
  }

  @override
  String toString() {
    return 'GridAnalysis(matches: $totalMatches, equal: $equalMatches, sum: $sumMatches, '
        'direct: $directPaths, L-shaped: $lShapedPaths, U-shaped: $uShapedPaths, '
        'solvable: $isSolvable, quality: ${qualityScore.toStringAsFixed(2)})';
  }
}

// Grid themes enum
enum GridTheme {
  random,
  mathematical,
  sequential,
  symmetric,
}