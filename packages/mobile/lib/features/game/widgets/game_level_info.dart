import 'package:flutter/material.dart';

class GameLevelInfo extends StatelessWidget {
  const GameLevelInfo({
    super.key,
    required this.level,
    required this.remainingMoves,
    required this.parMoves,
    required this.eliteMoves,
    this.dailyModifierLabel,
  });

  final int level;
  final int remainingMoves;
  final int parMoves;
  final int eliteMoves;
  final String? dailyModifierLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Game level $level, $remainingMoves moves remaining, par $parMoves, elite $eliteMoves',
      child: Column(
        children: [
          Text(
            'Level: $level',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'Moves left: $remainingMoves',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'Targets: Par <= $parMoves, Elite <= $eliteMoves',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          if (dailyModifierLabel != null && dailyModifierLabel!.isNotEmpty)
            Text(
              'Daily Modifier: $dailyModifierLabel',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
