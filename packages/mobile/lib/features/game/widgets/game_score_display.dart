import 'package:flutter/material.dart';
import 'package:modulo_squares/l10n/app_localizations.dart';

class GameScoreDisplay extends StatelessWidget {
  const GameScoreDisplay({
    super.key,
    required this.currentScore,
    required this.highScore,
  });

  final int currentScore;
  final int highScore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: 'Current score: $currentScore, High score: $highScore',
      child: Text(
        '${l10n.score} $currentScore ${l10n.highScore} $highScore',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
