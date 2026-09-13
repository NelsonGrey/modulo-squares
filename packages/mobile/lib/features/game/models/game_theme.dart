import 'package:flutter/material.dart';

/// Identifies one of the built-in falling-mode color palettes. Persisted by
/// name in SharedPreferences (`fallingMode.theme`, see
/// [FallingModuloGameScreen]) -- renaming a value here changes what a
/// player who already picked a non-default theme sees next launch.
enum GameThemeId { deepOcean, arcadeNeon, warmSunset, candyPop, slateMono }

/// One HUD stat chip's background/foreground pair (combo, difficulty, fall
/// speed, move speed, range, deficit).
class GameChipColors {
  const GameChipColors({required this.bg, required this.fg});

  final Color bg;
  final Color fg;
}

/// A complete color palette for the falling-mode game screen. Every themed
/// surface -- app bar, HUD, board, grid, buckets, falling tile, and controls
/// -- reads its colors from one of these rather than hardcoding them, so
/// adding a palette is just adding another instance below.
class GameThemePalette {
  const GameThemePalette({
    required this.name,
    required this.appBarBg,
    required this.appBarFg,
    required this.pageBg,
    required this.textPrimary,
    required this.textMuted,
    required this.progressTrack,
    required this.progressFill,
    required this.chipCombo,
    required this.chipDifficulty,
    required this.chipFall,
    required this.chipMove,
    required this.chipRange,
    required this.chipDeficit,
    required this.boardGradientFrom,
    required this.boardGradientTo,
    required this.gridUnfilledBg,
    required this.gridUnfilledBorder,
    required this.gridFilledBg,
    required this.bucketBg,
    required this.bucketBorder,
    required this.bucketSelectedBg,
    required this.bucketSelectedBorder,
    required this.deadBg,
    required this.deadBorder,
    required this.fallingTileBg,
    required this.fallingTileFg,
    required this.buttonTonalBg,
    required this.buttonTonalFg,
    required this.buttonPrimaryBg,
    required this.buttonPrimaryFg,
  });

  /// Shown in the theme picker.
  final String name;

  final Color appBarBg;
  final Color appBarFg;

  /// Scaffold background -- the surface the HUD and the board's own margins
  /// sit on.
  final Color pageBg;

  final Color textPrimary;
  final Color textMuted;

  final Color progressTrack;
  final Color progressFill;

  final GameChipColors chipCombo;
  final GameChipColors chipDifficulty;
  final GameChipColors chipFall;
  final GameChipColors chipMove;
  final GameChipColors chipRange;
  final GameChipColors chipDeficit;

  final Color boardGradientFrom;
  final Color boardGradientTo;

  final Color gridUnfilledBg;
  final Color gridUnfilledBorder;
  final Color gridFilledBg;

  final Color bucketBg;
  final Color bucketBorder;
  final Color bucketSelectedBg;
  final Color bucketSelectedBorder;

  /// The Dead bucket's own colors -- semantic (danger), not swapped when a
  /// palette changes, but every palette still picks its own shade of red so
  /// it never clashes with the board gradient.
  final Color deadBg;
  final Color deadBorder;

  final Color fallingTileBg;
  final Color fallingTileFg;

  final Color buttonTonalBg;
  final Color buttonTonalFg;
  final Color buttonPrimaryBg;
  final Color buttonPrimaryFg;
}

/// The five built-in palettes, keyed by [GameThemeId]. Deep Ocean is the
/// default for new players (see `fallingMode.theme`'s fallback in
/// [FallingModuloGameScreen]).
const Map<GameThemeId, GameThemePalette> gameThemePalettes = {
  GameThemeId.deepOcean: GameThemePalette(
    name: 'Deep Ocean',
    appBarBg: Color(0xFFFFFFFF),
    appBarFg: Color(0xFF0B6B77),
    pageBg: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF10262E),
    // Darkened from the original #6E8B93 (~3.6:1 on white, below WCAG AA's
    // 4.5:1 for this size text) to a value that actually clears it.
    textMuted: Color(0xFF4A6B73),
    progressTrack: Color(0xFFDCEEF1),
    progressFill: Color(0xFF0FA3B1),
    chipCombo: GameChipColors(bg: Color(0xFFE1F5F6), fg: Color(0xFF0FA3B1)),
    chipDifficulty: GameChipColors(
      bg: Color(0xFFE3ECF7),
      fg: Color(0xFF2A6FB0),
    ),
    chipFall: GameChipColors(bg: Color(0xFFE7F2FF), fg: Color(0xFF1C7ED6)),
    chipMove: GameChipColors(bg: Color(0xFFDFF6F2), fg: Color(0xFF0E8C7F)),
    chipRange: GameChipColors(bg: Color(0xFFE6F0F5), fg: Color(0xFF3A7CA5)),
    chipDeficit: GameChipColors(bg: Color(0xFFFDE7E7), fg: Color(0xFFC0392B)),
    boardGradientFrom: Color(0xFF12A7B5),
    boardGradientTo: Color(0xFF075A66),
    gridUnfilledBg: Color(0x29FFFFFF),
    gridUnfilledBorder: Color(0x6BFFFFFF),
    gridFilledBg: Color(0xFF4CD97B),
    bucketBg: Color(0xFFFFFFFF),
    bucketBorder: Color(0xFFBFE3E6),
    bucketSelectedBg: Color(0xFFFDECC8),
    bucketSelectedBorder: Color(0xFFF4A300),
    deadBg: Color(0xFFC0392B),
    deadBorder: Color(0xFF8E2A20),
    fallingTileBg: Color(0xFF2A6FB0),
    fallingTileFg: Color(0xFFFFFFFF),
    buttonTonalBg: Color(0xFFDCEEF1),
    buttonTonalFg: Color(0xFF0B6B77),
    buttonPrimaryBg: Color(0xFF0FA3B1),
    // Dark, not white: white-on-#0FA3B1 is only ~2.8:1, below WCAG AA for
    // the 17px Start/Drop labels this colors.
    buttonPrimaryFg: Color(0xFF0A2A2F),
  ),
  GameThemeId.arcadeNeon: GameThemePalette(
    name: 'Arcade Neon',
    appBarBg: Color(0xFF0B0F1A),
    appBarFg: Color(0xFFEAF9FF),
    pageBg: Color(0xFF11162A),
    textPrimary: Color(0xFFF2F7FF),
    textMuted: Color(0xFF7C8AA8),
    progressTrack: Color(0xFF1E2740),
    progressFill: Color(0xFF00E5FF),
    chipCombo: GameChipColors(bg: Color(0xFF1B2A3D), fg: Color(0xFF00E5FF)),
    chipDifficulty: GameChipColors(
      bg: Color(0xFF22182F),
      fg: Color(0xFFFF3DCB),
    ),
    chipFall: GameChipColors(bg: Color(0xFF16213B), fg: Color(0xFF3D7BFF)),
    chipMove: GameChipColors(bg: Color(0xFF182A22), fg: Color(0xFF39FF88)),
    chipRange: GameChipColors(bg: Color(0xFF2A2312), fg: Color(0xFFFFD23D)),
    chipDeficit: GameChipColors(bg: Color(0xFF2A1414), fg: Color(0xFFFF5C5C)),
    boardGradientFrom: Color(0xFF151C33),
    boardGradientTo: Color(0xFF05070D),
    gridUnfilledBg: Color(0x0DFFFFFF),
    gridUnfilledBorder: Color(0x5200E5FF),
    gridFilledBg: Color(0xFF39FF88),
    bucketBg: Color(0xFF0F1524),
    bucketBorder: Color(0xFF2A3550),
    bucketSelectedBg: Color(0x2900E5FF),
    bucketSelectedBorder: Color(0xFF00E5FF),
    deadBg: Color(0xFFB0121F),
    deadBorder: Color(0xFFFF4D4D),
    fallingTileBg: Color(0xFF3D7BFF),
    fallingTileFg: Color(0xFFFFFFFF),
    buttonTonalBg: Color(0xFF1B2338),
    buttonTonalFg: Color(0xFF00E5FF),
    buttonPrimaryBg: Color(0xFF00E5FF),
    buttonPrimaryFg: Color(0xFF05131F),
  ),
  GameThemeId.warmSunset: GameThemePalette(
    name: 'Warm Sunset',
    appBarBg: Color(0xFFFFF8F0),
    appBarFg: Color(0xFF7A3B1E),
    pageBg: Color(0xFFFFFCF7),
    textPrimary: Color(0xFF3A2418),
    // Darkened from the original #A9876F (~3.4:1 on this palette's cream
    // page, below WCAG AA's 4.5:1 for this size text).
    textMuted: Color(0xFF8A6A4E),
    progressTrack: Color(0xFFF3E3D6),
    progressFill: Color(0xFFE8734A),
    chipCombo: GameChipColors(bg: Color(0xFFFDECC8), fg: Color(0xFFB5651D)),
    chipDifficulty: GameChipColors(
      bg: Color(0xFFFCE3D6),
      fg: Color(0xFFC1440E),
    ),
    chipFall: GameChipColors(bg: Color(0xFFFBEAD9), fg: Color(0xFFD46A28)),
    chipMove: GameChipColors(bg: Color(0xFFFFF1E0), fg: Color(0xFFE08E45)),
    chipRange: GameChipColors(bg: Color(0xFFF7E0CE), fg: Color(0xFFA85C2E)),
    chipDeficit: GameChipColors(bg: Color(0xFFFDE2E2), fg: Color(0xFFC0392B)),
    boardGradientFrom: Color(0xFFF4A261),
    boardGradientTo: Color(0xFFE76F51),
    gridUnfilledBg: Color(0x38FFFFFF),
    gridUnfilledBorder: Color(0x477A3B1E),
    gridFilledBg: Color(0xFF6FCF97),
    bucketBg: Color(0xFFFFF8F0),
    bucketBorder: Color(0xFFD8B08C),
    bucketSelectedBg: Color(0xFFFBD9B8),
    bucketSelectedBorder: Color(0xFFE8734A),
    deadBg: Color(0xFFC0392B),
    deadBorder: Color(0xFF8E2A20),
    fallingTileBg: Color(0xFFE8734A),
    // Dark, not white: white-on-#E8734A is only ~2.9:1, below WCAG AA for
    // the falling number this colors.
    fallingTileFg: Color(0xFF3A1A0E),
    buttonTonalBg: Color(0xFFFBD9B8),
    buttonTonalFg: Color(0xFF7A3B1E),
    buttonPrimaryBg: Color(0xFFE8734A),
    // Same contrast issue as fallingTileFg above -- white on this
    // background is only ~2.9:1 for the 17px Start/Drop labels.
    buttonPrimaryFg: Color(0xFF3A1A0E),
  ),
  GameThemeId.candyPop: GameThemePalette(
    name: 'Candy Pop',
    appBarBg: Color(0xFFFBF3FF),
    appBarFg: Color(0xFF4A1663),
    pageBg: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF3B0A56),
    // Darkened from the original #9B7BAE (~3.5:1 on white, below WCAG AA's
    // 4.5:1 for this size text).
    textMuted: Color(0xFF6E4E82),
    progressTrack: Color(0xFFF1DFF7),
    progressFill: Color(0xFFFF3D9A),
    chipCombo: GameChipColors(bg: Color(0xFFFDE1F3), fg: Color(0xFFD6006B)),
    chipDifficulty: GameChipColors(
      bg: Color(0xFFF3E1FD),
      fg: Color(0xFF7B1FA2),
    ),
    chipFall: GameChipColors(bg: Color(0xFFFFE8F5), fg: Color(0xFFC2185B)),
    chipMove: GameChipColors(bg: Color(0xFFF0E4FE), fg: Color(0xFF6A1B9A)),
    chipRange: GameChipColors(bg: Color(0xFFFCE4FF), fg: Color(0xFF9C27B0)),
    chipDeficit: GameChipColors(bg: Color(0xFFFDE2E2), fg: Color(0xFFC0392B)),
    boardGradientFrom: Color(0xFFFF6FB5),
    boardGradientTo: Color(0xFFB368FF),
    gridUnfilledBg: Color(0x40FFFFFF),
    gridUnfilledBorder: Color(0x6BFFFFFF),
    gridFilledBg: Color(0xFF5CE65C),
    bucketBg: Color(0xFFFFFFFF),
    bucketBorder: Color(0xFFF3C6E4),
    bucketSelectedBg: Color(0xFFFFE07D),
    bucketSelectedBorder: Color(0xFFFFB300),
    deadBg: Color(0xFFFF4757),
    deadBorder: Color(0xFFC0392B),
    fallingTileBg: Color(0xFFD6006B),
    fallingTileFg: Color(0xFFFFFFFF),
    buttonTonalBg: Color(0xFFF3E1FD),
    buttonTonalFg: Color(0xFF7B1FA2),
    buttonPrimaryBg: Color(0xFFD6006B),
    buttonPrimaryFg: Color(0xFFFFFFFF),
  ),
  // Not in gameThemeOrder -- too easily confused with Arcade Neon's dark
  // board at swatch size. Kept defined (not deleted) in case it's revived
  // later, e.g. paired with a second accent color of its own.
  GameThemeId.slateMono: GameThemePalette(
    name: 'Slate Mono',
    appBarBg: Color(0xFFF5F5F4),
    appBarFg: Color(0xFF1C1C1C),
    pageBg: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1C1C1C),
    textMuted: Color(0xFF8A8A85),
    progressTrack: Color(0xFFE4E4E1),
    progressFill: Color(0xFFFF7A00),
    chipCombo: GameChipColors(bg: Color(0xFFFFF1E0), fg: Color(0xFFCC5A00)),
    chipDifficulty: GameChipColors(
      bg: Color(0xFFEDEDEA),
      fg: Color(0xFF3A3A36),
    ),
    chipFall: GameChipColors(bg: Color(0xFFEDEDEA), fg: Color(0xFF3A3A36)),
    chipMove: GameChipColors(bg: Color(0xFFEDEDEA), fg: Color(0xFF3A3A36)),
    chipRange: GameChipColors(bg: Color(0xFFEDEDEA), fg: Color(0xFF3A3A36)),
    chipDeficit: GameChipColors(bg: Color(0xFFFDE2E2), fg: Color(0xFFC0392B)),
    boardGradientFrom: Color(0xFF2B2B28),
    boardGradientTo: Color(0xFF101010),
    gridUnfilledBg: Color(0x12FFFFFF),
    gridUnfilledBorder: Color(0x52FFFFFF),
    gridFilledBg: Color(0xFF4CAF50),
    bucketBg: Color(0xFFF5F5F4),
    bucketBorder: Color(0xFFD8D8D3),
    // Opaque (not the translucent tint the other dark-board palettes use):
    // Slate Mono's text is dark, and a translucent orange over the charcoal
    // board behind it would read too dark for that text to stay legible.
    bucketSelectedBg: Color(0xFFFFE0B8),
    bucketSelectedBorder: Color(0xFFFF7A00),
    deadBg: Color(0xFF8A1B1B),
    deadBorder: Color(0xFFC0392B),
    fallingTileBg: Color(0xFFFF7A00),
    // Dark, not white -- white-on-amber fails contrast here unlike the
    // other four palettes' falling-tile colors.
    fallingTileFg: Color(0xFF201200),
    buttonTonalBg: Color(0xFFEDEDEA),
    buttonTonalFg: Color(0xFF1C1C1C),
    buttonPrimaryBg: Color(0xFFFF7A00),
    buttonPrimaryFg: Color(0xFF201200),
  ),
};

/// Display order for the theme picker -- four palettes, one row. Slate Mono
/// stays defined above but out of this list (see the note on its entry).
const List<GameThemeId> gameThemeOrder = [
  GameThemeId.deepOcean,
  GameThemeId.arcadeNeon,
  GameThemeId.warmSunset,
  GameThemeId.candyPop,
];
