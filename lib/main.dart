import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'widgets/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinkScan Pro',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}
