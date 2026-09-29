import 'package:flutter/material.dart';
import 'package:blockster/models/game_state_doc.dart';
import 'package:blockster/services/leaderboard_service_doc.dart';
import 'package:blockster/screens/menu_screen_doc.dart';

/// Screen shown when the game ends (no valid placements remain).
///
/// Displays the final score, allows player to enter their name
/// for the leaderboard, and provides options to play again or return to menu.
class LoseScreen extends StatefulWidget {
  /// The completed game state with final score.
  final GameState gameState;

  /// Creates a lose screen.
  ///
  /// Parameters:
  ///   - [gameState]: The GameState instance with the final score
  const LoseScreen({
    Key? key,
    required this.gameState,
  }) : super(key: key);

  @override
  State<LoseScreen> createState() => _LoseScreenState();
}

/// State for [LoseScreen].
///
/// Manages player name input and leaderboard submission.
class _LoseScreenState extends State<LoseScreen> {
  /// Text controller for the player name input field.
  late TextEditingController _nameController;

  /// Whether the leaderboard entry is being submitted.
  ///
  /// Used to show loading state and disable button during submission.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Submits the player's score and name to the leaderboard.
  ///
  /// If the player enters a name, saves it to the leaderboard.
  /// Shows appropriate feedback (success/failure).
  /// Navigates to menu after submission.
  Future<void> _submitScore() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter a name');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Add entry to leaderboard
      final success = await LeaderboardService.addEntry(
        name,
        widget.gameState.score,
      );

      if (!mounted) return;

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Score saved to leaderboard!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Score didn't make top 10
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Score not in top 10'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Navigate back to menu after a brief delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MenuScreen()),
            (route) => false,
          );
        }
      });
    } catch (e) {
      _showError('Error saving score: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Shows an error message to the user.
  ///
  /// Parameters:
  ///   - [message]: The error message to display
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Navigates back to the menu screen.
  void _backToMenu() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MenuScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[900]!, Colors.grey[800]!],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game Over Title
                const Text(
                  'GAME OVER',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Final Score Display
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Final Score',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${widget.gameState.score}',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Moves: ${widget.gameState.moves}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Name Input Field
                TextField(
                  controller: _nameController,
                  enabled: !_isSubmitting,
                  maxLength: 3,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'NAME',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 24,
                      letterSpacing: 2,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.white, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.white, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.cyan, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Submit Score Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitScore,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'SUBMIT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                    // Back to Menu Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _backToMenu,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: const Text(
                        'MENU',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
