import 'package:flutter/material.dart';

/// Enumeration of the 5 block types in Blockster.
enum BlockType { red, blue, green, purple, pink }

/// Represents a single Tetris-style block with shape, color, and position.
///
/// Each block consists of a 2D grid where 1 = occupied cell, 0 = empty.
/// Blocks can be positioned on the game grid and checked for valid placement.
class Block {
  /// The type of this block (determines color and shape).
  final BlockType type;

  /// 2D list representing the block's shape.
  /// Each [1] represents an occupied cell, [0] is empty space.
  /// Example: a 3x3 square has nine [1]s, an L-shape has four [1]s.
  final List<List<int>> shape;

  /// The color to render this block with.
  final Color color;

  /// Current X position on the game grid (0-9).
  int gridX = 0;

  /// Current Y position on the game grid (0-9).
  int gridY = 0;

  /// Creates a new Block.
  ///
  /// Parameters:
  ///   - [type]: The block's type (determines its role in the game)
  ///   - [shape]: 2D list where 1 = filled cell, 0 = empty
  ///   - [color]: Flutter Color to render the block
  Block({
    required this.type,
    required this.shape,
    required this.color,
  });

  /// Returns the width of this block's bounding box.
  int get width => shape[0].length;

  /// Returns the height of this block's bounding box.
  int get height => shape.length;

  /// Returns a list of (x, y) coordinates of occupied cells relative to (0,0).
  ///
  /// For example, a 3x3 square returns 9 tuples; an L-shape returns 4 tuples.
  /// Useful for collision detection and grid placement validation.
  ///
  /// Returns: List of (x, y) tuples representing occupied cells
  List<(int, int)> getOccupiedCells() {
    List<(int, int)> cells = [];
    for (int y = 0; y < shape.length; y++) {
      for (int x = 0; x < shape[y].length; x++) {
        if (shape[y][x] == 1) {
          cells.add((x, y));
        }
      }
    }
    return cells;
  }

  /// Creates a deep copy of this block.
  ///
  /// Returns: A new Block instance with identical properties
  Block copy() {
    return Block(
      type: type,
      shape: shape.map((row) => [...row]).toList(),
      color: color,
    );
  }

  /// Factory constructor that creates a new block of the specified type.
  ///
  /// Parameters:
  ///   - [type]: The BlockType to create
  ///
  /// Returns: A new Block instance with the shape and color for [type]
  ///
  /// Block shapes:
  ///   - **red**: 3×3 square (9 cells)
  ///   - **blue**: 2×2 L-shape (4 cells)
  ///   - **green**: 2×3 T-shape (5 cells)
  ///   - **purple**: 3×3 cross (5 cells)
  ///   - **pink**: 3×2 corner (4 cells)
  static Block createBlock(BlockType type) {
    switch (type) {
      case BlockType.red:
        // 3x3 square - 9 occupied cells
        return Block(
          type: BlockType.red,
          shape: [
            [1, 1, 1],
            [1, 1, 1],
            [1, 1, 1],
          ],
          color: Colors.red,
        );
      case BlockType.blue:
        // L-shape - 4 occupied cells
        return Block(
          type: BlockType.blue,
          shape: [
            [0, 1],
            [1, 1],
          ],
          color: Colors.blue,
        );
      case BlockType.green:
        // T-shape - 5 occupied cells
        return Block(
          type: BlockType.green,
          shape: [
            [1, 0, 0],
            [1, 1, 1],
          ],
          color: Colors.green,
        );
      case BlockType.purple:
        // Cross shape - 5 occupied cells
        return Block(
          type: BlockType.purple,
          shape: [
            [0, 1, 0],
            [1, 1, 1],
            [0, 1, 0],
          ],
          color: Colors.purple,
        );
      case BlockType.pink:
        // Corner shape - 4 occupied cells
        return Block(
          type: BlockType.pink,
          shape: [
            [1, 1],
            [1, 0],
            [1, 0],
          ],
          color: Colors.pink,
        );
    }
  }
}
