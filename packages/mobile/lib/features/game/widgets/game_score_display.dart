import 'package:flutter/material.dart';
import 'package:modulo/l10n/app_localizations.dart';

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
    return Semantics(
      label: 'Current score: $currentScore, High score: $highScore',
      child: Text(
        '${AppLocalizations.of(context).score} $currentScore ${AppLocalizations.of(context).highScore} $highScore',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
