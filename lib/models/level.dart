class Level {
  final int levelNumber;
  final int gridSize;
  final List<int> availableNumbers;
  final String description;
  final int timeLimit; // in seconds
  final int targetMatches; // minimum matches to complete level

  const Level({
    required this.levelNumber,
    required this.gridSize,
    required this.availableNumbers,
    required this.description,
    this.timeLimit = 120, // default 2 minutes
    required this.targetMatches,
  });

  // Predefined levels
  static const Level level1 = Level(
    levelNumber: 1,
    gridSize: 4,
    availableNumbers: [1, 2, 3, 4, 5, 6, 7, 8, 9],
    description: "Basic 4x4 grid with simple numbers",
    targetMatches: 6, // Need at least 6 matches to win
  );

  static const Level level2 = Level(
    levelNumber: 2,
    gridSize: 5,
    availableNumbers: [1, 2, 3, 4, 5, 6, 7, 8, 9],
    description: "Intermediate 5x5 grid with more numbers",
    targetMatches: 10,
  );

  static const Level level3 = Level(
    levelNumber: 3,
    gridSize: 6,
    availableNumbers: [1, 2, 3, 4, 5, 6, 7, 8, 9],
    description: "Advanced 6x6 grid with complex patterns",
    targetMatches: 15,
  );

  static const List<Level> allLevels = [level1, level2, level3];

  static Level getLevelByNumber(int levelNumber) {
    return allLevels.firstWhere(
          (level) => level.levelNumber == levelNumber,
      orElse: () => level1,
    );
  }
}