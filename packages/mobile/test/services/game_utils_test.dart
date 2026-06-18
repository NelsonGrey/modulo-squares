import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/core/services/game_utils.dart';

void main() {
  group('GameUtils', () {
    test('calculateMaxValue returns correct values for different difficulty levels', () {
      expect(GameUtils.calculateMaxValue(1), 1000);
      expect(GameUtils.calculateMaxValue(2), 2000);
      expect(GameUtils.calculateMaxValue(5), 5000);
      expect(GameUtils.calculateMaxValue(10), 10000);
    });

    test('calculateMaxValue clamps minimum value', () {
      expect(GameUtils.calculateMaxValue(0), 1);
      expect(GameUtils.calculateMaxValue(-1), 1);
      expect(GameUtils.calculateMaxValue(-10), 1);
    });

    test('calculateMaxValue clamps maximum value', () {
      expect(GameUtils.calculateMaxValue(100), 100000);
      expect(GameUtils.calculateMaxValue(200), 100000);
      expect(GameUtils.calculateMaxValue(1000), 100000);
    });

    test('calculateMaxValue handles edge cases', () {
      expect(GameUtils.calculateMaxValue(50), 50000);
      expect(GameUtils.calculateMaxValue(99), 99000);
      expect(GameUtils.calculateMaxValue(100), 100000);
      expect(GameUtils.calculateMaxValue(101), 100000);
    });

    test('calculateMaxValue is deterministic', () {
      // Multiple calls with same input should return same result
      expect(GameUtils.calculateMaxValue(7), GameUtils.calculateMaxValue(7));
      expect(GameUtils.calculateMaxValue(7), 7000);
    });

    test('calculateMaxValue scales linearly within valid range', () {
      for (int level = 1; level <= 100; level++) {
        final expected = (level * 1000).clamp(1, 100000);
        expect(GameUtils.calculateMaxValue(level), expected);
      }
    });

    test('calculateMaxValue handles large inputs efficiently', () {
      // Test with very large inputs
      expect(GameUtils.calculateMaxValue(1000000), 100000);
      expect(GameUtils.calculateMaxValue(999999999), 100000);
    });
  });
}
