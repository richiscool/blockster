import 'dart:math';
import 'package:blockster/models/block_doc.dart';
import 'package:blockster/constants/game_constants.dart';

/// Manages the complete game state and logic for Blockster.
///
/// Handles the 10×10 grid, block placement, line clearing, scoring,
/// combo detection, and game-over conditions. All game rules are
/// implemented here.
class GameState {
  /// The 10×10 play grid.
  ///
  /// 0 = empty cell, 1 = occupied cell.
  /// Access as: grid[y][x]
  late List<List<int>> grid;

  /// The 3 blocks currently available for placement.
  late List<Block> currentBlocks;

  /// The 3 blocks that will become [currentBlocks] after the next placement.
  late List<Block> nextBlocks;

  /// Total points earned this game.
  int score = 0;

  /// Total number of block placements made.
  int moves = 0;

  /// Whether the 2× combo multiplier is currently active.
  ///
  /// Activated by clearing rows AND columns simultaneously.
  /// Remains active for [GameConstants.comboActiveMoves] placements.
  bool isDoublePointsActive = false;

  /// Remaining placements while combo is active.
  ///
  /// Decremented after each placement. When it reaches 0,
  /// [isDoublePointsActive] is set to false.
  int doublePointsMovesRemaining = 0;

  /// Whether the game has ended (no valid placement exists).
  bool gameOver = false;

  /// Creates a new GameState and initializes the game.
  ///
  /// Sets up a fresh 10×10 grid and generates initial blocks.
  GameState() {
    initializeGame();
  }

  /// Resets the game to its initial state.
  ///
  /// Clears the grid, resets score/moves, deactivates combo,
  /// generates new blocks, and marks game as active.
  void initializeGame() {
    grid = List.generate(
      GameConstants.gridSize,
      (_) => List.generate(GameConstants.gridSize, (_) => 0),
    );
    currentBlocks = [];
    nextBlocks = [];
    score = 0;
    moves = 0;
    isDoublePointsActive = false;
    doublePointsMovesRemaining = 0;
    gameOver = false;

    generateNewBlocks();
    generateNextBlocks();
  }

  /// Generates 3 random blocks for [currentBlocks].
  ///
  /// Each block type has equal probability. Called at game start
  /// and after each block placement.
  void generateNewBlocks() {
    currentBlocks = [];
    for (int i = 0; i < GameConstants.blocksPerRound; i++) {
      BlockType randomType =
          BlockType.values[Random().nextInt(BlockType.values.length)];
      currentBlocks.add(Block.createBlock(randomType));
    }
  }

  /// Generates 3 random blocks for [nextBlocks].
  ///
  /// Called after [generateNewBlocks] at startup and after each
  /// block placement to preview upcoming blocks.
  void generateNextBlocks() {
    nextBlocks = [];
    for (int i = 0; i < GameConstants.blocksPerRound; i++) {
      BlockType randomType =
          BlockType.values[Random().nextInt(BlockType.values.length)];
      nextBlocks.add(Block.createBlock(randomType));
    }
  }

  /// Checks if a block can be placed at the given grid position.
  ///
  /// Validates:
  ///   - All occupied cells are within grid bounds (0-9)
  ///   - No occupied cells collide with existing blocks
  ///
  /// Parameters:
  ///   - [block]: The block to check
  ///   - [x]: Grid X position (0-9)
  ///   - [y]: Grid Y position (0-9)
  ///
  /// Returns: true if placement is valid, false otherwise
  bool canPlaceBlock(Block block, int x, int y) {
    List<(int, int)> cells = block.getOccupiedCells();

    for (var (cellX, cellY) in cells) {
      int gridX = x + cellX;
      int gridY = y + cellY;

      // Check bounds
      if (gridX < 0 ||
          gridX >= GameConstants.gridSize ||
          gridY < 0 ||
          gridY >= GameConstants.gridSize) {
        return false;
      }

      // Check collision
      if (grid[gridY][gridX] != 0) {
        return false;
      }
    }

    return true;
  }

  /// Attempts to place a block on the grid at the given position.
  ///
  /// If placement succeeds:
  ///   1. Marks cells as occupied
  ///   2. Increments move counter
  ///   3. Updates combo state
  ///   4. Detects and clears full rows/columns
  ///   5. Replaces [currentBlocks] with [nextBlocks]
  ///   6. Generates new [nextBlocks]
  ///   7. Checks for game-over condition
  ///
  /// Parameters:
  ///   - [block]: The block to place
  ///   - [x]: Grid X position (0-9)
  ///   - [y]: Grid Y position (0-9)
  ///
  /// Returns: true if placement succeeded, false if invalid position
  bool placeBlock(Block block, int x, int y) {
    if (!canPlaceBlock(block, x, y)) {
      return false;
    }

    // Mark occupied cells
    List<(int, int)> cells = block.getOccupiedCells();
    for (var (cellX, cellY) in cells) {
      int gridX = x + cellX;
      int gridY = y + cellY;
      grid[gridY][gridX] = 1;
    }

    // Update move counter and combo state
    moves++;
    if (isDoublePointsActive) {
      doublePointsMovesRemaining--;
      if (doublePointsMovesRemaining == 0) {
        isDoublePointsActive = false;
      }
    }

    // Clear completed lines and score points
    clearLines();

    // Replace current blocks with next blocks and generate new ones
    currentBlocks = nextBlocks;
    generateNextBlocks();

    // Check if game is over
    if (!canPlaceAnyBlock()) {
      gameOver = true;
    }

    return true;
  }

  /// Detects and clears full rows and columns.
  ///
  /// When rows or columns are cleared:
  ///   - Cells are reset to 0
  ///   - Each cleared line awards [GameConstants.pointsPerLine] points
  ///   - Clearing both rows AND columns triggers a combo
  ///   - Combo: doubles points and activates 2× multiplier for [GameConstants.comboActiveMoves] moves
  ///
  /// If combo is already active, points earned are doubled.
  /// Called automatically by [placeBlock].
  void clearLines() {
    Set<int> rowsToClear = {};
    Set<int> columnsToClear = {};

    // Check rows for completeness
    for (int y = 0; y < GameConstants.gridSize; y++) {
      bool rowFull = true;
      for (int x = 0; x < GameConstants.gridSize; x++) {
        if (grid[y][x] == 0) {
          rowFull = false;
          break;
        }
      }
      if (rowFull) {
        rowsToClear.add(y);
      }
    }

    // Check columns for completeness
    for (int x = 0; x < GameConstants.gridSize; x++) {
      bool colFull = true;
      for (int y = 0; y < GameConstants.gridSize; y++) {
        if (grid[y][x] == 0) {
          colFull = false;
          break;
        }
      }
      if (colFull) {
        columnsToClear.add(x);
      }
    }

    // Clear cells and calculate score
    if (rowsToClear.isNotEmpty || columnsToClear.isNotEmpty) {
      // Check for combo (rows AND columns cleared simultaneously)
      bool isCombo = rowsToClear.isNotEmpty && columnsToClear.isNotEmpty;

      // Zero out all cleared cells
      for (int y = 0; y < GameConstants.gridSize; y++) {
        for (int x = 0; x < GameConstants.gridSize; x++) {
          if (rowsToClear.contains(y) || columnsToClear.contains(x)) {
            grid[y][x] = 0;
          }
        }
      }

      // Calculate points: base is lines cleared × pointsPerLine
      int pointsEarned = (rowsToClear.length + columnsToClear.length) *
          GameConstants.pointsPerLine;

      // Combo: double points and activate 2× for next comboActiveMoves placements
      if (isCombo) {
        pointsEarned *= GameConstants.comboMultiplier;
        isDoublePointsActive = true;
        doublePointsMovesRemaining = GameConstants.comboActiveMoves;
      }

      // If combo already active, double points again
      if (isDoublePointsActive && !isCombo) {
        pointsEarned *= GameConstants.comboMultiplier;
      }

      score += pointsEarned;
    }
  }

  /// Checks whether any block in [currentBlocks] can be placed anywhere on the grid.
  ///
  /// Returns: true if at least one valid placement exists, false otherwise
  ///
  /// When this returns false, the game is over.
  bool canPlaceAnyBlock() {
    for (var block in currentBlocks) {
      for (int y = 0; y < GameConstants.gridSize; y++) {
        for (int x = 0; x < GameConstants.gridSize; x++) {
          if (canPlaceBlock(block, x, y)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Returns the grid coordinates of a block's occupied cells.
  ///
  /// Parameters:
  ///   - [block]: The block to get positions for
  ///
  /// Returns: List of (x, y) grid coordinates where the block's cells are
  ///
  /// Useful for rendering the block on the grid.
  List<(int, int)> getBlockCellsAtPosition(Block block) {
    List<(int, int)> cells = [];
    List<(int, int)> occupiedCells = block.getOccupiedCells();

    for (var (cellX, cellY) in occupiedCells) {
      cells.add((block.gridX + cellX, block.gridY + cellY));
    }

    return cells;
  }
}
