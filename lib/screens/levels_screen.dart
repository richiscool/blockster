import 'package:flutter/material.dart';
import 'package:blockster/constants/game_constants.dart';
import 'package:blockster/models/level_data.dart';
import 'package:blockster/screens/game_screen.dart';
import 'package:blockster/services/level_service.dart';

/// Level select screen showing ten levels.
///
/// Level 1 is open from the start. Reaching
/// [GameConstants.pointsToUnlockNextLevel] points in a level unlocks the
/// next one, and unlocked levels can be replayed any time.
class LevelsScreen extends StatefulWidget {
  const LevelsScreen({Key? key}) : super(key: key);

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  int _unlockedLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final unlocked = await LevelService.getUnlockedLevel();
    if (mounted) setState(() => _unlockedLevel = unlocked);
  }

  Future<void> _openLevel(int level) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => GameScreen(level: level)),
    );
    // Refresh in case a new level was unlocked while playing.
    _loadProgress();
  }

  void _showLocked(int level) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Reach ${GameConstants.pointsToUnlockNextLevel} points in '
            'Level ${level - 1} to unlock Level $level',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Levels'), centerTitle: true),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.4,
        ),
        itemCount: GameConstants.levelCount,
        itemBuilder: (context, index) {
          final level = index + 1;
          final unlocked = level <= _unlockedLevel;

          return Material(
            color: unlocked
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: unlocked ? () => _openLevel(level) : () => _showLocked(level),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      unlocked ? Icons.play_circle_fill : Icons.lock,
                      size: 28,
                      color: unlocked
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Level $level',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: unlocked
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${LevelData.startingCells(level)} blocks to start',
                      style: TextStyle(
                        fontSize: 12,
                        color: unlocked
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}