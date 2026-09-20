import 'dart:math';
import 'block.dart';

class GameState {
  static const int gridSize = 10;
  late List<List<int>> grid;
  late List<Block> currentBlocks;
  late List<Block> nextBlocks;
  int score = 0;
  int moves = 0;
  bool isDoublePointsActive = false;
  int doublePointsMovesRemaining = 0;
  bool gameOver = false;

  GameState() {
    initializeGame();
  }

  void initializeGame() {
    grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => 0));
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

  void generateNewBlocks() {
    currentBlocks = [];
    for (int i = 0; i < 3; i++) {
      BlockType randomType =
          BlockType.values[Random().nextInt(BlockType.values.length)];
      currentBlocks.add(Block.createBlock(randomType));
    }
  }

  void generateNextBlocks() {
    nextBlocks = [];
    for (int i = 0; i < 3; i++) {
      BlockType randomType =
          BlockType.values[Random().nextInt(BlockType.values.length)];
      nextBlocks.add(Block.createBlock(randomType));
    }
  }

  bool canPlaceBlock(Block block, int x, int y) {
    List<(int, int)> cells = block.getOccupiedCells();

    for (var (cellX, cellY) in cells) {
      int gridX = x + cellX;
      int gridY = y + cellY;

      if (gridX < 0 || gridX >= gridSize || gridY < 0 || gridY >= gridSize) {
        return false;
      }

      if (grid[gridY][gridX] != 0) {
        return false;
      }
    }
    return true;
  }

  bool placeBlock(Block block, int x, int y) {
    if (!canPlaceBlock(block, x, y)) {
      return false;
    }

    List<(int, int)> cells = block.getOccupiedCells();
    for (var (cellX, cellY) in cells) {
      int gridX = x + cellX;
      int gridY = y + cellY;
      grid[gridY][gridX] = 1;
    }

    moves++;
    if (isDoublePointsActive) {
      doublePointsMovesRemaining--;
      if (doublePointsMovesRemaining == 0) {
        isDoublePointsActive = false;
      }
    }

    clearLines();

    currentBlocks = nextBlocks;
    generateNextBlocks();

    if (!canPlaceAnyBlock()) {
      gameOver = true;
    }

    return true;
  }

  void clearLines() {
    Set<int> rowsToClear = {};
    Set<int> columnsToClear = {};

    for (int y = 0; y < gridSize; y++) {
      bool rowFull = true;
      for (int x = 0; x < gridSize; x++) {
        if (grid[y][x] == 0) {
          rowFull = false;
          break;
        }
      }
      if (rowFull) {
        rowsToClear.add(y);
      }
    }

    for (int x = 0; x < gridSize; x++) {
      bool colFull = true;
      for (int y = 0; y < gridSize; y++) {
        if (grid[y][x] == 0) {
          colFull = false;
          break;
        }
      }
      if (colFull) {
        columnsToClear.add(x);
      }
    }

    if (rowsToClear.isNotEmpty || columnsToClear.isNotEmpty) {
      bool isCombo = rowsToClear.isNotEmpty && columnsToClear.isNotEmpty;

      for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
          if (rowsToClear.contains(y) || columnsToClear.contains(x)) {
            grid[y][x] = 0;
          }
        }
      }

      int pointsEarned = (rowsToClear.length + columnsToClear.length) * 10;

      if (isCombo) {
        pointsEarned *= 2;
        isDoublePointsActive = true;
        doublePointsMovesRemaining = 10;
      }

      if (isDoublePointsActive && !isCombo) {
        pointsEarned *= 2;
      }

      score += pointsEarned;
    }
  }

  bool canPlaceAnyBlock() {
    for (var block in currentBlocks) {
      for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
          if (canPlaceBlock(block, x, y)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  List<(int, int)> getBlockCellsAtPosition(Block block) {
    List<(int, int)> cells = [];
    List<(int, int)> occupiedCells = block.getOccupiedCells();

    for (var (cellX, cellY) in occupiedCells) {
      cells.add((block.gridX + cellX, block.gridY + cellY));
    }

    return cells;
  }
}
