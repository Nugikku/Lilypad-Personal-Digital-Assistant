import 'package:flutter_test/flutter_test.dart';

import 'package:lilypad/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // This is a basic Flutter widget test.
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LilypadApp());

    // Verify that we are on the login screen.
    expect(find.text('START PLAYING'), findsOneWidget);
  });
}
