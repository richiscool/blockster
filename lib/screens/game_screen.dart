import 'package:flutter/material.dart';
import 'package:blockster/constants/game_constants.dart';
import 'package:blockster/models/block.dart';
import 'package:blockster/models/game_state.dart';
import 'package:blockster/services/haptic_feedback_service.dart';
import 'package:blockster/screens/lose_screen.dart';
import 'package:blockster/widgets/confetti_widget.dart';

/// Optimized main gameplay screen with CustomPaint and ValueNotifier for 60 FPS performance.
///
/// This version eliminates the performance bottlenecks of the GridView-based approach:
/// - Uses CustomPaint instead of GridView.builder (single paint call vs 100 widgets)
/// - Uses ValueNotifier for drag updates (no setState on every pixel movement)
/// - Minimizes widget rebuilds
class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  /// The game state instance managing grid and logic.
  late GameState gameState;

  /// Currently selected block being dragged.
  Block? selectedBlock;

  /// ValueNotifier for drag position (doesn't trigger setState).
  /// Initialized in field declaration to ensure it's always available.
  final ValueNotifier<Offset> _dragNotifier = ValueNotifier(Offset.zero);

  /// Whether the dragged block is currently over the grid.
  bool isDraggingOverGrid = false;

  /// Preview grid X position (null if not over grid).
  int? previewGridX;

  /// Preview grid Y position (null if not over grid).
  int? previewGridY;

  @override
  void initState() {
    super.initState();
    gameState = GameState();
  }

  @override
  void dispose() {
    _dragNotifier.dispose();
    super.dispose();
  }

  /// Called when user starts dragging a block.
  void _onBlockDragStart(DragStartDetails details, Block block) {
    setState(() {
      selectedBlock = block;
    });
    _dragNotifier.value = details.globalPosition;
  }

  /// Called continuously while dragging (updates notifier, not setState).
  void _onBlockDragUpdate(DragUpdateDetails details) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Update drag position in notifier (no setState!)
    _dragNotifier.value = details.globalPosition;

    // Calculate grid position
    const gridPosition = Offset(
      GameConstants.gridPixelSize / 2 + 50,
      80,
    );
    final distance =
        (details.globalPosition - renderBox.localToGlobal(gridPosition))
            .distance;

    final isOverGrid =
        distance < GameConstants.gridPixelSize / 2 && selectedBlock != null;

    if (isOverGrid) {
      final localPosition = renderBox.globalToLocal(details.globalPosition);
      final relativePos = localPosition -
          Offset(
            MediaQuery.of(context).size.width / 2 -
                GameConstants.gridPixelSize / 2,
            80,
          );

      final newGridX = (relativePos.dx / GameConstants.cellSize).floor();
      final newGridY = (relativePos.dy / GameConstants.cellSize).floor();

      // Only rebuild if grid position changed, not on every pixel movement
      if (isDraggingOverGrid != isOverGrid ||
          previewGridX != newGridX ||
          previewGridY != newGridY) {
        setState(() {
          isDraggingOverGrid = isOverGrid;
          previewGridX = newGridX;
          previewGridY = newGridY;
        });
      }
    } else if (isDraggingOverGrid) {
      // Only rebuild when leaving grid
      setState(() {
        isDraggingOverGrid = false;
        previewGridX = null;
        previewGridY = null;
      });
    }
  }

  /// Called when user releases the drag.
  Future<void> _onBlockDragEnd(DragEndDetails details) async {
    if (selectedBlock != null &&
        isDraggingOverGrid &&
        previewGridX != null &&
        previewGridY != null) {
      // Attempt placement
      if (gameState.placeBlock(selectedBlock!, previewGridX!, previewGridY!)) {
        // ✅ Haptic feedback: block placed
        await HapticFeedbackService.blockPlaced();

        setState(() {
          selectedBlock = null;
          previewGridX = null;
          previewGridY = null;
          isDraggingOverGrid = false;
        });

        // Trigger confetti animation
        await _showConfetti();

        // Extra haptic feedback for combo
        if (gameState.isDoublePointsActive) {
          await HapticFeedbackService.custom(durationMs: 150);
        }

        // Check game over
        if (gameState.gameOver) {
          // ✅ Haptic feedback: game over
          await HapticFeedbackService.gameOver();

          if (mounted) {
            Future.delayed(
              GameConstants.gameOverDelay,
              () {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => LoseScreen(gameState: gameState),
                    ),
                  );
                }
              },
            );
          }
        }
      }
    }

    setState(() {
      selectedBlock = null;
      previewGridX = null;
      previewGridY = null;
      isDraggingOverGrid = false;
    });
  }

  /// Shows confetti animation.
  Future<void> _showConfetti() async {
    // ✅ Haptic feedback: line cleared
    await HapticFeedbackService.lineCleared();

    // Show confetti overlay
    if (mounted) {
      showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) => const Dialog(
          backgroundColor: Colors.transparent,
          child: ConfettiWidget(),
        ),
      );
    }
  }

  /// Builds the 10x10 game grid using CustomPaint (much faster than GridView).
  Widget _buildGrid() {
    return Center(
      child: Container(
        width: GameConstants.gridPixelSize,
        height: GameConstants.gridPixelSize,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          color: Colors.grey[900],
        ),
        child: Stack(
          children: [
            // Grid rendered with CustomPaint (single paint call instead of 100 widgets)
            CustomPaint(
              painter: GameGridPainter(gameState),
              size: const Size(
                GameConstants.gridPixelSize,
                GameConstants.gridPixelSize,
              ),
            ),
            // Drag preview (updates from ValueNotifier, not setState)
            ValueListenableBuilder<Offset>(
              valueListenable: _dragNotifier,
              builder: (context, offset, _) {
                if (!isDraggingOverGrid ||
                    selectedBlock == null ||
                    previewGridX == null ||
                    previewGridY == null) {
                  return const SizedBox.expand();
                }

                bool isValidPlacement = gameState.canPlaceBlock(
                  selectedBlock!,
                  previewGridX!,
                  previewGridY!,
                );

                return CustomPaint(
                  painter: BlockPreviewOverlayPainter(
                    gridX: previewGridX,
                    gridY: previewGridY,
                    block: selectedBlock,
                    isValid: isValidPlacement,
                  ),
                  size: const Size(
                    GameConstants.gridPixelSize,
                    GameConstants.gridPixelSize,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds draggable block widget.
  Widget _buildDraggableBlock(Block block) {
    return GestureDetector(
      onHorizontalDragStart: (details) => _onBlockDragStart(details, block),
      onHorizontalDragUpdate: _onBlockDragUpdate,
      onHorizontalDragEnd: _onBlockDragEnd,
      onVerticalDragStart: (details) => _onBlockDragStart(details, block),
      onVerticalDragUpdate: _onBlockDragUpdate,
      onVerticalDragEnd: _onBlockDragEnd,
      child: Container(
        width: GameConstants.blockContainerSize,
        height: GameConstants.blockContainerSize,
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedBlock == block ? Colors.yellow : Colors.white,
            width: 2,
          ),
          color: Colors.grey[800],
        ),
        child: _buildSmallBlockPreview(block),
      ),
    );
  }

  /// Builds preview visualization of a block using CustomPaint.
  Widget _buildSmallBlockPreview(Block block) {
    return Center(
      child: CustomPaint(
        painter: BlockPreviewPainter(block),
        size: const Size(80, 80),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blockster'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Score display
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Score: ${gameState.score}',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),

                // Game grid
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: _buildGrid(),
                ),

                // Current blocks & Next blocks
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const Text('Your Blocks',
                              style: TextStyle(fontSize: 14)),
                          const SizedBox(height: 8),
                          Row(
                            children: gameState.currentBlocks
                                .map((block) => Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: _buildDraggableBlock(block),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Next Blocks',
                              style: TextStyle(fontSize: 14)),
                          const SizedBox(height: 8),
                          Row(
                            children: gameState.nextBlocks
                                .map((block) => Container(
                                      width: GameConstants.nextBlockPreviewSize,
                                      height:
                                          GameConstants.nextBlockPreviewSize,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey, width: 1),
                                        color: Colors.grey[800],
                                      ),
                                      child: _buildSmallBlockPreview(block),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Exit button
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Exit Game'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the game grid.
/// Renders the 10x10 grid with occupied cells in a single paint call.
class GameGridPainter extends CustomPainter {
  final GameState gameState;

  GameGridPainter(this.gameState);

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / GameConstants.gridSize;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 0.5;

    for (int i = 0; i <= GameConstants.gridSize; i++) {
      final offset = i * cellSize;
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, offset),
        Offset(size.width, offset),
        gridPaint,
      );
    }

    // Draw occupied cells
    final occupiedPaint = Paint()..color = Colors.blue.withValues(alpha: 0.6);

    for (int y = 0; y < GameConstants.gridSize; y++) {
      for (int x = 0; x < GameConstants.gridSize; x++) {
        if (gameState.grid[y][x] != 0) {
          canvas.drawRect(
            Rect.fromLTWH(
              x * cellSize + 1,
              y * cellSize + 1,
              cellSize - 2,
              cellSize - 2,
            ),
            occupiedPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(GameGridPainter oldDelegate) => true;
}

/// Custom painter for block preview (small preview in block selector).
class BlockPreviewPainter extends CustomPainter {
  final Block block;

  BlockPreviewPainter(this.block);

  @override
  void paint(Canvas canvas, Size size) {
    final occupied = block.getOccupiedCells();
    if (occupied.isEmpty) return;

    final maxX = occupied.map((c) => c.$1).fold(0, (a, b) => a > b ? a : b) + 1;
    final maxY = occupied.map((c) => c.$2).fold(0, (a, b) => a > b ? a : b) + 1;

    final cellWidth = size.width / maxX;
    final cellHeight = size.height / maxY;

    final paint = Paint()..color = block.color;

    for (var (x, y) in occupied) {
      canvas.drawRect(
        Rect.fromLTWH(
          x * cellWidth + 2,
          y * cellHeight + 2,
          cellWidth - 4,
          cellHeight - 4,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BlockPreviewPainter oldDelegate) => false;
}

/// Custom painter for block preview overlay (when dragging over grid).
/// Shows green outline for valid placement, red for invalid.
class BlockPreviewOverlayPainter extends CustomPainter {
  final int? gridX;
  final int? gridY;
  final Block? block;
  final bool isValid;

  BlockPreviewOverlayPainter({
    required this.gridX,
    required this.gridY,
    required this.block,
    required this.isValid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (gridX == null || gridY == null || block == null) return;

    final cellSize = size.width / GameConstants.gridSize;
    final occupied = block!.getOccupiedCells();

    final fillPaint = Paint()
      ..color = isValid
          ? Colors.green.withValues(alpha: 0.2)
          : Colors.red.withValues(alpha: 0.2);

    final outlinePaint = Paint()
      ..color = isValid ? Colors.green : Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var (cellX, cellY) in occupied) {
      final x = (gridX! + cellX) * cellSize;
      final y = (gridY! + cellY) * cellSize;

      final rect = Rect.fromLTWH(x + 1, y + 1, cellSize - 2, cellSize - 2);

      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, outlinePaint);
    }
  }

  @override
  bool shouldRepaint(BlockPreviewOverlayPainter oldDelegate) =>
      oldDelegate.gridX != gridX || oldDelegate.gridY != gridY;
}
