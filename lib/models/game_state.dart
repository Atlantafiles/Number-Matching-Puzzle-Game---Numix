import 'package:flutter/foundation.dart';
import 'cells.dart';
import 'level.dart';
import '../services/level_generator.dart';
import '../services/game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameStatus {
  playing,
  paused,
  won,
  lost,
  timeUp,
}

enum MatchResult {
  valid,
  invalid,
  alreadyMatched,
  noPath,
}

class GameState extends ChangeNotifier {
  // Grid and game data
  List<List<Cell>> _grid = [];
  Cell? _selectedCell;
  Level _currentLevel = Level.level1;

  // Game progress
  int _score = 0;
  int _matchCount = 0;
  int _timeRemaining = 120; // 2 minutes in seconds
  GameStatus _status = GameStatus.playing;

  // Animation flags
  bool _isAnimating = false;
  String _lastMessage = '';

  // Path visualization
  List<Cell> _currentPath = [];

  // Getters
  List<List<Cell>> get grid => _grid;
  Cell? get selectedCell => _selectedCell;
  Level get currentLevel => _currentLevel;
  int get score => _score;
  int get matchCount => _matchCount;
  int get timeRemaining => _timeRemaining;
  GameStatus get status => _status;
  bool get isAnimating => _isAnimating;
  String get lastMessage => _lastMessage;
  List<Cell> get currentPath => _currentPath;

  // Grid dimensions
  int get gridSize => _currentLevel.gridSize;

  // Progress tracking
  double get progress => _matchCount / _currentLevel.targetMatches;
  bool get isLevelComplete => _matchCount >= _currentLevel.targetMatches;

  int _bestScore = 0;

  int get bestScore => _bestScore;


  // to save best score
  Future<void> _saveBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('best_score', _bestScore);
  }

  void checkAndUpdateBestScore() {
    if (score > bestScore) {
      _bestScore = score;
      _saveBestScore(); // Save to persistent storage
      notifyListeners(); // Update UI
    }
  }

 // whenever the score increases
  void addScore(int points) {
    _score += points;
    checkAndUpdateBestScore(); // Check for new high score
    notifyListeners();
  }


  // Initialize game with specific level
  void initializeGame(Level level) {
    _currentLevel = level;

    // Use the optimal grid generator with numbers limited to 1-9
    _grid = LevelGenerator.generateOptimalGrid(_createLimitedLevel(level));

    _score = 0;
    _matchCount = 0;
    _timeRemaining = level.timeLimit;
    _status = GameStatus.playing;
    _selectedCell = null;
    _currentPath = [];

    notifyListeners();
  }

  // Create a level with numbers limited to 1-9
  Level _createLimitedLevel(Level originalLevel) {
    final limitedNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    return Level(
      levelNumber: originalLevel.levelNumber,
      gridSize: originalLevel.gridSize,
      availableNumbers: limitedNumbers,
      description: originalLevel.description,
      timeLimit: originalLevel.timeLimit,
      targetMatches: originalLevel.targetMatches,
    );
  }

  // Handle cell selection with path validation
  MatchResult selectCell(int row, int col) {
    if (_status != GameStatus.playing || _isAnimating) {
      return MatchResult.invalid;
    }

    final cell = _grid[row][col];

    // Can't select already matched cells
    if (cell.isMatched) {
      return MatchResult.alreadyMatched;
    }

    // If no cell is selected, select this one
    if (_selectedCell == null) {
      _selectCell(cell);
      return MatchResult.valid;
    }

    // If same cell is clicked, deselect
    if (_selectedCell == cell) {
      _deselectCell();
      return MatchResult.valid;
    }

    // Try to match with selected cell (with path validation)
    return _tryMatch(_selectedCell!, cell);
  }

  void _selectCell(Cell cell) {
    _grid[cell.row][cell.col] = cell.copyWith(state: CellState.selected);
    _selectedCell = _grid[cell.row][cell.col];
    _currentPath = [];
    notifyListeners();
  }

  void _deselectCell() {
    if (_selectedCell != null) {
      _grid[_selectedCell!.row][_selectedCell!.col] =
          _selectedCell!.copyWith(state: CellState.normal);
      _selectedCell = null;
      _currentPath = [];
      notifyListeners();
    }
  }

  MatchResult _tryMatch(Cell cell1, Cell cell2) {
    _isAnimating = true;
    notifyListeners();

    // Check if it's a valid match with path connectivity
    if (!GameController.canCellsMatch(cell1, cell2, _grid)) {
      _lastMessage = 'No valid path!';

      Future.delayed(const Duration(milliseconds: 500), () {
        _isAnimating = false;
        _deselectCell();
        notifyListeners();
      });

      return MatchResult.noPath;
    }

    // Get and show the path
    final path = GameController.getPath(cell1, cell2, _grid);
    if (path != null) {
      _currentPath = path;
      notifyListeners();
    }

    // Perform the match
    _performMatch(cell1, cell2);
    _lastMessage = 'Great match!';

    Future.delayed(const Duration(milliseconds: 800), () {
      _currentPath = [];
      _isAnimating = false;
      _checkGameComplete();
      notifyListeners();
    });

    return MatchResult.valid;
  }

  void _performMatch(Cell cell1, Cell cell2) {
    // Mark both cells as matched
    _grid[cell1.row][cell1.col] = cell1.copyWith(state: CellState.matched);
    _grid[cell2.row][cell2.col] = cell2.copyWith(state: CellState.matched);

    // Update game state
    _selectedCell = null;
    _matchCount++;
    _score += _calculateScore(cell1.value, cell2.value);
  }

  int _calculateScore(int value1, int value2) {
    // Base score for any match
    int baseScore = 10;

    // Bonus for sum-to-10 matches
    if (value1 + value2 == 10) {
      baseScore += 5;
    }

    // Bonus for equal matches with higher numbers
    if (value1 == value2) {
      baseScore += value1;
    }

    // Bonus for time remaining (encourage quick matches)
    if (_timeRemaining > 60) {
      baseScore += 2;
    }

    return baseScore;
  }

  void _checkGameComplete() {
    if (isLevelComplete) {
      _status = GameStatus.won;
      _lastMessage = 'Level Complete! 🎉';
    } else if (!hasAvailableMatches()) {
      _status = GameStatus.lost;
      _lastMessage = 'No more matches available!';
    }
  }

  // Timer management
  void decrementTime() {
    if (_status == GameStatus.playing && _timeRemaining > 0) {
      _timeRemaining--;

      if (_timeRemaining == 0) {
        _status = GameStatus.timeUp;
        _lastMessage = 'Time\'s up!';
      }

      notifyListeners();
    }
  }

  // Game control methods
  void pauseGame() {
    if (_status == GameStatus.playing) {
      _status = GameStatus.paused;
      notifyListeners();
    }
  }

  void resumeGame() {
    if (_status == GameStatus.paused) {
      _status = GameStatus.playing;
      notifyListeners();
    }
  }

  void restartLevel() {
    initializeGame(_currentLevel);
    _score = 0; // Make sure score resets but bestScore persists
    notifyListeners();
  }

  void nextLevel() {
    if (_currentLevel.levelNumber < Level.allLevels.length) {
      final nextLevel = Level.getLevelByNumber(_currentLevel.levelNumber + 1);
      initializeGame(nextLevel);
    }
  }

  // Reset game to level 1
  void resetGame() {
    initializeGame(Level.level1);
  }

  // Get formatted time string
  String get formattedTime {
    final minutes = _timeRemaining ~/ 60;
    final seconds = _timeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Check if there are any possible matches remaining (with path validation)
  bool hasAvailableMatches() {
    return GameController.getAllPossibleMatches(_grid).isNotEmpty;
  }

  // Get hint for next possible match
  MatchPair? getHint() {
    return GameController.getHint(_grid);
  }

  // Shuffle remaining cells (power-up feature)
  void shuffleGrid() {
    if (_status != GameStatus.playing) return;

    final availableCells = <Cell>[];
    final values = <int>[];

    // Collect all unmatched cells and their values
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (!_grid[i][j].isMatched) {
          availableCells.add(_grid[i][j]);
          values.add(_grid[i][j].value);
        }
      }
    }

    // Shuffle the values
    values.shuffle();

    // Reassign shuffled values to cells
    for (int i = 0; i < availableCells.length; i++) {
      final cell = availableCells[i];
      _grid[cell.row][cell.col] = cell.copyWith(value: values[i]);
    }

    // Clear selection and path
    _selectedCell = null;
    _currentPath = [];
    _lastMessage = 'Grid shuffled!';

    notifyListeners();
  }


  // Remove a specific number from the grid (power-up feature)
  void removeNumber(int number) {
    if (_status != GameStatus.playing) return;

    int removed = 0;
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (!_grid[i][j].isMatched && _grid[i][j].value == number) {
          _grid[i][j] = _grid[i][j].copyWith(state: CellState.matched);
          removed++;
          if (removed >= 2) break; // Remove maximum 2 cells
        }
      }
      if (removed >= 2) break;
    }

    if (removed > 0) {
      _score += removed * 5; // Bonus points for using power-up
      _lastMessage = 'Removed $removed cells with number $number!';
    } else {
      _lastMessage = 'No cells found with number $number';
    }

    // Clear selection and path
    _selectedCell = null;
    _currentPath = [];

    notifyListeners();
  }

  // Add time bonus (power-up feature)
  void addTimeBonus(int seconds) {
    if (_status == GameStatus.playing) {
      _timeRemaining += seconds;
      _lastMessage = 'Added $seconds seconds!';
      notifyListeners();
    }
  }

  // Show path preview when hovering over a cell (for UI feedback)
  void previewPath(int row, int col) {
    if (_selectedCell == null || _status != GameStatus.playing) {
      _currentPath = [];
      return;
    }

    final targetCell = _grid[row][col];
    if (targetCell.isMatched || targetCell == _selectedCell) {
      _currentPath = [];
      return;
    }

    // Check if cells can match and get path
    if (GameController.canCellsMatch(_selectedCell!, targetCell, _grid)) {
      final path = GameController.getPath(_selectedCell!, targetCell, _grid);
      _currentPath = path ?? [];
    } else {
      _currentPath = [];
    }

    notifyListeners();
  }

  // Clear path preview
  void clearPathPreview() {
    if (_currentPath.isNotEmpty) {
      _currentPath = [];
      notifyListeners();
    }
  }

  // Get statistics for the current game
  GameStatistics getStatistics() {
    final totalCells = gridSize * gridSize;
    final matchedCells = _grid.expand((row) => row).where((cell) => cell.isMatched).length;
    final remainingCells = totalCells - matchedCells;
    final possibleMatches = GameController.getAllPossibleMatches(_grid);

    return GameStatistics(
      level: _currentLevel.levelNumber,
      score: _score,
      matchCount: _matchCount,
      targetMatches: _currentLevel.targetMatches,
      timeRemaining: _timeRemaining,
      totalTime: _currentLevel.timeLimit,
      remainingCells: remainingCells,
      possibleMatches: possibleMatches.length,
      isComplete: isLevelComplete,
    );
  }

  // Auto-hint system - highlights possible matches after inactivity
  void showAutoHint() {
    if (_status != GameStatus.playing) return;

    final hint = getHint();
    if (hint != null) {
      _currentPath = GameController.getPath(hint.cell1, hint.cell2, _grid) ?? [];
      _lastMessage = 'Hint: Try these cells! 💡';

      // Clear hint after a few seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (_currentPath.isNotEmpty) {
          _currentPath = [];
          notifyListeners();
        }
      });

      notifyListeners();
    }
  }

  // Check if two specific cells can be matched (for UI validation)
  bool canMatchCells(int row1, int col1, int row2, int col2) {
    if (row1 < 0 || row1 >= gridSize || col1 < 0 || col1 >= gridSize ||
        row2 < 0 || row2 >= gridSize || col2 < 0 || col2 >= gridSize) {
      return false;
    }

    final cell1 = _grid[row1][col1];
    final cell2 = _grid[row2][col2];

    return GameController.canCellsMatch(cell1, cell2, _grid);
  }

  // Get all numbers currently on the grid (for UI display)
  Set<int> getAvailableNumbers() {
    final numbers = <int>{};
    for (final row in _grid) {
      for (final cell in row) {
        if (!cell.isMatched) {
          numbers.add(cell.value);
        }
      }
    }
    return numbers;
  }

  // Calculate completion percentage
  double get completionPercentage {
    return (_matchCount / _currentLevel.targetMatches).clamp(0.0, 1.0);
  }

  // Get time pressure indicator (for UI coloring)
  TimePressure get timePressure {
    final ratio = _timeRemaining / _currentLevel.timeLimit;
    if (ratio > 0.5) return TimePressure.low;
    if (ratio > 0.25) return TimePressure.medium;
    return TimePressure.high;
  }

  // Dispose method for cleanup
  @override
  void dispose() => super.dispose();
}

// Game statistics class
class GameStatistics {
  final int level;
  final int score;
  final int matchCount;
  final int targetMatches;
  final int timeRemaining;
  final int totalTime;
  final int remainingCells;
  final int possibleMatches;
  final bool isComplete;

  GameStatistics({
    required this.level,
    required this.score,
    required this.matchCount,
    required this.targetMatches,
    required this.timeRemaining,
    required this.totalTime,
    required this.remainingCells,
    required this.possibleMatches,
    required this.isComplete,
  });

  double get progress => matchCount / targetMatches;
  double get timeProgress => 1.0 - (timeRemaining / totalTime);
  int get timeUsed => totalTime - timeRemaining;
  double get efficiency => matchCount > 0 ? score / matchCount : 0.0;
}

// Time pressure enum
enum TimePressure { low, medium, high }