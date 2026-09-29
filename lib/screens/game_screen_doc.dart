import 'package:flutter/material.dart';
import 'package:blockster/constants/game_constants.dart';
import 'package:blockster/models/block_doc.dart';
import 'package:blockster/models/game_state_doc.dart';
import 'package:blockster/services/haptic_feedback_service_doc.dart';
import 'package:blockster/screens/lose_screen_doc.dart';
import 'package:blockster/widgets/confetti_widget_doc.dart';

/// Main gameplay screen where players place blocks on the 10x10 grid.
///
/// Handles:
/// - Grid rendering and visualization
/// - Block dragging and placement preview
/// - Placement validation with visual feedback (green = valid, red = invalid)
/// - Score and move tracking
/// - Confetti animation on line clears
/// - Haptic feedback on game events
/// - Game-over detection and navigation
class GameScreen extends StatefulWidget {
  /// Creates the game screen.
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// State for [GameScreen].
///
/// Manages game state, block selection, dragging, and placement.
class _GameScreenState extends State<GameScreen> {
  /// The game state instance managing grid and logic.
  late GameState gameState;

  /// Currently selected block being dragged.
  ///
  /// Null if no block is being dragged.
  Block? selectedBlock;

  /// Current drag position in screen coordinates.
  Offset dragOffset = Offset.zero;

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

  /// Called when user starts dragging a block.
  ///
  /// Parameters:
  ///   - [details]: Drag start details with position
  ///   - [block]: The block being dragged
  void _onBlockDragStart(DragStartDetails details, Block block) {
    setState(() {
      selectedBlock = block;
      dragOffset = details.globalPosition;
    });
  }

  /// Called continuously while dragging.
  ///
  /// Updates preview position and validates placement.
  ///
  /// Parameters:
  ///   - [details]: Drag update details with current position
  void _onBlockDragUpdate(DragUpdateDetails details) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    setState(() {
      dragOffset = details.globalPosition;

      // Calculate grid position if dragging over grid
      const gridPosition = Offset(
        GameConstants.gridPixelSize / 2 + 50,
        80,
      );
      final distance =
          (dragOffset - renderBox.localToGlobal(gridPosition)).distance;

      isDraggingOverGrid =
          distance < GameConstants.gridPixelSize / 2 && selectedBlock != null;

      if (isDraggingOverGrid) {
        final localPosition = renderBox.globalToLocal(dragOffset);
        final relativePos = localPosition -
            Offset(
              MediaQuery.of(context).size.width / 2 -
                  GameConstants.gridPixelSize / 2,
              80,
            );

        previewGridX = (relativePos.dx / GameConstants.cellSize).floor();
        previewGridY = (relativePos.dy / GameConstants.cellSize).floor();
      } else {
        previewGridX = null;
        previewGridY = null;
      }
    });
  }

  /// Called when user releases the drag.
  ///
  /// Attempts to place block if valid position.
  /// Triggers haptic feedback and confetti on success.
  ///
  /// Parameters:
  ///   - [details]: Drag end details
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
        _showConfetti();

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
  ///
  /// Displays celebratory confetti and triggers line-clear haptic feedback.
  void _showConfetti() {
    // ✅ Haptic feedback: line cleared
    HapticFeedbackService.lineCleared();

    // Show confetti overlay
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        child: ConfettiWidget(),
      ),
    );
  }

  /// Builds preview outline showing where block will be placed.
  /// Green = valid placement, Red = invalid placement.
  Widget _buildBlockPreviewOverlay() {
    if (!isDraggingOverGrid ||
        selectedBlock == null ||
        previewGridX == null ||
        previewGridY == null) {
      return SizedBox.expand(
        child: CustomPaint(
          painter: BlockPreviewOverlayPainter(
            gridX: null,
            gridY: null,
            block: null,
            isValid: false,
          ),
        ),
      );
    }

    bool isValidPlacement = gameState.canPlaceBlock(
      selectedBlock!,
      previewGridX!,
      previewGridY!,
    );

    return SizedBox.expand(
      child: CustomPaint(
        painter: BlockPreviewOverlayPainter(
          gridX: previewGridX,
          gridY: previewGridY,
          block: selectedBlock,
          isValid: isValidPlacement,
        ),
      ),
    );
  }

  /// Builds the 10x10 game grid with occupied cells highlighted.
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
            // Grid cells
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: GameConstants.gridSize,
              ),
              itemCount: GameConstants.gridSize * GameConstants.gridSize,
              itemBuilder: (context, index) {
                int x = index % GameConstants.gridSize;
                int y = index ~/ GameConstants.gridSize;
                bool isOccupied = gameState.grid[y][x] != 0;

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey[700]!,
                      width: 0.5,
                    ),
                    color: isOccupied ? Colors.blue : Colors.transparent,
                  ),
                );
              },
            ),
            // Preview overlay
            _buildBlockPreviewOverlay(),
          ],
        ),
      ),
    );
  }

  /// Builds draggable block widget.
  ///
  /// Parameters:
  ///   - [block]: The block to render
  ///   - [index]: Block index (for identification)
  Widget _buildDraggableBlock(Block block, int index) {
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

  /// Builds preview visualization of a block.
  ///
  /// Parameters:
  ///   - [block]: The block to preview
  Widget _buildSmallBlockPreview(Block block) {
    return Center(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: block.width,
        ),
        itemCount: block.width * block.height,
        itemBuilder: (context, index) {
          int x = index % block.width;
          int y = index ~/ block.width;

          return Container(
            decoration: BoxDecoration(
              color: block.shape[y][x] == 1 ? block.color : Colors.transparent,
              border: Border.all(color: Colors.grey, width: 0.5),
            ),
          );
        },
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
                                .asMap()
                                .entries
                                .map((e) => Padding(
                                      padding: const EdgeInsets.all(4),
                                      child:
                                          _buildDraggableBlock(e.value, e.key),
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
                                .asMap()
                                .entries
                                .map((e) => Container(
                                      width: GameConstants.nextBlockPreviewSize,
                                      height:
                                          GameConstants.nextBlockPreviewSize,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey, width: 1),
                                        color: Colors.grey[800],
                                      ),
                                      child: _buildSmallBlockPreview(e.value),
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

/// Custom painter for block preview overlay.
/// Shows green outline for valid placement, red for invalid.
///
/// Used to provide real-time visual feedback while dragging blocks over the grid.
class BlockPreviewOverlayPainter extends CustomPainter {
  /// Grid X position of the preview (null if not over grid).
  final int? gridX;

  /// Grid Y position of the preview (null if not over grid).
  final int? gridY;

  /// The block being previewed (null if not over grid).
  final Block? block;

  /// Whether the current placement is valid.
  final bool isValid;

  /// Creates a block preview overlay painter.
  ///
  /// Parameters:
  ///   - [gridX]: Grid X position
  ///   - [gridY]: Grid Y position
  ///   - [block]: The block being previewed
  ///   - [isValid]: Whether placement is valid
  BlockPreviewOverlayPainter({
    required this.gridX,
    required this.gridY,
    required this.block,
    required this.isValid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (gridX == null || gridY == null || block == null) return;

    final paint = Paint()
      ..color = isValid
          ? Colors.green.withValues(alpha: 0.4)
          : Colors.red.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const cellSize = GameConstants.cellSize;
    List<(int, int)> cells = block!.getOccupiedCells();

    for (var (cellX, cellY) in cells) {
      final x = (gridX! + cellX) * cellSize;
      final y = (gridY! + cellY) * cellSize;

      canvas.drawRect(
        Rect.fromLTWH(x, y, cellSize, cellSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BlockPreviewOverlayPainter oldDelegate) => true;
}
