import 'package:flutter/cupertino.dart';
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
  int _timeRemaining = 120;
  GameStatus _status = GameStatus.playing;

  // Animation and UI state
  bool _isAnimating = false;
  String _lastMessage = '';
  List<Cell> _currentPath = [];
  int _bestScore = 0;

  // Performance optimization flags
  bool _suppressNotifications = false;
  bool _needsGridUpdate = false;
  DateTime _lastClickTime = DateTime.now();

  // Debouncing for rapid clicks
  static const Duration _clickDebounceTime = Duration(milliseconds: 100);

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
  int get bestScore => _bestScore;

  // Grid dimensions
  int get gridSize => _currentLevel.gridSize;

  // Progress tracking
  double get progress => _matchCount / _currentLevel.targetMatches;
  bool get isLevelComplete => _matchCount >= _currentLevel.targetMatches;

  // Batch notifications for better performance
  void _batchedNotify() {
    if (!_suppressNotifications && _needsGridUpdate) {
      _needsGridUpdate = false;
      notifyListeners();
    }
  }

  void _scheduleNotification() {
    _needsGridUpdate = true;
    if (!_suppressNotifications) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _batchedNotify());
    }
  }

  // Best score management with reduced I/O
  SharedPreferences? _prefs;
  bool _prefsInitialized = false;

  Future<void> _initializePrefs() async {
    if (!_prefsInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _bestScore = _prefs?.getInt('best_score') ?? 0;
      _prefsInitialized = true;
    }
  }

  Future<void> _saveBestScore() async {
    await _initializePrefs();
    await _prefs?.setInt('best_score', _bestScore);
  }

  void checkAndUpdateBestScore() {
    if (_score > _bestScore) {
      _bestScore = _score;
      _saveBestScore(); // Async save doesn't block UI
      _scheduleNotification();
    }
  }

  void addScore(int points) {
    _score += points;
    checkAndUpdateBestScore();
    _scheduleNotification();
  }

  // Optimized game initialization
  void initializeGame(Level level) async {
    _suppressNotifications = true; // Batch all updates

    await _initializePrefs(); // Load best score

    _currentLevel = level;
    GameController.clearCache(); // Clear cache for new grid

    // Generate grid efficiently
    _grid = LevelGenerator.generateOptimalGrid(_createLimitedLevel(level));

    _score = 0;
    _matchCount = 0;
    _timeRemaining = level.timeLimit;
    _status = GameStatus.playing;
    _selectedCell = null;
    _currentPath = [];
    _isAnimating = false;
    _lastMessage = '';

    _suppressNotifications = false;
    notifyListeners();
  }

  Level _createLimitedLevel(Level originalLevel) {
    return Level(
      levelNumber: originalLevel.levelNumber,
      gridSize: originalLevel.gridSize,
      availableNumbers: [1, 2, 3, 4, 5, 6, 7, 8, 9],
      description: originalLevel.description,
      timeLimit: originalLevel.timeLimit,
      targetMatches: originalLevel.targetMatches,
    );
  }

  // Optimized cell selection with debouncing
  MatchResult selectCell(int row, int col) {
    final now = DateTime.now();
    if (now.difference(_lastClickTime) < _clickDebounceTime) {
      return MatchResult.invalid; // Debounce rapid clicks
    }
    _lastClickTime = now;

    if (_status != GameStatus.playing || _isAnimating) {
      return MatchResult.invalid;
    }

    // Bounds checking
    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) {
      return MatchResult.invalid;
    }

    final cell = _grid[row][col];

    if (cell.isMatched) {
      return MatchResult.alreadyMatched;
    }

    if (_selectedCell == null) {
      _selectCell(cell);
      return MatchResult.valid;
    }

    if (_selectedCell == cell) {
      _deselectCell();
      return MatchResult.valid;
    }

    return _tryMatch(_selectedCell!, cell);
  }

  void _selectCell(Cell cell) {
    _suppressNotifications = true;

    _grid[cell.row][cell.col] = cell.copyWith(state: CellState.selected);
    _selectedCell = _grid[cell.row][cell.col];
    _currentPath = [];

    _suppressNotifications = false;
    notifyListeners();
  }

  void _deselectCell() {
    if (_selectedCell != null) {
      _suppressNotifications = true;

      _grid[_selectedCell!.row][_selectedCell!.col] =
          _selectedCell!.copyWith(state: CellState.normal);
      _selectedCell = null;
      _currentPath = [];

      _suppressNotifications = false;
      notifyListeners();
    }
  }

  MatchResult _tryMatch(Cell cell1, Cell cell2) {
    _suppressNotifications = true;
    _isAnimating = true;

    // Quick validation before expensive path checking
    if (!GameController.canMatch(cell1.value, cell2.value)) {
      _lastMessage = 'Numbers don\'t match!';
      _suppressNotifications = false;

      Future.delayed(const Duration(milliseconds: 300), () {
        _isAnimating = false;
        _deselectCell();
      });

      notifyListeners();
      return MatchResult.invalid;
    }

    // Check path connectivity
    if (!GameController.hasValidPath(cell1, cell2, _grid)) {
      _lastMessage = 'No valid path!';
      _suppressNotifications = false;

      Future.delayed(const Duration(milliseconds: 300), () {
        _isAnimating = false;
        _deselectCell();
      });

      notifyListeners();
      return MatchResult.noPath;
    }

    // Get and show the path
    final path = GameController.getPath(cell1, cell2, _grid);
    if (path != null) {
      _currentPath = path;
    }

    _performMatch(cell1, cell2);
    _lastMessage = 'Great match!';

    _suppressNotifications = false;
    notifyListeners();

    // Clear animation state after delay
    Future.delayed(const Duration(milliseconds: 600), () {
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
    final points = _calculateScore(cell1.value, cell2.value);
    addScore(points);

    // Clear cache when grid changes
    GameController.clearCache();
  }

  int _calculateScore(int value1, int value2) {
    int baseScore = 10;

    // Bonus for sum-to-10 matches
    if (value1 + value2 == 10) {
      baseScore += 5;
    }

    // Bonus for equal matches with higher numbers
    if (value1 == value2) {
      baseScore += value1;
    }

    // Time bonus for quick matches
    if (_timeRemaining > _currentLevel.timeLimit * 0.75) {
      baseScore += 3;
    } else if (_timeRemaining > _currentLevel.timeLimit * 0.5) {
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

  // Optimized timer with reduced notifications
  void decrementTime() {
    if (_status == GameStatus.playing && _timeRemaining > 0) {
      _timeRemaining--;

      if (_timeRemaining == 0) {
        _status = GameStatus.timeUp;
        _lastMessage = 'Time\'s up!';
        notifyListeners();
      } else {
        // Only notify every 5 seconds or when time is critical
        if (_timeRemaining % 5 == 0 || _timeRemaining <= 30) {
          _scheduleNotification();
        }
      }
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
    _suppressNotifications = true;

    GameController.clearCache();
    _grid = LevelGenerator.generateOptimalGrid(_createLimitedLevel(_currentLevel));
    _score = 0;
    _matchCount = 0;
    _timeRemaining = _currentLevel.timeLimit;
    _status = GameStatus.playing;
    _selectedCell = null;
    _currentPath = [];
    _isAnimating = false;
    _lastMessage = '';

    _suppressNotifications = false;
    notifyListeners();
  }

  void nextLevel() {
    if (_currentLevel.levelNumber < Level.allLevels.length) {
      final nextLevel = Level.getLevelByNumber(_currentLevel.levelNumber + 1);
      initializeGame(nextLevel);
    }
  }

  void resetGame() {
    initializeGame(Level.level1);
  }

  // Optimized formatted time (cached result)
  String? _cachedFormattedTime;
  int _lastFormattedTimeValue = -1;

  String get formattedTime {
    if (_timeRemaining != _lastFormattedTimeValue) {
      final minutes = _timeRemaining ~/ 60;
      final seconds = _timeRemaining % 60;
      _cachedFormattedTime = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      _lastFormattedTimeValue = _timeRemaining;
    }
    return _cachedFormattedTime!;
  }

  // Cached match availability check
  bool? _cachedHasMatches;
  int _lastMatchCheckHash = 0;

  bool hasAvailableMatches() {
    // Create a simple hash of the grid state
    int currentHash = 0;
    for (final row in _grid) {
      for (final cell in row) {
        if (!cell.isMatched) {
          currentHash ^= (cell.row * 1000 + cell.col * 100 + cell.value);
        }
      }
    }

    if (currentHash != _lastMatchCheckHash || _cachedHasMatches == null) {
      _cachedHasMatches = GameController.getAllPossibleMatches(_grid).isNotEmpty;
      _lastMatchCheckHash = currentHash;
    }

    return _cachedHasMatches!;
  }

  MatchPair? getHint() {
    return GameController.getHint(_grid);
  }

  // Optimized shuffle with reduced notifications
  void shuffleGrid() {
    if (_status != GameStatus.playing) return;

    _suppressNotifications = true;

    GameController.clearCache();
    final availableCells = <Cell>[];
    final values = <int>[];

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (!_grid[i][j].isMatched) {
          availableCells.add(_grid[i][j]);
          values.add(_grid[i][j].value);
        }
      }
    }

    values.shuffle();

    for (int i = 0; i < availableCells.length; i++) {
      final cell = availableCells[i];
      _grid[cell.row][cell.col] = cell.copyWith(value: values[i]);
    }

    _selectedCell = null;
    _currentPath = [];
    _lastMessage = 'Grid shuffled!';
    _cachedHasMatches = null; // Reset cache

    _suppressNotifications = false;
    notifyListeners();
  }

  void removeNumber(int number) {
    if (_status != GameStatus.playing) return;

    _suppressNotifications = true;

    int removed = 0;
    for (int i = 0; i < gridSize && removed < 2; i++) {
      for (int j = 0; j < gridSize && removed < 2; j++) {
        if (!_grid[i][j].isMatched && _grid[i][j].value == number) {
          _grid[i][j] = _grid[i][j].copyWith(state: CellState.matched);
          removed++;
        }
      }
    }

    if (removed > 0) {
      _score += removed * 5;
      _lastMessage = 'Removed $removed cells with number $number!';
      GameController.clearCache();
      _cachedHasMatches = null;
    } else {
      _lastMessage = 'No cells found with number $number';
    }

    _selectedCell = null;
    _currentPath = [];

    _suppressNotifications = false;
    notifyListeners();
  }

  void addTimeBonus(int seconds) {
    if (_status == GameStatus.playing) {
      _timeRemaining += seconds;
      _lastMessage = 'Added $seconds seconds!';
      notifyListeners();
    }
  }

  // Optimized path preview with throttling
  DateTime _lastPreviewTime = DateTime.now();
  static const Duration _previewThrottleTime = Duration(milliseconds: 50);

  void previewPath(int row, int col) {
    final now = DateTime.now();
    if (now.difference(_lastPreviewTime) < _previewThrottleTime) {
      return; // Throttle preview updates
    }
    _lastPreviewTime = now;

    if (_selectedCell == null || _status != GameStatus.playing) {
      if (_currentPath.isNotEmpty) {
        _currentPath = [];
        notifyListeners();
      }
      return;
    }

    // Bounds checking
    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) {
      return;
    }

    final targetCell = _grid[row][col];
    if (targetCell.isMatched || targetCell == _selectedCell) {
      if (_currentPath.isNotEmpty) {
        _currentPath = [];
        notifyListeners();
      }
      return;
    }

    final newPath = GameController.canCellsMatch(_selectedCell!, targetCell, _grid)
        ? (GameController.getPath(_selectedCell!, targetCell, _grid) ?? [])
        : <Cell>[];

    if (newPath != _currentPath) {
      _currentPath = newPath;
      notifyListeners();
    }
  }

  void clearPathPreview() {
    if (_currentPath.isNotEmpty) {
      _currentPath = [];
      notifyListeners();
    }
  }

  // Optimized statistics calculation
  GameStatistics getStatistics() {
    final totalCells = gridSize * gridSize;
    final matchedCells = _grid.expand((row) => row).where((cell) => cell.isMatched).length;
    final remainingCells = totalCells - matchedCells;
    final possibleMatches = hasAvailableMatches() ? GameController.getAllPossibleMatches(_grid).length : 0;

    return GameStatistics(
      level: _currentLevel.levelNumber,
      score: _score,
      matchCount: _matchCount,
      targetMatches: _currentLevel.targetMatches,
      timeRemaining: _timeRemaining,
      totalTime: _currentLevel.timeLimit,
      remainingCells: remainingCells,
      possibleMatches: possibleMatches,
      isComplete: isLevelComplete,
    );
  }

  void showAutoHint() {
    if (_status != GameStatus.playing) return;

    final hint = getHint();
    if (hint != null) {
      _currentPath = GameController.getPath(hint.cell1, hint.cell2, _grid) ?? [];
      _lastMessage = 'Hint: Try these cells! 💡';

      Future.delayed(const Duration(seconds: 3), () {
        if (_currentPath.isNotEmpty) {
          _currentPath = [];
          notifyListeners();
        }
      });

      notifyListeners();
    }
  }


  bool canMatchCells(int row1, int col1, int row2, int col2) {
    if (row1 < 0 || row1 >= gridSize || col1 < 0 || col1 >= gridSize ||
        row2 < 0 || row2 >= gridSize || col2 < 0 || col2 >= gridSize) {
      return false;
    }

    final cell1 = _grid[row1][col1];
    final cell2 = _grid[row2][col2];

    return GameController.canCellsMatch(cell1, cell2, _grid);
  }

  // Cached available numbers
  Set<int>? _cachedAvailableNumbers;
  int _lastNumberCheckHash = 0;

  Set<int> getAvailableNumbers() {
    int currentHash = 0;
    for (final row in _grid) {
      for (final cell in row) {
        if (!cell.isMatched) {
          currentHash ^= (cell.row * 100 + cell.col * 10 + cell.value);
        }
      }
    }

    if (currentHash != _lastNumberCheckHash || _cachedAvailableNumbers == null) {
      final numbers = <int>{};
      for (final row in _grid) {
        for (final cell in row) {
          if (!cell.isMatched) {
            numbers.add(cell.value);
          }
        }
      }
      _cachedAvailableNumbers = numbers;
      _lastNumberCheckHash = currentHash;
    }

    return _cachedAvailableNumbers!;
  }

  double get completionPercentage {
    return (_matchCount / _currentLevel.targetMatches).clamp(0.0, 1.0);
  }

  TimePressure get timePressure {
    final ratio = _timeRemaining / _currentLevel.timeLimit;
    if (ratio > 0.5) return TimePressure.low;
    if (ratio > 0.25) return TimePressure.medium;
    return TimePressure.high;
  }

  @override
  void dispose() {
    GameController.clearCache();
    super.dispose();
  }
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