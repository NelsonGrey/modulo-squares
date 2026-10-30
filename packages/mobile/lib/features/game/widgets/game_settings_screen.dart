import 'package:flutter/material.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';
import 'package:modulo_squares/features/game/models/game_theme.dart';
import 'package:modulo_squares/features/game/widgets/purchase_section.dart';
import 'package:modulo_squares/features/game/widgets/settings_section.dart';
import 'package:modulo_squares/gamecenter/game_center_connection.dart';
import 'package:modulo_squares/gamecenter/game_center_services.dart';
import 'package:modulo_squares/gamecenter/game_center_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the falling-mode Settings page: Appearance, Difficulty, Game Center,
/// Purchases and Legal. The layout, section order and wording match the
/// Memory Survival and Intercept Echo Settings screens.
///
/// Changes apply as soon as they are made (there is no Save/Cancel), so the
/// caller's [onSaveDifficulty] and [onSaveTheme] fire on every change.
///
/// It does not own the game-loop timer or core game state -- those stay on
/// [FallingModuloGameScreen] -- so the caller passes in the current difficulty,
/// a live getter for the high score, plus a couple of callbacks to report
/// changes back up.
Future<void> showGameSettings({
  required BuildContext context,
  required GameDifficulty difficulty,
  required int Function() getHighScore,
  required PurchaseService? purchaseService,
  required ValueChanged<GameDifficulty> onSaveDifficulty,
  required GameThemeId themeId,
  required ValueChanged<GameThemeId> onSaveTheme,
  GameCenterServices? gameCenter,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder:
          (_) => _GameSettingsScreen(
            difficulty: difficulty,
            getHighScore: getHighScore,
            purchaseService: purchaseService,
            onSaveDifficulty: onSaveDifficulty,
            themeId: themeId,
            onSaveTheme: onSaveTheme,
            gameCenter: gameCenter,
          ),
    ),
  );
}

class _GameSettingsScreen extends StatefulWidget {
  const _GameSettingsScreen({
    required this.difficulty,
    required this.getHighScore,
    required this.purchaseService,
    required this.onSaveDifficulty,
    required this.themeId,
    required this.onSaveTheme,
    required this.gameCenter,
  });

  final GameDifficulty difficulty;
  final int Function() getHighScore;
  final PurchaseService? purchaseService;
  final ValueChanged<GameDifficulty> onSaveDifficulty;
  final GameThemeId themeId;
  final ValueChanged<GameThemeId> onSaveTheme;
  final GameCenterServices? gameCenter;

  @override
  State<_GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends State<_GameSettingsScreen> {
  late GameDifficulty _difficulty = widget.difficulty;
  late GameThemeId _themeId = widget.themeId;
  late bool _adsRemoved = widget.purchaseService?.adsRemoved ?? false;

  static String _difficultyBlurb(GameDifficulty d) => switch (d) {
    GameDifficulty.easy => 'The falling number speeds up slowly.',
    GameDifficulty.normal => 'The falling number speeds up at a steady pace.',
    GameDifficulty.hard => 'The falling number speeds up quickly.',
  };

  static String _difficultyLabel(GameDifficulty d) => switch (d) {
    GameDifficulty.easy => 'Easy',
    GameDifficulty.normal => 'Normal',
    GameDifficulty.hard => 'Hard',
  };

  @override
  Widget build(BuildContext context) {
    final purchaseService = widget.purchaseService;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const SettingsSectionHeader('Appearance'),
          for (final id in gameThemeOrder)
            _PaletteTile(
              id: id,
              palette: gameThemePalettes[id]!,
              selected: id == _themeId,
              onTap: () {
                setState(() => _themeId = id);
                widget.onSaveTheme(id);
              },
            ),
          const SizedBox(height: 16),
          const SettingsSectionHeader('Difficulty'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<GameDifficulty>(
              segments: [
                for (final d in GameDifficulty.values)
                  ButtonSegment(value: d, label: Text(_difficultyLabel(d))),
              ],
              selected: {_difficulty},
              onSelectionChanged: (selection) {
                setState(() => _difficulty = selection.first);
                widget.onSaveDifficulty(_difficulty);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(_difficultyBlurb(_difficulty)),
          ),
          ListTile(
            title: const Text('Best Score'),
            trailing: Text(
              '${widget.getHighScore()}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.gameCenter case final gameCenter?
              when gameCenter.connection.supported) ...[
            const SettingsSectionHeader('Game Center'),
            _GameCenterTiles(gameCenter: gameCenter),
          ],
          if (purchaseService != null) ...[
            const SizedBox(height: 16),
            PurchaseSection(
              purchaseService: purchaseService,
              adsRemoved: _adsRemoved,
              onAdsRemovedChanged:
                  (value) => setState(() => _adsRemoved = value),
            ),
          ],
          const SizedBox(height: 16),
          const SettingsSectionHeader('Legal'),
          _LegalLink(label: 'Privacy Policy', path: 'privacy'),
          _LegalLink(label: 'Terms of Use', path: 'terms'),
          _LegalLink(label: 'Support', path: 'support'),
        ],
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.path});

  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => _openLegalLink(path),
    );
  }
}

/// One palette in the Appearance list: a miniature of its board gradient, its
/// name and a check on the selected one.
class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.id,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final GameThemeId id;
  final GameThemePalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('theme-swatch-${id.name}'),
      onTap: onTap,
      selected: selected,
      minTileHeight: 64,
      leading: ExcludeSemantics(
        child: Container(
          width: 72,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.boardGradientFrom, palette.boardGradientTo],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
          ),
        ),
      ),
      title: Text(palette.name),
      trailing: selected ? const Icon(Icons.check) : null,
    );
  }
}

Future<void> _openLegalLink(String path) async {
  final uri = Uri.parse('https://nelsongrey.com/games/modulo-squares/$path');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Game Center connection status with the leaderboard and achievements
/// shortcuts. Rebuilds as the connection changes.
class _GameCenterTiles extends StatelessWidget {
  const _GameCenterTiles({required this.gameCenter});

  final GameCenterServices gameCenter;

  @override
  Widget build(BuildContext context) {
    final connection = gameCenter.connection;
    return ListenableBuilder(
      listenable: connection,
      builder: (context, _) {
        return Column(
          children: [
            switch (connection.status) {
              GameCenterStatus.connected => ListTile(
                leading: const Icon(Icons.sports_esports),
                title: Text(connection.playerName ?? 'Game Center'),
                subtitle: const Text('Connected'),
                trailing: TextButton(
                  onPressed: connection.disconnect,
                  child: const Text('Disconnect'),
                ),
              ),
              GameCenterStatus.connecting => const ListTile(
                leading: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                title: Text('Connecting to Game Center...'),
              ),
              GameCenterStatus.unavailable => ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Game Center unavailable'),
                subtitle: const Text(
                  'Check that you are signed in to Game Center in iOS '
                  'Settings. Tap to retry.',
                ),
                onTap: connection.connect,
              ),
              GameCenterStatus.off => ListTile(
                leading: const Icon(Icons.sports_esports_outlined),
                title: const Text('Connect Game Center'),
                subtitle: const Text(
                  'Post your best score and earn achievements.',
                ),
                onTap: connection.connect,
              ),
            },
            if (connection.isConnected) ...[
              ListTile(
                leading: const Icon(Icons.leaderboard),
                title: const Text('Leaderboard'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openGameCenterLeaderboard(context, gameCenter),
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events),
                title: const Text('Achievements'),
                trailing: const Icon(Icons.chevron_right),
                onTap: gameCenter.progress.showAchievements,
              ),
            ],
          ],
        );
      },
    );
  }
}
