import 'dart:math';
import 'package:blockster/constants/game_constants.dart';

/// Builds the starting grid for each of the ten levels.
///
/// Higher levels begin with more pre-placed cells. Layouts are generated
/// from a fixed seed, so a level looks the same every time it is played.
abstract class LevelData {
  /// Number of pre-placed cells for [level] (level 1 = 6, level 10 = 51).
  static int startingCells(int level) => 6 + (level - 1) * 5;

  /// Returns a fresh 10x10 grid with the level's blocks already placed.
  static List<List<int>> gridFor(int level) {
    const size = GameConstants.gridSize;
    final grid = List.generate(size, (_) => List.filled(size, 0));
    final random = Random(level * 7919);
    final target = startingCells(level);

    final rowCounts = List.filled(size, 0);
    final colCounts = List.filled(size, 0);
    int placed = 0;
    int guard = 0;

    while (placed < target && guard < 5000) {
      guard++;
      final x = random.nextInt(size);
      final y = random.nextInt(size);
      if (grid[y][x] != 0) continue;
      // Never start with a completed (or almost completed) line.
      if (rowCounts[y] >= size - 2 || colCounts[x] >= size - 2) continue;

      grid[y][x] = 1;
      rowCounts[y]++;
      colCounts[x]++;
      placed++;
    }
    return grid;
  }
}
