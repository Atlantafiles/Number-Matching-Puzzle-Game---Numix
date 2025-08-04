import 'package:flutter/material.dart';

class GameConstants {
  // Game Configuration
  static const int maxLevels = 3;
  static const int defaultTimeLimit = 120; // 2 minutes in seconds
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration invalidMatchDuration = Duration(milliseconds: 500);
  static const Duration matchSuccessDuration = Duration(milliseconds: 200);
  static const Duration pathAnimationDuration = Duration(milliseconds: 800);

  // Number constraints (1-9 only)
  static const List<int> allowedNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];
  static const int minNumber = 1;
  static const int maxNumber = 9;

  // Path-based matching settings
  static const int maxPathTurns = 2; // Maximum turns allowed in path
  static const double pathLineWidth = 3.0;
  static const Duration pathPreviewDelay = Duration(milliseconds: 200);

  // Scoring
  static const int baseMatchScore = 10;
  static const int sumToTenBonus = 5;
  static const int timeRemainingBonus = 1; // per second remaining
  static const int levelCompletionBonus = 100;
  static const int pathComplexityBonus = 2; // bonus for L-shaped and U-shaped paths

  // Grid Configuration
  static const double cellPadding = 4.0;
  static const double cellBorderRadius = 8.0;
  static const double cellSize = 60.0;
  static const double gridSpacing = 8.0;

  // Animation Settings
  static const double shakeAmount = 5.0;
  static const int shakeCount = 3;
  static const double pulseScale = 1.1;
  static const Duration pulseDelay = Duration(milliseconds: 100);

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color errorColor = Color(0xFFCF6679);
  static const Color successColor = Color(0xFF4CAF50);

  // Cell Colors
  static const Color normalCellColor = Color(0xFF2C2C2C);
  static const Color selectedCellColor = Color(0xFF2196F3);
  static const Color matchedCellColor = Color(0xFF424242);
  static const Color hintCellColor = Color(0xFFFF9800);

  // Path Colors
  static const Color pathColor = Color(0xFF4CAF50);
  static const Color pathPreviewColor = Color(0x804CAF50);
  static const Color invalidPathColor = Color(0xFFCF6679);

  // Text Colors
  static const Color primaryTextColor = Color(0xFFFFFFFF);
  static const Color secondaryTextColor = Color(0xFFB0BEC5);
  static const Color matchedTextColor = Color(0xFF757575);

  // Typography
  static const double cellTextSize = 20.0;
  static const double titleTextSize = 24.0;
  static const double bodyTextSize = 16.0;
  static const double captionTextSize = 12.0;

  static const FontWeight boldWeight = FontWeight.w700;
  static const FontWeight normalWeight = FontWeight.w400;

  // Layout
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(12.0);
  static const double cardElevation = 4.0;
  static const double buttonHeight = 48.0;

  // Game Messages
  static const String gameTitle = 'Number Puzzle';
  static const String levelCompleteMessage = 'Level Complete! 🎉';
  static const String timeUpMessage = 'Time\'s Up! ⏰';
  static const String gameOverMessage = 'Game Over';
  static const String greatMatchMessage = 'Great Match! ✨';
  static const String invalidMatchMessage = 'Try Again! ❌';
  static const String noPathMessage = 'No Valid Path! 🚫';
  static const String hintMessage = 'Hint: Try these cells! 💡';
  static const String noMatchesMessage = 'No more matches available';
  static const String pausedMessage = 'Game Paused';

  // Path-specific messages
  static const String directPathMessage = 'Direct Path! 🎯';
  static const String lShapedPathMessage = 'L-Shaped Path! 📐';
  static const String uShapedPathMessage = 'U-Shaped Path! 🔄';

  // Button Labels
  static const String playButtonLabel = 'Play';
  static const String pauseButtonLabel = 'Pause';
  static const String resumeButtonLabel = 'Resume';
  static const String restartButtonLabel = 'Restart';
  static const String nextLevelButtonLabel = 'Next Level';
  static const String hintButtonLabel = 'Hint';
  static const String menuButtonLabel = 'Menu';
  static const String settingsButtonLabel = 'Settings';
  static const String shuffleButtonLabel = 'Shuffle';

  // Level Descriptions
  static const Map<int, String> levelDescriptions = {
    1: 'Match numbers that are equal or sum to 10. Path must be clear!',
    2: 'More numbers, same rules - find the connecting paths!',
    3: 'Master level - complex paths await your skills!',
  };

  // Achievement Thresholds
  static const int speedBonusThreshold = 90; // Complete level in 90 seconds
  static const int perfectScoreMultiplier = 2;
  static const int comboThreshold = 3; // 3 consecutive matches for combo

  // Path complexity scoring
  static const Map<String, int> pathComplexityScores = {
    'direct': 1,
    'lshaped': 2,
    'ushaped': 3,
  };

  // Sound and Haptic Feedback Settings
  static const bool defaultSoundEnabled = true;
  static const bool defaultHapticEnabled = true;
  static const bool defaultAnimationsEnabled = true;
  static const bool defaultPathAnimationEnabled = true;

  // Debug Settings
  static const bool debugMode = false;
  static const bool showGridCoordinates = false;
  static const bool showMatchHints = false;
  static const bool showPathDebugInfo = false;

  // Preferences Keys
  static const String soundEnabledKey = 'sound_enabled';
  static const String hapticEnabledKey = 'haptic_enabled';
  static const String animationsEnabledKey = 'animations_enabled';
  static const String pathAnimationEnabledKey = 'path_animation_enabled';
  static const String highScoreKey = 'high_score';
  static const String currentLevelKey = 'current_level';
  static const String totalPlayTimeKey = 'total_play_time';

  // Validation
  static const int minGridSize = 3;
  static const int maxGridSize = 8;
  static const int minTargetMatches = 1;
  static const int minTimeLimit = 30;
  static const int maxTimeLimit = 600; // 10 minutes

  // Path validation settings
  static const int maxPathLength = 20; // Maximum cells in a path
  static const double pathTolerance = 0.1; // Tolerance for path calculations
}

class GameTextStyles {
  static const TextStyle cellText = TextStyle(
    color: GameConstants.primaryTextColor,
    fontSize: GameConstants.cellTextSize,
    fontWeight: GameConstants.boldWeight,
  );

  static const TextStyle cellTextMatched = TextStyle(
    color: GameConstants.matchedTextColor,
    fontSize: GameConstants.cellTextSize,
    fontWeight: GameConstants.normalWeight,
  );

  static const TextStyle titleText = TextStyle(
    color: GameConstants.primaryTextColor,
    fontSize: GameConstants.titleTextSize,
    fontWeight: GameConstants.boldWeight,
  );

  static const TextStyle bodyText = TextStyle(
    color: GameConstants.primaryTextColor,
    fontSize: GameConstants.bodyTextSize,
    fontWeight: GameConstants.normalWeight,
  );

  static const TextStyle secondaryText = TextStyle(
    color: GameConstants.secondaryTextColor,
    fontSize: GameConstants.bodyTextSize,
    fontWeight: GameConstants.normalWeight,
  );

  static const TextStyle captionText = TextStyle(
    color: GameConstants.secondaryTextColor,
    fontSize: GameConstants.captionTextSize,
    fontWeight: GameConstants.normalWeight,
  );

  static const TextStyle timerText = TextStyle(
    color: GameConstants.primaryTextColor,
    fontSize: 18.0,
    fontWeight: GameConstants.boldWeight,
    fontFamily: 'monospace',
  );

  static const TextStyle scoreText = TextStyle(
    color: GameConstants.successColor,
    fontSize: 16.0,
    fontWeight: GameConstants.boldWeight,
  );

  static const TextStyle pathInfoText = TextStyle(
    color: GameConstants.pathColor,
    fontSize: 14.0,
    fontWeight: GameConstants.boldWeight,
  );
}

class GameDecorations {
  static BoxDecoration cellDecoration(CellState state) {
    Color color;
    double elevation = 2.0;

    switch (state) {
      case CellState.normal:
        color = GameConstants.normalCellColor;
        break;
      case CellState.selected:
        color = GameConstants.selectedCellColor;
        elevation = 4.0;
        break;
      case CellState.matched:
        color = GameConstants.matchedCellColor;
        elevation = 0.5;
        break;
    }

    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(GameConstants.cellBorderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: elevation,
          offset: Offset(0, elevation / 2),
        ),
      ],
    );
  }

  static BoxDecoration cellDecorationWithPath(CellState state, bool isInPath) {
    final baseDecoration = cellDecoration(state);

    if (isInPath) {
      return baseDecoration.copyWith(
        border: Border.all(
          color: GameConstants.pathColor,
          width: 2.0,
        ),
      );
    }

    return baseDecoration;
  }

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: GameConstants.surfaceColor,
    borderRadius: BorderRadius.circular(12.0),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: GameConstants.cardElevation,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration get backgroundDecoration => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1A1A1A),
        Color(0xFF0A0A0A),
      ],
    ),
  );

  // Path line decoration
  static Paint get pathPaint => Paint()
    ..color = GameConstants.pathColor
    ..strokeWidth = GameConstants.pathLineWidth
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static Paint get pathPreviewPaint => Paint()
    ..color = GameConstants.pathPreviewColor
    ..strokeWidth = GameConstants.pathLineWidth
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
}

// Enum definitions that might be used across the app
enum CellState { normal, selected, matched }
enum GameDifficulty { easy, medium, hard, expert }
enum MatchType { equal, sumToTen }
enum PathType { direct, lShaped, uShaped }
enum GameEvent { cellSelected, matchFound, matchFailed, levelComplete, timeUp, pathFound }

// Extension methods for enums
extension CellStateExtension on CellState {
  bool get isInteractable => this != CellState.matched;
  bool get isHighlighted => this == CellState.selected;
}

extension PathTypeExtension on PathType {
  String get displayName {
    switch (this) {
      case PathType.direct:
        return 'Direct';
      case PathType.lShaped:
        return 'L-Shaped';
      case PathType.uShaped:
        return 'U-Shaped';
    }
  }

  String get message {
    switch (this) {
      case PathType.direct:
        return GameConstants.directPathMessage;
      case PathType.lShaped:
        return GameConstants.lShapedPathMessage;
      case PathType.uShaped:
        return GameConstants.uShapedPathMessage;
    }
  }

  int get complexityScore => GameConstants.pathComplexityScores[name] ?? 1;
}

extension GameEventExtension on GameEvent {
  String get message {
    switch (this) {
      case GameEvent.cellSelected:
        return 'Cell selected';
      case GameEvent.matchFound:
        return GameConstants.greatMatchMessage;
      case GameEvent.matchFailed:
        return GameConstants.invalidMatchMessage;
      case GameEvent.levelComplete:
        return GameConstants.levelCompleteMessage;
      case GameEvent.timeUp:
        return GameConstants.timeUpMessage;
      case GameEvent.pathFound:
        return 'Path found!';
    }
  }
}

// Helper class for path information
class PathInfo {
  final PathType type;
  final List<CellState> cells;
  final double length;

  PathInfo({
    required this.type,
    required this.cells,
    required this.length,
  });

  int get complexityScore => type.complexityScore;
  String get displayMessage => type.message;
}

// Game statistics helper
class MatchStatistics {
  final int totalMatches;
  final int equalMatches;
  final int sumToTenMatches;
  final int directPaths;
  final int lShapedPaths;
  final int uShapedPaths;

  MatchStatistics({
    required this.totalMatches,
    required this.equalMatches,
    required this.sumToTenMatches,
    required this.directPaths,
    required this.lShapedPaths,
    required this.uShapedPaths,
  });

  double get equalMatchRatio => totalMatches > 0 ? equalMatches / totalMatches : 0.0;
  double get sumMatchRatio => totalMatches > 0 ? sumToTenMatches / totalMatches : 0.0;
  double get directPathRatio => totalMatches > 0 ? directPaths / totalMatches : 0.0;
  double get complexPathRatio => totalMatches > 0 ? (lShapedPaths + uShapedPaths) / totalMatches : 0.0;
}