// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_cast_controller/main.dart';

void main() {
  testWidgets('YouTube Cast Controller app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const YouTubeCastControllerApp());

    // Verify that the app title is displayed.
    expect(find.text('YouTube Cast Controller'), findsOneWidget);
    
    // Verify that the Cast status card is displayed.
    expect(find.text('Cast未接続'), findsOneWidget);
    
    // Verify that the refresh button is displayed.
    expect(find.text('状態を更新'), findsOneWidget);
  });
}
