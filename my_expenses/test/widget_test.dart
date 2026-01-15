// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_expenses/main.dart';

void main() {
  // setUpAll(() async {
  //   WidgetsFlutterBinding.ensureInitialized();
  //   await Supabase.initialize(
  //     url: 'test_url',
  //     anonKey: 'test_key',
  //   );
  // });

  testWidgets('App builds smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyExpensesApp());

    // Just check that it builds without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
