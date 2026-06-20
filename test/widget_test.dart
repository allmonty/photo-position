// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:photo_position/main.dart';

void main() {
  testWidgets('App shows start overlay button', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PhotoPositionApp());

    // Verify that the start overlay button is present
    expect(find.text('START OVERLAY'), findsOneWidget);
    expect(find.text('PHOTO POSITION OVERLAY'), findsOneWidget);
  });

  testWidgets('App shows instructions', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PhotoPositionApp());

    // Verify that instructions are present
    expect(find.text('INSTRUCTIONS'), findsOneWidget);
    expect(find.textContaining('Drag the circle / square'), findsOneWidget);
  });
}
