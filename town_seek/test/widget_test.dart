// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:town_seek/main.dart';

import 'package:flutter/material.dart';

void main() {
  testWidgets('App shows subtitle text on launch', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TownSeekApp());

    // Verify that our app shows the subtitle 'Choose your account type'.
    expect(find.text('Choose your account type'), findsOneWidget);
  });

  testWidgets('Personal button navigates to personal registration screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TownSeekApp());

    final personalButton = find.byKey(const Key('personal_button'));
    expect(personalButton, findsOneWidget);

    await tester.tap(personalButton);
    await tester.pumpAndSettle();

    // Verify navigation by checking for login screen elements
    expect(find.text('Login'), findsWidgets);
    expect(find.text('User name'), findsOneWidget);
  });
}
