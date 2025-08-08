// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:macos_file_manager/main.dart';
import 'package:macos_file_manager/home.dart';
import 'package:macos_file_manager/providers/favorites_provider.dart' as favorites_provider;
import 'package:macos_file_manager/providers/file_category_config_provider.dart' as file_category_provider;

void main() {
  testWidgets('App boots with ProviderScope and shows HomePage', (WidgetTester tester) async {
    // Set up mock shared preferences for providers used by the app
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app wrapped in ProviderScope with required overrides
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favorites_provider.sharedPreferencesProvider.overrideWithValue(prefs),
          file_category_provider.sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    );

    // Let initial async work settle
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // Verify MaterialApp and HomePage render
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);
  });
}
