import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/features/game/models/game_theme.dart';

double _linearChannel(int channel) {
  final value = channel / 255;
  return value <= 0.04045
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color color) {
  final argb = color.toARGB32();
  return 0.2126 * _linearChannel((argb >> 16) & 0xff) +
      0.7152 * _linearChannel((argb >> 8) & 0xff) +
      0.0722 * _linearChannel(argb & 0xff);
}

double _contrast(Color first, Color second) {
  final values = [_luminance(first), _luminance(second)]..sort();
  return (values.last + 0.05) / (values.first + 0.05);
}

void main() {
  test('visible palette HUD chips meet normal-text contrast', () {
    for (final themeId in gameThemeOrder) {
      final palette = gameThemePalettes[themeId]!;
      final chips = {
        'combo': palette.chipCombo,
        'difficulty': palette.chipDifficulty,
        'fall': palette.chipFall,
        'move': palette.chipMove,
        'range': palette.chipRange,
        'deficit': palette.chipDeficit,
      };

      for (final entry in chips.entries) {
        expect(
          _contrast(entry.value.bg, entry.value.fg),
          greaterThanOrEqualTo(4.5),
          reason: '${palette.name} ${entry.key} chip must remain readable',
        );
      }
    }
  });
}
