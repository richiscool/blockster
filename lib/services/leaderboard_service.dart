// ignore_for_file: avoid_print

import 'package:shared_preferences/shared_preferences.dart';
import '../constants/game_constants.dart';

/// Manages the game's leaderboard persistence.
///
/// Stores player scores using SharedPreferences (local device storage).
/// Maintains a top 10 list sorted by highest scores.
///
/// Data format: Pipe-separated entries stored as a single string.
/// Example: "ALICE|5000;BOB|3500;CHARLIE|2000"
class LeaderboardService {
  /// SharedPreferences key for storing the leaderboard data.
  static const String _leaderboardKey = 'blockster_leaderboard';

  /// Retrieves the current leaderboard entries.
  ///
  /// Returns a list of (name, score) tuples sorted by score (highest first).
  /// If no leaderboard exists, returns an empty list.
  ///
  /// Returns: List of (playerName, score) tuples
  static Future<List<(String, int)>> getLeaderboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_leaderboardKey);

      if (data == null || data.isEmpty) {
        return [];
      }

      // Parse pipe-separated entries
      final entries = data.split(';');
      List<(String, int)> leaderboard = [];

      for (var entry in entries) {
        final parts = entry.split('|');
        if (parts.length == 2) {
          final name = parts[0];
          final score = int.tryParse(parts[1]);
          if (score != null) {
            leaderboard.add((name, score));
          }
        }
      }

      // Sort by score (highest first)
      leaderboard.sort((a, b) => b.$2.compareTo(a.$2));
      return leaderboard;
    } catch (e) {
      print('Error reading leaderboard: $e');
      return [];
    }
  }

  /// Adds a new entry to the leaderboard.
  ///
  /// If the score is in the top [GameConstants.topScoresCount],
  /// the entry is added and the leaderboard is saved.
  ///
  /// Player name is automatically truncated to [GameConstants.maxNameLength] characters.
  ///
  /// Parameters:
  ///   - [playerName]: Name of the player (will be trimmed to max length)
  ///   - [score]: The player's score
  ///
  /// Returns: true if entry was added to leaderboard, false if score didn't make top 10
  static Future<bool> addEntry(String playerName, int score) async {
    try {
      // Trim name to max length
      final trimmedName = playerName.length > GameConstants.maxNameLength
          ? playerName.substring(0, GameConstants.maxNameLength)
          : playerName;

      // Get current leaderboard
      var leaderboard = await getLeaderboard();

      // Add new entry
      leaderboard.add((trimmedName, score));

      // Sort by score (highest first)
      leaderboard.sort((a, b) => b.$2.compareTo(a.$2));

      // Keep only top scores
      if (leaderboard.length > GameConstants.topScoresCount) {
        leaderboard = leaderboard.sublist(0, GameConstants.topScoresCount);
      }

      // Save back to storage
      await _saveLeaderboard(leaderboard);

      return true;
    } catch (e) {
      print('Error adding leaderboard entry: $e');
      return false;
    }
  }

  /// Checks if a score qualifies for the leaderboard.
  ///
  /// A score qualifies if:
  ///   - The leaderboard has fewer than [GameConstants.topScoresCount] entries, OR
  ///   - The score is higher than the lowest score on the leaderboard
  ///
  /// Parameters:
  ///   - [score]: The score to check
  ///
  /// Returns: true if this score would make the top 10, false otherwise
  static Future<bool> isScoreQualifying(int score) async {
    try {
      final leaderboard = await getLeaderboard();

      // Not full yet, any score qualifies
      if (leaderboard.length < GameConstants.topScoresCount) {
        return true;
      }

      // Check if score beats the lowest entry
      if (leaderboard.isNotEmpty) {
        final lowestScore = leaderboard.last.$2;
        return score > lowestScore;
      }

      return false;
    } catch (e) {
      print('Error checking qualifying score: $e');
      return false;
    }
  }

  /// Clears all leaderboard data.
  ///
  /// Used for testing or resetting the game.
  ///
  /// Returns: true if clear was successful, false otherwise
  static Future<bool> clearLeaderboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_leaderboardKey);
      return true;
    } catch (e) {
      print('Error clearing leaderboard: $e');
      return false;
    }
  }

  /// Saves leaderboard entries to persistent storage.
  ///
  /// Internal method used by [addEntry].
  /// Formats entries as pipe-separated values and saves to SharedPreferences.
  ///
  /// Parameters:
  ///   - [leaderboard]: List of (name, score) tuples to save
  static Future<void> _saveLeaderboard(List<(String, int)> leaderboard) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Format as pipe-separated entries
      final data =
          leaderboard.map((entry) => '${entry.$1}|${entry.$2}').join(';');

      await prefs.setString(_leaderboardKey, data);
    } catch (e) {
      print('Error saving leaderboard: $e');
    }
  }

  /// Gets the player's best score on the leaderboard.
  ///
  /// Returns the highest score associated with any entry,
  /// or 0 if the leaderboard is empty.
  ///
  /// Returns: The best score on the leaderboard, or 0
  static Future<int> getBestScore() async {
    try {
      final leaderboard = await getLeaderboard();
      if (leaderboard.isEmpty) {
        return 0;
      }
      return leaderboard.first.$2;
    } catch (e) {
      print('Error getting best score: $e');
      return 0;
    }
  }
}
