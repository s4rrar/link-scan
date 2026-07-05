import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../theme/app_styles.dart';
import '../viewmodels/barcode_viewmodel.dart';

class AboutTab extends StatelessWidget {
  final BarcodeViewModel viewModel;
  const AboutTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final isDark = viewModel.isDarkMode;
        final primaryColor = polishPrimary;

        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // App Branding Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96.0,
                    height: 96.0,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(28.0),
                      boxShadow: [
                        BoxShadow(
                          color: polishPrimary.withOpacity(0.15),
                          blurRadius: 16.0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child: Image.asset(
                        'logo/logo.png',
                        width: 96.0,
                        height: 96.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    'LinkScan Pro',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 26.0,
                      color: polishOnBackground,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: polishPrimaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(100.0),
                      border: Border.all(
                        color: polishPrimary.withOpacity(0.2),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: polishOnPrimaryContainer,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36.0),

            // Description Card
            GlassContainer(
              isDark: isDark,
              primaryColor: primaryColor,
              borderRadius: AppStyles.radiusLarge,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What is LinkScan Pro?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: polishPrimary,
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'LinkScan Pro turns your mobile device into a high-speed, wireless hardware barcode scanner. Using local network connectivity, it pipes barcode and QR code transmissions directly to your cursor focus on any PC or laptop running our friction-free companion server script.',
                    style: TextStyle(
                      color: polishOnSurfaceVariant,
                      fontSize: 13.0,
                      height: 1.6,
                ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppStyles.spacingLarge),

            // Key Features List
            Text(
              'KEY FEATURES',
              style: TextStyle(
                color: polishPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12.0),

            _buildFeatureItem(
              icon: Icons.wifi,
              title: 'Frictionless Wireless Scan Syncing',
              description:
                  'Type codes directly into Excel, Google Sheets, databases, or Notepad over local Wi-Fi.',
            ),
            _buildFeatureItem(
              icon: Icons.flash_on,
              title: 'Live Camera Flash Support',
              description:
                  'Toggle the camera flash to read barcodes in low-light warehouse conditions.',
            ),
            _buildFeatureItem(
              icon: Icons.history,
              title: 'Offline SQLite Scan Logs',
              description:
                  'Access scan history and sync statuses anywhere, even when disconnected.',
            ),
            _buildFeatureItem(
              icon: Icons.timer_outlined,
              title: 'Anti-Duplicate Cooldown Control',
              description:
                  'Customizable sliding window filters out accidental double scans seamlessly.',
            ),

            const SizedBox(height: 24.0),

            // Git Repository Details Card
            GlassContainer(
              isDark: isDark,
              primaryColor: primaryColor,
              borderRadius: AppStyles.radiusLarge,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Open Source Repository',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: polishPrimary,
                      fontSize: 15.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Access documentation, submit bug reports, or contribute to the project on Github.',
                    style: TextStyle(
                      color: polishOnSurfaceVariant,
                      fontSize: 12.0,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(
                        const ClipboardData(
                          text: 'https://github.com/s4rrar/link-scan',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Github URL copied to clipboard!'),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: polishOutline.withOpacity(0.2),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link, color: polishPrimary, size: 20.0),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Text(
                              'github.com/s4rrar/link-scan',
                              style: TextStyle(
                                color: polishOnSurface,
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.copy,
                            color: polishOnSurfaceVariant,
                            size: 16.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            Center(
              child: Text(
                'Made by s4rrar for faster workflows.',
                style: TextStyle(color: polishOnSurfaceVariant, fontSize: 11.0),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isDark = AppThemeState.isDark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: polishPrimaryContainer.withOpacity(isDark ? 0.2 : 0.4),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: polishPrimary.withOpacity(0.15),
                width: 1.0,
              ),
            ),
            child: Icon(icon, color: polishPrimary, size: 20.0),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                    color: polishOnBackground,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  description,
                  style: TextStyle(
                    color: polishOnSurfaceVariant,
                    fontSize: 12.0,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
