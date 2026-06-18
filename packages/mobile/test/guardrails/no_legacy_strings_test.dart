import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('No legacy AppStrings files/symbols under lib/', () async {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ directory must exist');

    // Guard against symbol reintroduction by a basic scan.
    final forbiddenSymbols = <Pattern>[RegExp(r'\bclass\s+AppStrings\b'), RegExp(r'AppStrings\.')];

    final dartFiles = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final content = await file.readAsString();
      for (final sym in forbiddenSymbols) {
        final has = sym.allMatches(content).isNotEmpty;
        expect(has, isFalse, reason: 'Found legacy AppStrings usage in ${file.path}');
      }
    }
  });
}
