/// Game configuration constants for Blockster.
/// 
/// This file centralizes all magic numbers and configuration values
/// used throughout the game for easy maintenance and tuning.
abstract class GameConstants {
  // Grid dimensions
  static const int gridSize = 10;
  static const double cellSize = 40.0;
  static const double gridPixelSize = gridSize * cellSize; // 400.0

  // Scoring
  static const int pointsPerLine = 10;
  static const int comboMultiplier = 2;
  static const int comboActiveMoves = 10;

  // Blocks
  static const int blocksPerRound = 3;
  static const double blockContainerSize = 80.0;
  static const double nextBlockPreviewSize = 60.0;

  // Leaderboard
  static const int topScoresCount = 10;
  static const int maxNameLength = 3;

  // UI/Timing
  static const Duration confettiDuration = Duration(seconds: 2);
  static const int confettiParticleCount = 30;
  static const Duration menuGradientDuration = Duration(seconds: 6);
  static const Duration gameOverDelay = Duration(milliseconds: 500);

  // Haptic feedback
  static const int blockPlacedVibrationDuration = 50; // milliseconds
  static const int lineClearedVibrationDuration = 100;
  static const int gameOverVibrationDuration = 200;
}
