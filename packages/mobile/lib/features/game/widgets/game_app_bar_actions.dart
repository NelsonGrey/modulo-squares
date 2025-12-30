import 'package:flutter/material.dart';
import 'package:modulo_squares/l10n/app_localizations.dart';

class GameAppBarActions extends StatelessWidget {
  const GameAppBarActions({
    super.key,
    required this.onShowLeaderboard,
    required this.onShowInstructions,
    required this.onShowSpecialTilesInfo,
    required this.onShowPurchaseDialog,
  });

  final VoidCallback onShowLeaderboard;
  final VoidCallback onShowInstructions;
  final VoidCallback onShowSpecialTilesInfo;
  final VoidCallback onShowPurchaseDialog;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.leaderboard),
          onPressed: onShowLeaderboard,
          tooltip: AppLocalizations.of(context).showLeaderboard,
        ),
        IconButton(
          icon: const Icon(Icons.menu_book_outlined),
          onPressed: onShowInstructions,
          tooltip: AppLocalizations.of(context).howToPlay,
        ),
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: onShowSpecialTilesInfo,
          tooltip: 'Special Tiles Info',
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: onShowPurchaseDialog,
          tooltip: 'Remove Ads',
        ),
      ],
    );
  }
}
