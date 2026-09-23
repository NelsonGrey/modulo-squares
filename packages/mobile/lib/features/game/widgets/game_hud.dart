import 'package:flutter/material.dart';
import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';
import 'package:modulo_squares/features/game/models/game_theme.dart';

/// The falling-mode HUD: a hero score/best row, a level-progress bar, and a
/// balanced grid of uniform icon chips for the remaining stats (combo,
/// difficulty, fall speed, move speed, range, and deficit).
///
/// Pure presentation — all values it needs come in as parameters/state
/// rather than reaching into the parent screen's internals. Colors come
/// from [theme] rather than being hardcoded, so a palette change recolors
/// the HUD without touching this widget.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.state,
    required this.highScore,
    required this.isRunning,
    required this.isSpawnDelayActive,
    required this.effectiveDropIntervalMs,
    required this.theme,
  });

  final FallingModuloGameState state;
  final int highScore;
  final bool isRunning;
  final bool isSpawnDelayActive;
  final int effectiveDropIntervalMs;
  final GameThemePalette theme;

  String get _fallLabel {
    if (!isRunning) return 'Paused';
    if (isSpawnDelayActive) return 'Ready...';
    return '${(effectiveDropIntervalMs / 1000).toStringAsFixed(2)}s';
  }

  String _difficultyLabel(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return 'Easy';
      case GameDifficulty.normal:
        return 'Normal';
      case GameDifficulty.hard:
        return 'Hard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fillFraction =
        state.progressGridCellCount == 0
            ? 0.0
            : (state.filledSquares / state.progressGridCellCount).clamp(
              0.0,
              1.0,
            );

    final chips = <_HudChipData>[
      _HudChipData(
        key: const Key('hud-combo-value'),
        icon: Icons.local_fire_department,
        label: 'Combo',
        value: '${state.combo}',
        bg: theme.chipCombo.bg,
        fg: theme.chipCombo.fg,
      ),
      _HudChipData(
        key: const Key('hud-difficulty-value'),
        icon: Icons.speed,
        label: 'Difficulty',
        value: _difficultyLabel(state.difficulty),
        bg: theme.chipDifficulty.bg,
        fg: theme.chipDifficulty.fg,
      ),
      _HudChipData(
        key: const Key('hud-fall-value'),
        icon: Icons.bolt,
        label: 'Fall speed',
        value: _fallLabel,
        bg: theme.chipFall.bg,
        fg: theme.chipFall.fg,
      ),
      _HudChipData(
        key: const Key('hud-move-speed-value'),
        icon: Icons.swap_horiz,
        label: 'Move speed',
        value: '${state.horizontalMoveSpeedMultiplier.toStringAsFixed(2)}x',
        bg: theme.chipMove.bg,
        fg: theme.chipMove.fg,
      ),
      _HudChipData(
        key: const Key('hud-range-value'),
        icon: Icons.straighten,
        label: 'Number range',
        value: '${state.numberRangeMin}-${state.numberRangeMax}',
        bg: theme.chipRange.bg,
        fg: theme.chipRange.fg,
      ),
      _HudChipData(
        key: const Key('hud-deficit-value'),
        icon: Icons.warning_amber_rounded,
        label: 'Deficit',
        value:
            state.deficitSquares > 0 ? '-${state.deficitSquares}' : '0',
        bg: theme.chipDeficit.bg,
        fg: theme.chipDeficit.fg,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero row: current score is the dominant number, best is secondary.
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow('Score'),
                Text(
                  '${state.score}',
                  key: const Key('hud-score-value'),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _eyebrow('Best'),
                  Text(
                    '$highScore',
                    key: const Key('hud-best-value'),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: theme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Level progress bar.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level ${state.level}',
              key: const Key('hud-level-value'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
            ),
            Text(
              '${state.filledSquares} / ${state.progressGridCellCount}',
              key: const Key('hud-fill-value'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fillFraction,
            minHeight: 8,
            backgroundColor: theme.progressTrack,
            valueColor: AlwaysStoppedAnimation(theme.progressFill),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary stats: uniform, balanced icon chips, 3 per row.
        _chipGrid(chips),
      ],
    );
  }

  Widget _eyebrow(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: theme.textMuted,
      ),
    );
  }

  Widget _chipGrid(List<_HudChipData> chips) {
    const perRow = 3;
    final rows = <Widget>[];
    for (var i = 0; i < chips.length; i += perRow) {
      final rowChips = chips.skip(i).take(perRow).toList();
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
          child: Row(
            children: [
              for (var j = 0; j < perRow; j++) ...[
                if (j > 0) const SizedBox(width: 8),
                Expanded(
                  child:
                      j < rowChips.length
                          ? _HudChip(data: rowChips[j])
                          : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _HudChipData {
  const _HudChipData({
    this.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
  });

  final Key? key;
  final IconData icon;

  /// What this chip's value means (Combo, Difficulty, ...) -- announced by
  /// assistive tech via [Semantics] in [_HudChip], since the bare on-screen
  /// value next to a decorative icon (e.g. "1", "6.00s") doesn't say what
  /// it's a value *of*.
  final String label;
  final String value;
  final Color bg;
  final Color fg;
}

class _HudChip extends StatelessWidget {
  const _HudChip({required this.data});

  final _HudChipData data;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${data.label}: ${data.value}',
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: data.bg,
          borderRadius: BorderRadius.circular(999),
        ),
        // The wrapping Semantics above already announces "<label>: <value>"
        // as one unit -- without this, the icon (if it ever gains an
        // implicit label) and the bare value Text would also be exposed
        // individually, announcing the value twice.
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.icon, size: 19, color: data.fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  data.value,
                  key: data.key,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: data.fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
