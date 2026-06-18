import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/main.dart';

void main() {
  testWidgets('shows recovery screen when Firebase is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(const ModuloApp(firebaseReady: false));

    expect(find.text('Unable to start app services'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
