import 'package:flutter/material.dart';
import 'package:modulo_squares/gamecenter/game_center_connection.dart';
import 'package:modulo_squares/gamecenter/game_center_services.dart';

/// One-time invitation to connect, shown on first launch. Either answer is
/// remembered; Settings and the leaderboard button stay available afterward.
Future<void> showGameCenterPrompt(
  BuildContext context,
  GameCenterConnection connection,
) async {
  final connect = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Connect to Game Center?'),
          content: const Text(
            'Post your best score to the leaderboard and earn achievements. '
            'Playing never requires it, and you can change your mind in '
            'Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Connect'),
            ),
          ],
        ),
  );
  if (connect == true) {
    await connection.connect();
  } else {
    await connection.decline();
  }
}

/// Opens Game Center's native leaderboard, connecting first if the player
/// hasn't yet.
Future<void> openGameCenterLeaderboard(
  BuildContext context,
  GameCenterServices gameCenter,
) async {
  final connection = gameCenter.connection;
  if (!connection.supported) {
    _showUnavailable(context, 'Game Center is only available on iPhone.');
    return;
  }
  if (!connection.isConnected) await connection.connect();
  if (connection.isConnected) {
    await gameCenter.progress.showLeaderboard();
  } else if (context.mounted) {
    _showUnavailable(
      context,
      'Game Center is unavailable. Check that you are signed in to Game '
      'Center in iOS Settings, then try again.',
    );
  }
}

void _showUnavailable(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
