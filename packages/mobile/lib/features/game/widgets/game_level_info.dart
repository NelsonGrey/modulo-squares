import 'package:flutter/material.dart';

class GameLevelInfo extends StatelessWidget {
  const GameLevelInfo({
    super.key,
    required this.level,
    required this.remainingMoves,
  });

  final int level;
  final int remainingMoves;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Game level $level, $remainingMoves moves remaining',
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
        ],
      ),
    );
  }
}
