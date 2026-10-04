import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/game_constants.dart';

/// Represents a single confetti particle.
///
/// Each particle has position, velocity, size, and color.
/// Particles fall from top to bottom of the screen during animation.
class ConfettiPiece {
  /// Current X position on screen.
  double x;

  /// Current Y position on screen.
  double y;

  /// Horizontal velocity (pixels per frame).
  double velocityX;

  /// Vertical velocity (pixels per frame).
  double velocityY;

  /// Size of the particle (width and height in pixels).
  double size;

  /// Color of this particle.
  Color color;

  /// Rotation angle in radians.
  double rotation;

  /// Angular velocity (radians per frame).
  double angularVelocity;

  /// Creates a new confetti particle.
  ///
  /// Parameters:
  ///   - [x]: Starting X position
  ///   - [y]: Starting Y position
  ///   - [velocityX]: Horizontal velocity
  ///   - [velocityY]: Vertical velocity
  ///   - [size]: Particle size
  ///   - [color]: Particle color
  ///   - [rotation]: Initial rotation angle
  ///   - [angularVelocity]: Rotation speed
  ConfettiPiece({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.color,
    required this.rotation,
    required this.angularVelocity,
  });

  /// Updates particle position based on velocity.
  ///
  /// Called each frame to animate the particle falling and spinning.
  void update() {
    x += velocityX;
    y += velocityY;
    rotation += angularVelocity;
  }
}

/// Widget that displays and animates confetti particles.
///
/// Shows confetti animation for 2 seconds (configurable via [GameConstants.confettiDuration]).
/// Automatically dismisses itself after animation completes.
/// Used to celebrate line clears and other achievements.
class ConfettiWidget extends StatefulWidget {
  /// Creates a confetti widget.
  ///
  /// The widget auto-dismisses after [GameConstants.confettiDuration].
  const ConfettiWidget({Key? key}) : super(key: key);

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

/// State for [ConfettiWidget].
///
/// Manages animation controller, particle generation, and rendering.
class _ConfettiWidgetState extends State<ConfettiWidget>
    with TickerProviderStateMixin {
  /// Animation controller for the confetti animation.
  ///
  /// Drives the animation forward for [GameConstants.confettiDuration].
  late AnimationController _controller;

  /// List of active confetti particles.
  ///
  /// Initialized in [didChangeDependencies] so [MediaQuery] is available.
  List<ConfettiPiece> _pieces = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: GameConstants.confettiDuration,
      vsync: this,
    );
    _controller.forward().then((_) {
      // Auto-dismiss after animation completes
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to use MediaQuery here
    if (_pieces.isEmpty) {
      _createConfetti();
    }
  }

  /// Generates random confetti particles.
  ///
  /// Creates [GameConstants.confettiParticleCount] particles with:
  ///   - Random positions (bottom of screen)
  ///   - Random velocities (upward and outward)
  ///   - Random colors from block palette
  ///   - Random rotation and angular velocity
  void _createConfetti() {
    final size = MediaQuery.of(context).size;
    final random = math.Random();
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.pink,
    ];

    _pieces = [];
    for (int i = 0; i < GameConstants.confettiParticleCount; i++) {
      _pieces.add(
        ConfettiPiece(
          x: random.nextDouble() * size.width,
          y: size.height,
          velocityX: (random.nextDouble() - 0.5) * 8,
          velocityY: -(random.nextDouble() * 8 + 4),
          size: random.nextDouble() * 10 + 5,
          color: colors[random.nextInt(colors.length)],
          rotation: random.nextDouble() * 2 * math.pi,
          angularVelocity: (random.nextDouble() - 0.5) * 0.2,
        ),
      );
    }
  }

  /// Updates all particles and redraws.
  ///
  /// Called on each animation frame via [_controller].
  void _onFrame(Duration elapsed) {
    setState(() {
      for (var piece in _pieces) {
        piece.update();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          _onFrame(_controller.lastElapsedDuration ?? Duration.zero);
          return CustomPaint(
            painter: ConfettiPainter(_pieces),
          );
        },
      ),
    );
  }
}

/// Custom painter that renders confetti particles.
///
/// Draws each particle as a rotated rectangle with its assigned color.
class ConfettiPainter extends CustomPainter {
  /// List of particles to paint.
  final List<ConfettiPiece> pieces;

  /// Creates a new confetti painter.
  ///
  /// Parameters:
  ///   - [pieces]: The confetti particles to render
  ConfettiPainter(this.pieces);

  @override
  void paint(Canvas canvas, Size size) {
    for (var piece in pieces) {
      final paint = Paint()..color = piece.color;

      canvas.save();
      canvas.translate(piece.x, piece.y);
      canvas.rotate(piece.rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: const Offset(0, 0),
          width: piece.size,
          height: piece.size,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}
