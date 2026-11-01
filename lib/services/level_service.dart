import 'package:shared_preferences/shared_preferences.dart';
import '../constants/game_constants.dart';

/// Tracks which levels the player has unlocked (saved on the device).
///
/// Level 1 is always unlocked. Reaching
/// [GameConstants.pointsToUnlockNextLevel] points in a level unlocks the next.
abstract class LevelService {
  static const String _key = 'blockster_unlocked_level';

  /// Highest unlocked level (1 to [GameConstants.levelCount]).
  static Future<int> getUnlockedLevel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getInt(_key) ?? 1;
      return value.clamp(1, GameConstants.levelCount);
    } catch (_) {
      return 1;
    }
  }

  /// Marks [level] as beaten and unlocks the next one.
  ///
  /// Returns true if a new level was unlocked by this call.
  static Future<bool> completeLevel(int level) async {
    try {
      final current = await getUnlockedLevel();
      final next = (level + 1).clamp(1, GameConstants.levelCount);
      if (next > current) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_key, next);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
