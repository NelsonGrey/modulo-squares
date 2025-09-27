import 'package:flutter/material.dart';
import '../models/game_board.dart';

class GridCellWidget extends StatelessWidget {
  final Tile tile;
  final bool isSelected;
  final bool isPossibleTarget;
  final bool justChanged;

  const GridCellWidget({
    super.key,
    required this.tile,
    required this.isSelected,
    this.isPossibleTarget = false,
    this.justChanged = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color tileColor = theme.colorScheme.secondaryContainer;
    IconData? icon;
    String? text;
    Color textColor = theme.colorScheme.onSurface;

    switch (tile.type) {
      case TileType.locked:
        tileColor = Colors.grey.shade700;
        icon = Icons.lock;
        break;
      case TileType.obstacle:
        tileColor = Colors.black87;
        icon = Icons.block;
        break;
      case TileType.multiplier:
        tileColor = Colors.greenAccent.shade700;
        text = tile.value?.toString();
        icon = Icons.star;
        break;
      case TileType.poison:
        tileColor = Colors.redAccent.shade700;
        text = tile.value?.toString();
        icon = Icons.warning;
        break;
      case TileType.freeze:
        tileColor = Colors.blueAccent.shade700;
        text = tile.value?.toString();
        icon = Icons.ac_unit;
        break;
      case TileType.normal:
        tileColor = theme.colorScheme.secondaryContainer;
        text = tile.value?.toString();
        break;
    }
    if (isSelected) {
      tileColor = theme.colorScheme.primaryContainer;
    }

    return SizedBox.expand(
      child: Stack(
        children: [
          // Base cell
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline, width: 0.5),
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),
          // Tile
          if (tile.value != null || tile.type == TileType.locked || tile.type == TileType.obstacle)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Center(
                  child: icon != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: textColor, size: 24),
                            if (text != null)
                              Text(
                                text,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                          ],
                        )
                      : (text != null
                          ? Text(
                              text,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            )
                          : const SizedBox()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
