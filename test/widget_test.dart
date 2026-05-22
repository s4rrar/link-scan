// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:link_scan_pc/main.dart';
import 'package:link_scan_pc/viewmodels/barcode_viewmodel.dart';

void main() {
  // Initialize ffi for sqflite in tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('Smoke test - App builds successfully', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    final viewModel = BarcodeViewModel();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(viewModel: viewModel));

    // Verify that the app title 'LinkScan Pro' is displayed.
    expect(find.text('LinkScan Pro'), findsOneWidget);
  });
}
