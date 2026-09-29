import 'dart:io' show Platform;
import 'package:vibration/vibration.dart';
import 'package:blockster/constants/game_constants.dart';

/// Provides haptic (vibration) feedback for game events.
///
/// Automatically handles platform availability — vibrations are skipped
/// gracefully on devices that don't support them.
///
/// Usage:
/// ```dart
/// HapticFeedbackService.blockPlaced();  // Placed a block
/// HapticFeedbackService.lineCleared();  // Cleared a line
/// HapticFeedbackService.gameOver();     // Game ended
/// ```
abstract class HapticFeedbackService {
  /// Whether vibration is available on this device.
  ///
  /// Cached on first call for performance.
  static bool? _isVibrationAvailable;

  /// Checks if the device supports vibrations (cached).
  ///
  /// Returns: true if vibration is available, false otherwise
  ///
  /// On iOS, always returns false (iOS doesn't support vibration API).
  /// On Android, queries the Vibration plugin.
  static Future<bool> _checkVibrationAvailable() async {
    if (_isVibrationAvailable != null) {
      return _isVibrationAvailable!;
    }

    try {
      // iOS doesn't support vibration
      if (Platform.isIOS) {
        _isVibrationAvailable = false;
      } else {
        _isVibrationAvailable = await Vibration.hasVibrator();
      }
    } catch (e) {
      // If there's any error, assume no vibration support
      _isVibrationAvailable = false;
    }

    return _isVibrationAvailable!;
  }

  /// Short vibration when a block is successfully placed.
  ///
  /// Duration: 50ms
  /// Useful feedback for confirming block placement.
  static Future<void> blockPlaced() async {
    if (await _checkVibrationAvailable()) {
      try {
        await Vibration.vibrate(
          duration: GameConstants.blockPlacedVibrationDuration,
        );
      } catch (e) {
        // Silently ignore vibration errors
      }
    }
  }

  /// Medium vibration when a line or column is cleared.
  ///
  /// Duration: 100ms
  /// Stronger than block placement to celebrate the achievement.
  static Future<void> lineCleared() async {
    if (await _checkVibrationAvailable()) {
      try {
        await Vibration.vibrate(
          duration: GameConstants.lineClearedVibrationDuration,
        );
      } catch (e) {
        // Silently ignore vibration errors
      }
    }
  }

  /// Long vibration when the game ends.
  ///
  /// Duration: 200ms
  /// Strong feedback to mark the end of gameplay.
  static Future<void> gameOver() async {
    if (await _checkVibrationAvailable()) {
      try {
        await Vibration.vibrate(
          duration: GameConstants.gameOverVibrationDuration,
        );
      } catch (e) {
        // Silently ignore vibration errors
      }
    }
  }

  /// Custom vibration with a specific duration.
  ///
  /// Parameters:
  ///   - [durationMs]: Vibration length in milliseconds
  ///
  /// Useful for custom game events beyond the standard three.
  static Future<void> custom({required int durationMs}) async {
    if (await _checkVibrationAvailable()) {
      try {
        await Vibration.vibrate(duration: durationMs);
      } catch (e) {
        // Silently ignore vibration errors
      }
    }
  }

  /// Pattern vibration (rapid pulses).
  ///
  /// Creates a series of short vibrations separated by pauses.
  /// Useful for alerts or special events.
  ///
  /// Parameters:
  ///   - [count]: Number of vibration pulses
  ///   - [pulseMs]: Duration of each pulse
  ///   - [pauseMs]: Duration between pulses
  static Future<void> pattern({
    required int count,
    int pulseMs = 50,
    int pauseMs = 50,
  }) async {
    if (await _checkVibrationAvailable()) {
      try {
        for (int i = 0; i < count; i++) {
          await Vibration.vibrate(duration: pulseMs);
          if (i < count - 1) {
            await Future.delayed(Duration(milliseconds: pauseMs));
          }
        }
      } catch (e) {
        // Silently ignore vibration errors
      }
    }
  }
}
