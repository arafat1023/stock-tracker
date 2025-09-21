// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_tracker/main.dart';

void main() {
  testWidgets('Stock Tracker app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StockTrackerApp());

    // Verify that our app loads with the home screen and navigation
    expect(find.byIcon(Icons.inventory), findsOneWidget);
    expect(find.byIcon(Icons.store), findsOneWidget);
    expect(find.byIcon(Icons.local_shipping), findsOneWidget);
    expect(find.byIcon(Icons.analytics), findsOneWidget);

    // Verify app title appears in both screens
    expect(find.text('Products'), findsWidgets);
  });
}
