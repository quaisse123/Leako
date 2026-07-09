// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('Welcome screen elements test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LeakoApp());

    // Verify that our app name 'LEAKO' is present.
    expect(find.text('LEAKO'), findsOneWidget);

    // Verify that the login and signup buttons/texts exist.
    expect(find.text('Se connecter'), findsOneWidget);

    // Pump to let any pending timers/Future.delayed complete
    await tester.pump(const Duration(seconds: 1));
  });
}
