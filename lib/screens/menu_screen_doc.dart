import 'package:flutter/material.dart';
import 'package:blockster/constants/game_constants.dart';
import 'package:blockster/screens/game_screen_doc.dart';

/// Main menu screen for Blockster.
///
/// Displays the game title, animated gradient background, play button,
/// and leaderboard link. Entry point to the game.
class MenuScreen extends StatefulWidget {
  /// Creates the menu screen.
  const MenuScreen({Key? key}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

/// State for [MenuScreen].
///
/// Manages the animated gradient background that cycles colors.
class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  /// Controller for the gradient color animation.
  ///
  /// Repeats endlessly, cycling through background colors
  /// over [GameConstants.menuGradientDuration].
  late AnimationController _gradientController;

  /// Animation value for gradient color interpolation.
  ///
  /// Ranges from 0.0 to 1.0 and repeats.
  /// Used to smoothly transition between background colors.
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _initializeGradientAnimation();
  }

  /// Initializes the gradient color animation controller.
  ///
  /// Sets up animation to repeat endlessly with a duration of
  /// [GameConstants.menuGradientDuration].
  void _initializeGradientAnimation() {
    _gradientController = AnimationController(
      duration: GameConstants.menuGradientDuration,
      vsync: this,
    )..repeat(reverse: true);

    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );
  }

  /// Builds a color for the gradient based on animation value.
  ///
  /// Smoothly transitions between a set of colors as the animation progresses.
  ///
  /// Parameters:
  ///   - [value]: Animation value (0.0 to 1.0)
  ///
  /// Returns: A Color interpolated based on the animation value
  Color _getGradientColor(double value) {
    if (value < 0.25) {
      // Blue to Purple
      return Color.lerp(Colors.blue, Colors.purple, value * 4)!;
    } else if (value < 0.5) {
      // Purple to Pink
      return Color.lerp(Colors.purple, Colors.pink, (value - 0.25) * 4)!;
    } else if (value < 0.75) {
      // Pink to Cyan
      return Color.lerp(Colors.pink, Colors.cyan, (value - 0.5) * 4)!;
    } else {
      // Cyan back to Blue
      return Color.lerp(Colors.cyan, Colors.blue, (value - 0.75) * 4)!;
    }
  }

  /// Navigates to the game screen when play is tapped.
  void _onPlayPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getGradientColor(_gradientAnimation.value),
                  _getGradientColor((_gradientAnimation.value + 0.3) % 1.0),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  const Text(
                    'BLOCKSTER',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Subtitle
                  const Text(
                    'Block Puzzle Game',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Play Button
                  ElevatedButton(
                    onPressed: _onPlayPressed,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      elevation: 8,
                    ),
                    child: const Text(
                      'PLAY',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
