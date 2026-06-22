import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'widgets/main_screen.dart';
import 'viewmodels/barcode_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final viewModel = BarcodeViewModel();
  runApp(MyApp(viewModel: viewModel));
}

class MyApp extends StatelessWidget {
  final BarcodeViewModel viewModel;
  const MyApp({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        AppThemeState.isDark = viewModel.isDarkMode;
        return MaterialApp(
          title: 'LinkScan Pro',
          theme: appTheme,
          darkTheme: darkAppTheme,
          themeMode: viewModel.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: MainScreen(viewModel: viewModel),
        );
      },
    );
  }
}
