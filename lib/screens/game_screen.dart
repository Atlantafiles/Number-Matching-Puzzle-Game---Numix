import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/level.dart';
import '../services/game_controller.dart';
import '../widgets/game_grid.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameController _gameController;
  late AnimationController _headerAnimationController;
  late Animation<Offset> _headerSlideAnimation;

  // Cache formatted numbers to avoid repeated string operations
  final Map<int, String> _formattedNumberCache = {};

  @override
  void initState() {
    super.initState();
    _gameController = GameController();

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.elasticOut,
    ));

    _headerAnimationController.forward();

    // Initialize game efficiently
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameState = Provider.of<GameState>(context, listen: false);
      gameState.checkAndUpdateBestScore();
      gameState.initializeGame(Level.level1);
      _gameController.startTimer(gameState);
    });
  }

  @override
  void dispose() {
    _gameController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  // Cached time formatting
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatNumber(int number) {
    return _formattedNumberCache.putIfAbsent(
      number,
          () => number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
      ),
    );
  }

  void _showGameOverDialog(GameState gameState) {
    // Prevent multiple dialogs
    if (ModalRoute.of(context)?.isCurrent != true) return;

    gameState.checkAndUpdateBestScore();

    final isGameComplete = gameState.status == GameStatus.won &&
        gameState.currentLevel.levelNumber >= 3;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          isGameComplete
              ? '🎊 CONGRATULATIONS! 🎊'
              : gameState.status == GameStatus.won
              ? '🎉 Level Complete!'
              : '⏰ Time\'s Up!',
          style: TextStyle(
            fontSize: isGameComplete ? 22 : 24,
            fontWeight: FontWeight.bold,
            color: isGameComplete ? Colors.purple[700] : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGameComplete) ...[
              const Text(
                'You have successfully completed all levels!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '🏆 Final Score: ${_formatNumber(gameState.score)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Total Matches: ${gameState.matchCount}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text(
                'Score: ${_formatNumber(gameState.score)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Matches: ${gameState.matchCount}/${gameState.currentLevel.targetMatches}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (isGameComplete) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                gameState.initializeGame(Level.level1);
                _gameController.startTimer(gameState);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[600]!, Colors.purple[800]!],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  'Start Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ] else ...[
            if (gameState.status == GameStatus.won && gameState.currentLevel.levelNumber < 3)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  gameState.nextLevel();
                  _gameController.startTimer(gameState);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4834D4),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Text(
                    'Next Level',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                gameState.restartLevel();
                _gameController.startTimer(gameState);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Consumer<GameState>(
          builder: (context, gameState, child) {
            // Show dialog when game ends (with protection against multiple calls)
            if ((gameState.status == GameStatus.won || gameState.status == GameStatus.timeUp) &&
                ModalRoute.of(context)?.isCurrent == true) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showGameOverDialog(gameState);
              });
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header with game stats - use Selector for specific parts
                  SlideTransition(
                    position: _headerSlideAnimation,
                    child: _buildOptimizedHeader(gameState),
                  ),

                  const SizedBox(height: 30),

                  // Main game grid
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 400,
                          maxHeight: 400,
                        ),
                        child: const GameGrid(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Bottom controls
                  _buildBottomControls(gameState),

                  const SizedBox(height: 20),

                  // Best score - separate selector to avoid unnecessary rebuilds
                  _buildOptimizedBestScore(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOptimizedHeader(GameState gameState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Level - rarely changes
        _LevelDisplay(level: gameState.currentLevel.levelNumber),

        // Timer - changes frequently, needs optimization
        _TimerDisplay(
          timeRemaining: gameState.timeRemaining,
          formatTime: _formatTime,
        ),

        // Score - changes on matches
        _ScoreDisplay(
          score: gameState.score,
          formatNumber: _formatNumber,
        ),
      ],
    );
  }

  Widget _buildBottomControls(GameState gameState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          label: 'New Game',
          icon: Icons.refresh,
          color: const Color(0xFF4834D4),
          onPressed: gameState.isAnimating ? null : () {
            gameState.restartLevel();
            _gameController.startTimer(gameState);
          },
        ),
        _buildControlButton(
          label: 'Hint',
          icon: Icons.lightbulb_outline,
          color: Colors.orange[600]!,
          onPressed: gameState.isAnimating ? null : () {
            gameState.showAutoHint();
          },
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            disabledBackgroundColor: Colors.grey[400],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptimizedBestScore() {
    return Selector<GameState, int>(
      selector: (context, gameState) => gameState.bestScore,
      builder: (context, bestScore, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              color: Colors.orange[400],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Best Score: ${_formatNumber(bestScore)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        );
      },
    );
  }
}

// Optimized widgets to prevent unnecessary rebuilds
class _LevelDisplay extends StatelessWidget {
  final int level;

  const _LevelDisplay({required this.level});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LEVEL',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
            letterSpacing: 1,
          ),
        ),
        Text(
          '$level',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  final int timeRemaining;
  final String Function(int) formatTime;

  const _TimerDisplay({
    required this.timeRemaining,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final isLowTime = timeRemaining <= 30;

    return Column(
      children: [
        const Text(
          'TIMER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
            letterSpacing: 1,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isLowTime ? Colors.red[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLowTime ? Colors.red[300]! : Colors.grey[300]!,
            ),
          ),
          child: Text(
            formatTime(timeRemaining),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: isLowTime ? Colors.red[700] : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  final int score;
  final String Function(int) formatNumber;

  const _ScoreDisplay({
    required this.score,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'SCORE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
            letterSpacing: 1,
          ),
        ),
        Text(
          formatNumber(score),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}