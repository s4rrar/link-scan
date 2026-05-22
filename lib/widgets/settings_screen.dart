import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../viewmodels/barcode_viewmodel.dart';
import 'settings_tab.dart';

class SettingsScreen extends StatelessWidget {
  final BarcodeViewModel viewModel;

  const SettingsScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
            color: polishOnBackground,
          ),
        ),
        backgroundColor: polishBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: polishOnBackground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SettingsTab(viewModel: viewModel),
    );
  }
}
