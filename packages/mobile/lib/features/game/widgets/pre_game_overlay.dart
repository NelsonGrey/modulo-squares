import 'package:flutter/material.dart';

import 'package:modulo_squares/features/game/models/game_theme.dart';

/// The full-screen rules-and-"Start Game" overlay shown before the first
/// run of a fresh game screen (as opposed to [PauseOverlay], which covers
/// pausing mid-run).
///
/// Pure presentation: the parent screen owns the actual game-loop state and
/// passes in the theme plus the two actions this overlay can trigger.
class PreGameOverlay extends StatelessWidget {
  const PreGameOverlay({
    super.key,
    required this.theme,
    required this.onStart,
    required this.onShowHowToPlay,
  });

  final GameThemePalette theme;
  final VoidCallback onStart;
  final VoidCallback onShowHowToPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(12),
      ),
      // SingleChildScrollView gives its child unbounded height in the scroll
      // direction, so a bare Align would shrink-wrap and render pinned to
      // the top instead of positioning within the overlay. LayoutBuilder +
      // a minHeight constraint forces the content to be at least as tall as
      // the visible area (so Align has room to work with) while still
      // allowing it to grow taller and scroll if content ever overflows a
      // small screen. Align (rather than Center) biases the block toward
      // the top so the Start Game button sits higher, not dead-center.
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Align(
                alignment: const Alignment(0, -0.35),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Modulo Squares',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _OverlayRule(
                        icon: Icons.arrow_downward,
                        text:
                            'A number falls — guide it left or right into a bucket',
                        accent: theme.buttonPrimaryBg,
                      ),
                      const SizedBox(height: 8),
                      _OverlayRule(
                        icon: Icons.calculate_outlined,
                        text:
                            'Land it where the number is divisible by the bucket value',
                        accent: theme.buttonPrimaryBg,
                      ),
                      const SizedBox(height: 8),
                      _OverlayRule(
                        icon: Icons.grid_on_outlined,
                        text:
                            'Fill 100 squares to level up — wrong buckets cost points, the Dead bucket costs your tile value',
                        accent: theme.buttonPrimaryBg,
                      ),
                      const SizedBox(height: 8),
                      _OverlayRule(
                        icon: Icons.star,
                        text:
                            'Find the bucket with the biggest number that still divides evenly for a Bonus — extra score and double fill',
                        accent: theme.buttonPrimaryBg,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: onStart,
                        icon: const Icon(Icons.play_arrow, size: 22),
                        label: const Text(
                          'Start Game',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(200, 52),
                          backgroundColor: theme.buttonPrimaryBg,
                          foregroundColor: theme.buttonPrimaryFg,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: onShowHowToPlay,
                        icon: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.buttonPrimaryBg,
                        ),
                        label: Text(
                          'How to Play',
                          style: TextStyle(color: theme.buttonPrimaryBg),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OverlayRule extends StatelessWidget {
  const _OverlayRule({
    required this.icon,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
