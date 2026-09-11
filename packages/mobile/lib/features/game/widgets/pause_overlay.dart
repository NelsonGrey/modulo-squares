import 'package:flutter/material.dart';

/// The full-screen "Paused" overlay shown over the board while the game
/// loop is stopped mid-run (as opposed to the pre-game "Start Game"
/// overlay, which is a separate state).
///
/// Pure presentation: the parent screen owns the actual game-loop timer and
/// passes in the values to display plus the two actions this overlay can
/// trigger.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.level,
    required this.score,
    required this.onResume,
    required this.onNewGame,
  });

  final int level;
  final int score;
  final VoidCallback onResume;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      // SingleChildScrollView gives its child unbounded height in the scroll
      // direction, so a bare Center would shrink-wrap and render pinned to
      // the top instead of actually centering. LayoutBuilder + a minHeight
      // constraint forces the content to be at least as tall as the visible
      // area (so Center has room to center) while still allowing it to grow
      // taller and scroll if content ever overflows a small screen.
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pause_circle_filled_outlined,
                      size: 72,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Paused',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Level $level  ·  Score $score',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: onResume,
                      icon: const Icon(Icons.play_arrow, size: 22),
                      label: const Text(
                        'Resume',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(180, 52),
                        backgroundColor: Colors.lightBlue.shade400,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: onNewGame,
                      icon: const Icon(Icons.replay, size: 20),
                      label: const Text('New Game'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        minimumSize: const Size(180, 48),
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
