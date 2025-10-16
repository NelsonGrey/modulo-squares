import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulo/features/website/website_screen.dart';

void main() {
  testWidgets('WebsiteScreen builds without errors', (WidgetTester tester) async {
    // Build the WebsiteScreen
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WebsiteScreen(),
        ),
      ),
    );

    // Verify that the screen builds and contains expected elements
    expect(find.byType(WebsiteScreen), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('WebsiteScreen contains navigation elements', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WebsiteScreen(),
        ),
      ),
    );

    // Check for navigation buttons in app bar
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Rules'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);
  });
}
