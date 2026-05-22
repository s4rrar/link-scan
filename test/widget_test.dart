// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_barcode_scanner/main.dart';
import 'package:wifi_barcode_scanner/viewmodels/barcode_viewmodel.dart';

void main() {
  testWidgets('Smoke test - App builds successfully', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Mock sqflite MethodChannel
    const channel = MethodChannel('tekartik_sqflite');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (message) async {
      if (message.method == 'getDatabasesPath') {
        return '.';
      }
      if (message.method == 'openDatabase') {
        return 1;
      }
      if (message.method == 'query') {
        return [];
      }
      return null;
    });

    final viewModel = BarcodeViewModel();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(viewModel: viewModel));

    // Verify that the app title 'LinkScan' is displayed.
    expect(find.text('LinkScan'), findsOneWidget);
  });
}
