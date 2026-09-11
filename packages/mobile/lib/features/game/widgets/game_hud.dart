import 'package:flutter/material.dart';
import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';

/// The falling-mode HUD: level / score / best / combo / move-speed / fall
/// timer / range / fill / deficit pills.
///
/// Pure presentation — all values it needs come in as parameters/state
/// rather than reaching into the parent screen's internals.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.state,
    required this.highScore,
    required this.isRunning,
    required this.isSpawnDelayActive,
    required this.effectiveDropIntervalMs,
  });

  final FallingModuloGameState state;
  final int highScore;
  final bool isRunning;
  final bool isSpawnDelayActive;
  final int effectiveDropIntervalMs;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _pill('Level', '${state.level}'),
        _pill('Score', '${state.score}'),
        _pill('Best', '$highScore'),
        _pill('Combo', '${state.combo}'),
        _pill(
          'Move Speed',
          '${state.horizontalMoveSpeedMultiplier.toStringAsFixed(2)}x',
        ),
        _pill(
          'Fall',
          !isRunning
              ? 'Paused'
              : isSpawnDelayActive
              ? 'Ready...'
              : '${(effectiveDropIntervalMs / 1000).toStringAsFixed(2)}s',
        ),
        _pill('Range', '${state.numberRangeMin}-${state.numberRangeMax}'),
        _pill('Fill', '${state.filledSquares}/${state.progressGridCellCount}'),
        if (state.deficitSquares > 0)
          _pill('Deficit', '-${state.deficitSquares}'),
      ],
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      child: Text('$label: $value'),
    );
  }
}
