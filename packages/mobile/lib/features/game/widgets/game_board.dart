import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';
import 'package:modulo_squares/features/game/models/game_theme.dart';

/// The falling-mode board: the themed gradient background, the 10x10
/// progress grid, the ten buckets, the falling tile, and the floating
/// score-burst pill -- everything inside the big [Stack] that used to live
/// directly in `FallingModuloGameScreen.build()`.
///
/// Pure presentation, like [GameHud] and [PauseOverlay]: every value it
/// needs comes in as a parameter rather than reaching into the screen's
/// state, so it renders identically whether driven by the real game loop or
/// a test's hand-built state.
class GameBoard extends StatelessWidget {
  const GameBoard({
    super.key,
    required this.state,
    required this.theme,
    required this.dropProgress,
    required this.resultBurstText,
    required this.resultBurstPositive,
    required this.resultBurstBonus,
  });

  final FallingModuloGameState state;
  final GameThemePalette theme;
  final double dropProgress;
  final String? resultBurstText;
  final bool resultBurstPositive;
  final bool resultBurstBonus;

  // Shared by the progress grid's own row spacing and the single gap between
  // the grid and the bucket row below it, so that gap always reads as "one
  // more row spacing" rather than a separately-tuned value.
  static const double _gridCellSpacing = 2;
  // A deliberately generous estimate of the bucket row's rendered height
  // (margin + padding + content) -- used only to size the grid's available
  // height so it never overflows the board's top edge. Overestimating here
  // just leaves a few unused pixels above the grid; underestimating would
  // let the grid overflow again, so this errs generous.
  static const double _bucketRowHeightEstimate = 60;
  // Empty space reserved at the board's top edge, above the progress grid,
  // so the floating score-burst pill has its own breathing room instead of
  // floating directly over the grid's top rows.
  static const double _scoreBurstGutterHeight = 64;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final laneWidth =
            constraints.maxWidth / FallingModuloGameEngine.laneCount;
        final tileSize = laneWidth.clamp(24.0, 40.0);
        final bucketTop = constraints.maxHeight - _bucketRowHeightEstimate;
        final fallTop = dropProgress * (bucketTop - tileSize);

        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [theme.boardGradientFrom, theme.boardGradientTo],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            // The grid and the bucket row are laid out as one bottom-anchored
            // block with an explicit spacer between them, rather than two
            // independently positioned pieces with separately-tuned offsets
            // -- that was what let the gap between them drift out of sync
            // with the grid's own row spacing.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ProgressGrid(
                    state: state,
                    theme: theme,
                    totalWidth: constraints.maxWidth,
                    // Ceiling the grid's own height must respect so all 10
                    // rows stay on-screen: total board height, minus the
                    // bucket row below, minus the one spacing gap above the
                    // bucket row, minus the score-burst gutter reserved at
                    // the board's top edge.
                    availableHeight:
                        constraints.maxHeight -
                        _bucketRowHeightEstimate -
                        _gridCellSpacing -
                        _scoreBurstGutterHeight,
                    cellSpacing: _gridCellSpacing,
                  ),
                  const SizedBox(height: _gridCellSpacing),
                  Row(
                    children: List<Widget>.generate(
                      state.bucketValues.length,
                      (index) => SizedBox(
                        width: laneWidth,
                        child: _Bucket(
                          value: state.bucketValues[index],
                          selected: index == state.currentLane,
                          theme: theme,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left:
                  (state.currentLane * laneWidth) +
                  ((laneWidth - tileSize) / 2),
              top: fallTop,
              child: _FallingTile(
                value: state.currentFallingValue,
                size: tileSize,
                theme: theme,
              ),
            ),
            if (resultBurstText != null)
              Positioned(
                top: 18,
                left: 0,
                right: 0,
                child: Center(
                  child: _AnimatedScoreBurst(
                    text: resultBurstText!,
                    positive: resultBurstPositive,
                    bonus: resultBurstBonus,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProgressGrid extends StatelessWidget {
  const _ProgressGrid({
    required this.state,
    required this.theme,
    required this.totalWidth,
    required this.availableHeight,
    required this.cellSpacing,
  });

  final FallingModuloGameState state;
  final GameThemePalette theme;
  final double totalWidth;
  final double availableHeight;
  final double cellSpacing;

  @override
  Widget build(BuildContext context) {
    const int columns = 10;
    const int rows = 10;
    final filled = state.filledSquares;
    final deficit = state.deficitSquares;

    // Column width is locked to exactly the same lane width the buckets
    // below use (totalWidth / laneCount, with no cross-axis spacing eating
    // into it) so every grid column lines up with its bucket. Row height is
    // free to shrink independently to whatever fits the vertical room
    // available above the buckets, so cells go rectangular rather than
    // square when height is the tighter constraint -- alignment with the
    // buckets wins over keeping cells square.
    final columnWidth = totalWidth / columns;
    final rowHeight = ((availableHeight - (cellSpacing * (rows - 1))) / rows)
        .clamp(8.0, 36.0);

    bool isFilledCell(int row, int col) {
      final orderFromBottomLeft = ((rows - 1 - row) * columns) + col;
      return orderFromBottomLeft < filled;
    }

    return SizedBox(
      key: const Key('progress-grid'),
      width: totalWidth,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows * columns,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: cellSpacing,
          crossAxisSpacing: 0,
          childAspectRatio: columnWidth / rowHeight,
        ),
        itemBuilder: (context, index) {
          final row = index ~/ columns;
          final col = index % columns;
          final isDeficitCell = row == rows - 1 && col == 0 && deficit > 0;
          final filledCell = isFilledCell(row, col);

          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Unfilled cells stay mostly transparent (just a faint tinted
              // outline) so the themed board gradient still reads through
              // cleanly -- filled cells are fully opaque and saturated
              // (green is semantic "progress", not swapped per theme) so
              // progress clearly pops instead of blending in.
              color: filledCell ? theme.gridFilledBg : theme.gridUnfilledBg,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: theme.gridUnfilledBorder),
            ),
            child:
                isDeficitCell
                    ? Text(
                      '-$deficit',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF221B37),
                        fontSize: math.min(columnWidth, rowHeight) < 14 ? 7 : 9,
                      ),
                    )
                    : null,
          );
        },
      ),
    );
  }
}

class _Bucket extends StatelessWidget {
  const _Bucket({
    required this.value,
    required this.selected,
    required this.theme,
  });

  final int value;
  final bool selected;
  final GameThemePalette theme;

  @override
  Widget build(BuildContext context) {
    final isDead = value == 0;

    final Color bgColor;
    final Color borderColor;
    if (isDead) {
      // The Dead bucket still needs a visibly different look when it's the
      // selected lane (so a player parked on it doesn't lose lane feedback)
      // -- lightened toward white rather than a second themed color, so
      // this works for every palette without its own selected-dead tokens.
      bgColor =
          selected
              ? Color.lerp(theme.deadBg, Colors.white, 0.18)!
              : theme.deadBg;
      borderColor =
          selected
              ? Color.lerp(theme.deadBorder, Colors.white, 0.3)!
              : theme.deadBorder;
    } else {
      bgColor = selected ? theme.bucketSelectedBg : theme.bucketBg;
      borderColor = selected ? theme.bucketSelectedBorder : theme.bucketBorder;
    }

    return Container(
      // No top margin: the grid-to-bucket gap above this row is the single
      // explicit spacer in the Stack's Column (matched to the grid's own
      // row spacing) -- a top margin here would silently add to that gap.
      margin: const EdgeInsets.fromLTRB(2, 0, 2, 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: selected ? 2 : 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDead)
            Semantics(
              label: 'Dead bucket, avoid',
              child: const Icon(Icons.close, size: 22, color: Colors.white),
            )
          else
            Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

class _FallingTile extends StatelessWidget {
  const _FallingTile({
    required this.value,
    required this.size,
    required this.theme,
  });

  final int value;
  final double size;
  final GameThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.fallingTileBg,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        '$value',
        style: TextStyle(color: theme.fallingTileFg, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AnimatedScoreBurst extends StatelessWidget {
  const _AnimatedScoreBurst({
    required this.text,
    required this.positive,
    required this.bonus,
  });

  final String text;
  final bool positive;
  final bool bonus;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final opacity = (1 - (value * 0.15)).clamp(0.0, 1.0);

        if (positive) {
          final translateY = 18 - (26 * value);
          final scale = 0.78 + (0.34 * value);
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, translateY),
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        }

        final shakeX = math.sin(value * math.pi * 5) * (1 - value) * 14;
        final scale = 0.96 + ((1 - value) * 0.12);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(shakeX, value * 6),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: _ScoreBurst(text: text, positive: positive, bonus: bonus),
    );
  }
}

class _ScoreBurst extends StatelessWidget {
  const _ScoreBurst({
    required this.text,
    required this.positive,
    required this.bonus,
  });

  final String text;
  final bool positive;
  final bool bonus;

  @override
  Widget build(BuildContext context) {
    final bg =
        positive
            ? (bonus ? const Color(0xFFFFB300) : const Color(0xFFFFD66B))
            : const Color(0xFFFF8A80);
    final fg =
        positive
            ? (bonus ? const Color(0xFF4A2E00) : const Color(0xFF7A4A00))
            : const Color(0xFF7A0019);
    final border =
        positive
            ? (bonus ? const Color(0xFF9C27B0) : const Color(0xFFFFA000))
            : const Color(0xFFD32F2F);

    final burst = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(positive ? 999 : 16),
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(
            color: border.withValues(alpha: 0.22),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 18),
      ),
    );

    if (positive && !bonus) {
      return burst;
    }

    if (positive && bonus) {
      // A ring of small stars radiating out from the pill -- the "starburst"
      // that celebrates finding the highest-divisor bucket after the fact,
      // rather than any bucket coloring that would have given it away.
      const starPositions = <(double?, double?, double?, double?)>[
        (-14, -14, null, null), // top-left
        (-14, null, null, -14), // top-right
        (null, -14, -14, null), // bottom-left
        (null, null, -14, -14), // bottom-right
      ];

      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (final (top, left, bottom, right) in starPositions)
            Positioned(
              top: top,
              left: left,
              bottom: bottom,
              right: right,
              child: Icon(Icons.star, color: Colors.amber.shade400, size: 14),
            ),
          burst,
        ],
      );
    }

    return Transform.rotate(
      angle: 0.78539816339,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: border.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -10,
              right: -8,
              child: Transform.rotate(
                angle: -0.78539816339,
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: border,
                  size: 16,
                ),
              ),
            ),
            Transform.rotate(angle: -0.78539816339, child: burst),
          ],
        ),
      ),
    );
  }
}
