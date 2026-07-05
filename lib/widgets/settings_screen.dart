import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_styles.dart';
import '../viewmodels/barcode_viewmodel.dart';
import 'settings_tab.dart';

class SettingsScreen extends StatelessWidget {
  final BarcodeViewModel viewModel;

  const SettingsScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isDark = viewModel.isDarkMode;
    final primaryColor = polishPrimary;

    return GlassBackground(
      isDark: isDark,
      primaryColor: primaryColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Settings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
              color: polishOnBackground,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: polishOnBackground),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SettingsTab(viewModel: viewModel),
      ),
    );
  }
}
