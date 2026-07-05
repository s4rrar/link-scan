import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_styles.dart';
import '../viewmodels/barcode_viewmodel.dart';
import 'scanner_tab.dart';
import 'history_tab.dart';
import 'companion_tab.dart';
import 'about_tab.dart';
import 'settings_screen.dart';

final Map<ConnectionStatus, Color> _statusDotColors = {
  ConnectionStatus.connected: const Color(0xFF4CAF50),
  ConnectionStatus.failed: Colors.red,
  ConnectionStatus.ready: Colors.blue,
};

final Map<ConnectionStatus, String> _statusLabels = {
  ConnectionStatus.connected: 'PC Connected: ',
  ConnectionStatus.failed: 'Failed to connect',
  ConnectionStatus.ready: 'Ready to connect',
};


enum AppTab {
  scanner('Scanner', Icons.qr_code_scanner_outlined, Icons.qr_code_scanner),
  history('History', Icons.history_outlined, Icons.history),
  companion('Companion', Icons.laptop_outlined, Icons.laptop),
  about('About', Icons.info_outline, Icons.info);

  final String title;
  final IconData iconUnselected;
  final IconData iconSelected;

  const AppTab(this.title, this.iconUnselected, this.iconSelected);
}

class MainScreen extends StatefulWidget {
  final BarcodeViewModel viewModel;
  const MainScreen({super.key, required this.viewModel});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ValueNotifier<AppTab> _selectedTab = ValueNotifier<AppTab>(AppTab.scanner);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.viewModel, _selectedTab]),
      builder: (context, _) {
        final currentTab = _selectedTab.value;
        final isDark = widget.viewModel.isDarkMode;
        final primaryColor = polishPrimary;

        return GlassBackground(
          isDark: isDark,
          primaryColor: primaryColor,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(64.0),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40.0,
                            height: 40.0,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: ClipOval(
                              child: Image.asset(
                                'logo/logo.png',
                                width: 40.0,
                                height: 40.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'LinkScan Pro',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                  color: polishOnBackground,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 8.0,
                                    height: 8.0,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: widget.viewModel.connectionStatus == ConnectionStatus.ready
                                          ? primaryColor
                                          : _statusDotColors[widget.viewModel.connectionStatus]!,
                                    ),
                                  ),
                                  const SizedBox(width: 6.0),
                                  Text(
                                    widget.viewModel.connectionStatus == ConnectionStatus.connected
                                        ? '${_statusLabels[widget.viewModel.connectionStatus]}${widget.viewModel.serverIp}'
                                        : _statusLabels[widget.viewModel.connectionStatus]!,
                                    style: TextStyle(
                                      fontSize: 11.0,
                                      color: polishOnSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.settings, color: polishOnSurfaceVariant),
                        style: IconButton.styleFrom(
                          backgroundColor: polishSurfaceVariant.withOpacity(0.5),
                          minimumSize: const Size(40.0, 40.0),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SettingsScreen(viewModel: widget.viewModel),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: IndexedStack(
              index: currentTab.index,
              children: [
                ScannerTab(viewModel: widget.viewModel, isActive: currentTab == AppTab.scanner),
                HistoryTab(viewModel: widget.viewModel),
                CompanionTab(viewModel: widget.viewModel),
                AboutTab(viewModel: widget.viewModel),
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GlassContainer(
                  isDark: isDark,
                  primaryColor: primaryColor,
                  borderRadius: AppStyles.radiusLarge,
                  child: NavigationBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    selectedIndex: currentTab.index,
                    onDestinationSelected: (index) {
                      _selectedTab.value = AppTab.values[index];
                    },
                    destinations: AppTab.values.map((tab) {
                      final isSelected = currentTab == tab;
                      return NavigationDestination(
                        icon: Icon(isSelected ? tab.iconSelected : tab.iconUnselected),
                        label: tab.title,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
