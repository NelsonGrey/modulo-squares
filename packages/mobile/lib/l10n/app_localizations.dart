import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate = AppLocalizationsDelegate();

  String get appTitle => Intl.message('Modulo Squares', name: 'appTitle');
  String get profile => Intl.message('Profile', name: 'profile');
  String get signOut => Intl.message('Sign Out', name: 'signOut');
  String get name => Intl.message('Name', name: 'name');
  String get email => Intl.message('Email', name: 'email');
  String get uid => Intl.message('UID', name: 'uid');
  String get difficultyLevel => Intl.message('Difficulty Level:', name: 'difficultyLevel');
  String get score => Intl.message('Score:', name: 'score');
  String get highScore => Intl.message('High Score:', name: 'highScore');
  String get restart => Intl.message('Restart', name: 'restart');
  String get youWin => Intl.message('You Win!', name: 'youWin');
  String winMessage(int score) => Intl.message(
        'Congratulations, you cleared the board! Score: $score',
        name: 'winMessage',
        args: [score],
        examples: const {'score': 42},
      );
  String get gameOver => Intl.message('Game Over', name: 'gameOver');
  String gameOverMessage(int score) => Intl.message(
        'No more valid moves available. Score: $score',
        name: 'gameOverMessage',
        args: [score],
        examples: const {'score': 42},
      );
  String get enterName => Intl.message('Enter your name to submit score:', name: 'enterName');
  String get yourName => Intl.message('Your name', name: 'yourName');
  String get submitScore => Intl.message('Submit Score', name: 'submitScore');
  String get playAgain => Intl.message('Play Again', name: 'playAgain');
  String get globalLeaderboard => Intl.message('Global Leaderboard', name: 'globalLeaderboard');
  String get noScoresYet => Intl.message('No scores yet', name: 'noScoresYet');
  String get close => Intl.message('Close', name: 'close');
  String get showLeaderboard => Intl.message('Show Leaderboard', name: 'showLeaderboard');
  String mercyHelperSpawned(int penalty) => Intl.message(
        'Helper tile spawned (−$penalty points).',
        name: 'mercyHelperSpawned',
        args: [penalty],
        examples: const {'penalty': 5},
      );
  // Special Tiles
  String get specialTilesTitle => Intl.message('Special Tiles', name: 'specialTilesTitle');
  String get obstacleTitle => Intl.message('Obstacle', name: 'obstacleTitle');
  String get obstacleSubtitle => Intl.message('Blocks movement.', name: 'obstacleSubtitle');
  String get bonusTitle => Intl.message('Bonus', name: 'bonusTitle');
  String get bonusSubtitle => Intl.message('Gives bonus points when you collide into it.', name: 'bonusSubtitle');
  String get obstacleTooltip => Intl.message('Obstacle: Blocks movement.', name: 'obstacleTooltip');
  String get bonusTooltip => Intl.message('Bonus: Bonus points on collision!', name: 'bonusTooltip');

  // Instructions Page
  String get howToPlay => Intl.message('How to Play', name: 'howToPlay');
  String get instructionsTitle => Intl.message('How to Play Modulo', name: 'instructionsTitle');
  String get objectiveTitle => Intl.message('Objective', name: 'objectiveTitle');
  String get objectiveBody =>
      Intl.message('Clear the board by strategically combining tiles using modulo rules to maximize your score before you run out of moves.',
          name: 'objectiveBody');
  String get controlsTitle => Intl.message('Controls', name: 'controlsTitle');
  String get controlsBody =>
      Intl.message('Tap a tile and then tap an adjacent tile to move into it. Or swipe a tile to slide it until it hits another tile or the edge.',
          name: 'controlsBody');
  String get moduloRuleTitle => Intl.message('Modulo Rule', name: 'moduloRuleTitle');
  String get moduloRuleBody => Intl.message(
      'When a source tile moves into a target tile: If target % source == 0, both tiles clear. Otherwise, the target becomes (target + source) × (target % source), and the source respawns as a new random tile.',
      name: 'moduloRuleBody');
  String get specialTilesTitle2 => Intl.message('Special Tiles', name: 'specialTilesTitle2');
  String get specialTilesBody =>
      Intl.message('Obstacle blocks movement; you can’t enter or move it. Bonus grants extra points when you collide into it.', name: 'specialTilesBody');
  String get levelsTitle => Intl.message('Levels & Grid Size', name: 'levelsTitle');
  String get levelsBody =>
      Intl.message('Levels 1–10 increase the grid size from 4×4 up to 13×13 (4 + level − 1). Higher levels mean more space and challenge.', name: 'levelsBody');
  String get mercyTitle => Intl.message('Last-Tile Mercy', name: 'mercyTitle');
  String get mercyBody => Intl.message(
      'If exactly one tile remains and you still have moves, a helper tile may spawn with a small score penalty and an extra move cost to keep the game going.',
      name: 'mercyBody');
  String get scoringTitle => Intl.message('Scoring & Moves', name: 'scoringTitle');
  String get scoringBody => Intl.message(
      'Each successful collision gives +1 point, plus +5 extra if you collide into a Bonus tile. Plan your moves to conserve your limited moves and maximize score.',
      name: 'scoringBody');
  String get leaderboardTitle => Intl.message('Leaderboard', name: 'leaderboardTitle');
  String get leaderboardBody => Intl.message('Sign in and submit your high score to the global leaderboard to compete with others.', name: 'leaderboardBody');
  String get tipsTitle => Intl.message('Tips', name: 'tipsTitle');
  String get tipsBody => Intl.message(
      'Look for zero-remainder opportunities to clear spaces. Use Bonus tiles to spike your score. Avoid getting trapped by obstacles—keep paths open.',
      name: 'tipsBody');

  // Instruction visuals & captions
  String get legendTitle => Intl.message('Legend', name: 'legendTitle');
  String get gridPreviewTitle => Intl.message('Board Preview', name: 'gridPreviewTitle');
  String get moduloExamplesTitle => Intl.message('Modulo Examples', name: 'moduloExamplesTitle');
  String get tapLabel => Intl.message('Tap', name: 'tapLabel');
  String get swipeLabel => Intl.message('Swipe', name: 'swipeLabel');
  String get normalTitle => Intl.message('Normal', name: 'normalTitle');
  String get normalSubtitle => Intl.message('Regular numbered tile.', name: 'normalSubtitle');
  String get moduloExampleClearCaption => Intl.message('12 % 3 = 0 → both clear', name: 'moduloExampleClearCaption');
  String get moduloExampleTransformCaption => Intl.message('12 % 5 = 2 → (12 + 5) × 2 = 34; source respawns', name: 'moduloExampleTransformCaption');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    Intl.defaultLocale = locale.languageCode;
    return AppLocalizations();
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
