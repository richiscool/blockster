import 'package:flutter/material.dart';
import '../models/block.dart';
import '../models/game_state.dart';
import '../widgets/confetti_widget.dart';
import 'lose_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState gameState;
  Block? selectedBlock;
  int? selectedBlockIndex;
  Offset dragOffset = Offset.zero;
  bool isDraggingOverGrid = false;
  int? previewGridX;
  int? previewGridY;

  @override
  void initState() {
    super.initState();
    gameState = GameState();
  }

  void _onBlockDragStart(Block block, int index, DragStartDetails details) {
    setState(() {
      selectedBlock = block;
      selectedBlockIndex = index;
      dragOffset = details.globalPosition;
    });
  }

  void _onBlockDragUpdate(DragUpdateDetails details) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return; // ← Add this

    final gridOffset = _getGridOffset();

    const gridSize = 400.0;
    final gridRect = Rect.fromLTWH(
      gridOffset.dx,
      gridOffset.dy,
      gridSize,
      gridSize,
    );

    final globalPos = details.globalPosition;
    final isOverGrid = gridRect.contains(globalPos);

    setState(() {
      dragOffset = globalPos;
      isDraggingOverGrid = isOverGrid;

      if (isOverGrid) {
        final renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(globalPos);
        previewGridX =
            ((localPosition.dx - gridOffset.dx) / 40).floor().clamp(0, 9);
        previewGridY =
            ((localPosition.dy - gridOffset.dy) / 40).floor().clamp(0, 9);
      } else {
        previewGridX = null;
        previewGridY = null;
      }
    });
  }

  void _onBlockDragEnd(DragEndDetails details) {
    if (selectedBlock == null) return;

    if (previewGridX != null && previewGridY != null) {
      if (gameState.placeBlock(selectedBlock!, previewGridX!, previewGridY!)) {
        // Block placed successfully
        setState(() {
          selectedBlock = null;
          selectedBlockIndex = null;
          isDraggingOverGrid = false;
          previewGridX = null;
          previewGridY = null;
        });

        // Check for line clears and show confetti if points were scored
        if (gameState.score > 0) {
          showConfetti(context);
        }

        // Check if game is over
        if (gameState.gameOver) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => LoseScreen(finalScore: gameState.score),
                ),
              );
            }
          });
        }
      } else {
        // Reset selection if placement failed
        setState(() {
          selectedBlock = null;
          selectedBlockIndex = null;
          isDraggingOverGrid = false;
          previewGridX = null;
          previewGridY = null;
        });
      }
    } else {
      setState(() {
        selectedBlock = null;
        selectedBlockIndex = null;
        isDraggingOverGrid = false;
        previewGridX = null;
        previewGridY = null;
      });
    }
  }

  Offset _getGridOffset() {
    final screenWidth = MediaQuery.of(context).size.width;
    const gridSize = 400.0;

    return Offset(
      (screenWidth - gridSize) / 2,
      80, // Top padding for score display
    );
  }

  @override
  Widget build(BuildContext context) {
    final gridOffset = _getGridOffset();
    const gridSize = 400.0;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            color: const Color(0xFFF0F0F0),
          ),
          // Score display
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Score: ${gameState.score}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (gameState.isDoublePointsActive)
                  Text(
                    '2x Points! (${gameState.doublePointsMovesRemaining} moves)',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          // Game Grid
          Positioned(
            left: gridOffset.dx,
            top: gridOffset.dy,
            child: Container(
              width: gridSize,
              height: gridSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                color: Colors.white,
              ),
              child: Stack(
                children: [
                  // Grid background
                  CustomPaint(
                    painter: GridPainter(gameState),
                    size: const Size(gridSize, gridSize),
                  ),
                  // Block placement preview
                  if (isDraggingOverGrid &&
                      selectedBlock != null &&
                      previewGridX != null &&
                      previewGridY != null)
                    CustomPaint(
                      painter: BlockPreviewOverlayPainter(
                        selectedBlock!,
                        previewGridX!,
                        previewGridY!,
                        gameState,
                      ),
                      size: const Size(gridSize, gridSize),
                    ),
                ],
              ),
            ),
          ),
          // Current blocks (draggable) - Below grid on left
          Positioned(
            left: 20,
            top: gridOffset.dy + gridSize + 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Blocks:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: screenHeight - (gridOffset.dy + gridSize + 60),
                  child: SingleChildScrollView(
                    child: Column(
                      children:
                          gameState.currentBlocks.asMap().entries.map((entry) {
                        int index = entry.key;
                        Block block = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: GestureDetector(
                            onPanStart: (details) =>
                                _onBlockDragStart(block, index, details),
                            onPanUpdate: _onBlockDragUpdate,
                            onPanEnd: _onBlockDragEnd,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedBlockIndex == index
                                      ? Colors.black
                                      : Colors.grey,
                                  width: selectedBlockIndex == index ? 3 : 2,
                                ),
                                color: Colors.grey[200],
                              ),
                              child: _buildBlockPreview(block),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Next blocks preview - Below grid on right (smaller)
          Positioned(
            right: 20,
            top: gridOffset.dy + gridSize + 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Blocks:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...gameState.nextBlocks.map((block) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        color: Colors.grey[100],
                      ),
                      child: _buildSmallBlockPreview(block),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          // Exit button
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              child: const Text(
                'Exit',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockPreview(Block block) {
    final occupied = block.getOccupiedCells();
    if (occupied.isEmpty) return const SizedBox();

    final maxX = occupied.map((c) => c.$1).reduce((a, b) => a > b ? a : b) + 1;
    final maxY = occupied.map((c) => c.$2).reduce((a, b) => a > b ? a : b) + 1;
    const double cellSize = 16.0;

    return CustomPaint(
      painter: BlockPreviewPainter(block, occupied, cellSize),
      size: Size(maxX * cellSize + 10, maxY * cellSize + 10),
    );
  }

  Widget _buildSmallBlockPreview(Block block) {
    final occupied = block.getOccupiedCells();
    if (occupied.isEmpty) return const SizedBox();

    final maxX = occupied.map((c) => c.$1).reduce((a, b) => a > b ? a : b) + 1;
    final maxY = occupied.map((c) => c.$2).reduce((a, b) => a > b ? a : b) + 1;
    const double cellSize = 12.0;

    return CustomPaint(
      painter: BlockPreviewPainter(block, occupied, cellSize),
      size: Size(maxX * cellSize + 5, maxY * cellSize + 5),
    );
  }
}

class GridPainter extends CustomPainter {
  final GameState gameState;

  GridPainter(this.gameState);

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / GameState.gridSize;
    final gridPaint = Paint()..color = Colors.black12;

    // Draw grid
    for (int i = 0; i <= GameState.gridSize; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        gridPaint,
      );
    }

    // Draw placed blocks
    for (int y = 0; y < GameState.gridSize; y++) {
      for (int x = 0; x < GameState.gridSize; x++) {
        if (gameState.grid[y][x] != 0) {
          final paint = Paint()..color = Colors.blue.withValues(alpha: 0.6);
          canvas.drawRect(
            Rect.fromLTWH(
              x * cellSize + 1,
              y * cellSize + 1,
              cellSize - 2,
              cellSize - 2,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => true;
}

class BlockPreviewPainter extends CustomPainter {
  final Block block;
  final List<(int, int)> occupied;
  final double cellSize;

  BlockPreviewPainter(this.block, this.occupied, this.cellSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = block.color;

    for (var (x, y) in occupied) {
      canvas.drawRect(
        Rect.fromLTWH(
          x * cellSize + 5,
          y * cellSize + 5,
          cellSize - 2,
          cellSize - 2,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BlockPreviewPainter oldDelegate) => false;
}

class BlockPreviewOverlayPainter extends CustomPainter {
  final Block block;
  final int gridX;
  final int gridY;
  final GameState gameState;

  BlockPreviewOverlayPainter(
      this.block, this.gridX, this.gridY, this.gameState);

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / GameState.gridSize;
    final occupied = block.getOccupiedCells();
    final canPlace = gameState.canPlaceBlock(block, gridX, gridY);

    // Draw semi-transparent preview
    final previewPaint = Paint()
      ..color = canPlace
          ? Colors.green.withValues(alpha: 0.3)
          : Colors.red.withValues(alpha: 0.3);

    for (var (cellX, cellY) in occupied) {
      final x = (gridX + cellX) * cellSize;
      final y = (gridY + cellY) * cellSize;

      canvas.drawRect(
        Rect.fromLTWH(
          x + 1,
          y + 1,
          cellSize - 2,
          cellSize - 2,
        ),
        previewPaint,
      );
    }

    // Draw outline
    final outlinePaint = Paint()
      ..color = canPlace ? Colors.green : Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var (cellX, cellY) in occupied) {
      final x = (gridX + cellX) * cellSize;
      final y = (gridY + cellY) * cellSize;

      canvas.drawRect(
        Rect.fromLTWH(
          x + 1,
          y + 1,
          cellSize - 2,
          cellSize - 2,
        ),
        outlinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(BlockPreviewOverlayPainter oldDelegate) =>
      oldDelegate.gridX != gridX || oldDelegate.gridY != gridY;
}
