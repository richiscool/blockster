import 'package:flutter/material.dart';

enum BlockType { red, blue, green, purple, pink }

class Block {
  final BlockType type;
  final List<List<int>> shape; // 2D grid representing block cells
  final Color color;
  int gridX = 0;
  int gridY = 0;

  Block({required this.type, required this.shape, required this.color});

  int get width => shape[0].length;
  int get height => shape.length;

  // Get list of occupied cells relative to (0,0)
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

  Block copy() {
    return Block(
      type: type,
      shape: shape.map((row) => [...row]).toList(),
      color: color,
    );
  }

  static Block createBlock(BlockType type) {
    switch (type) {
      case BlockType.red:
        // 3x3 square
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
        // 2x1 horizontal rectangle with 1x1 square on top right
        return Block(
          type: BlockType.blue,
          shape: [
            [0, 1],
            [1, 1],
          ],
          color: Colors.blue,
        );
      case BlockType.green:
        // 3x1 horizontal rectangle with 2x1 vertical rectangle on top left
        return Block(
          type: BlockType.green,
          shape: [
            [1, 0, 0],
            [1, 1, 1],
          ],
          color: Colors.green,
        );
      case BlockType.purple:
        // 3x1 vertical rectangle with 1x1 squares on sides of middle
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
        // 3x1 vertical rectangle with 1x1 square on right side of top
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
