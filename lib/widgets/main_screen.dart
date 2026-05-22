import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../viewmodels/barcode_viewmodel.dart';
import 'scanner_tab.dart';
import 'history_tab.dart';
import 'companion_tab.dart';
import 'about_tab.dart';
import 'settings_screen.dart';


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
  AppTab _selectedTab = AppTab.scanner;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
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
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: polishPrimaryContainer,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.qr_code_scanner,
                            color: polishOnPrimaryContainer,
                            size: 22.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'LinkScan',
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
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                                const SizedBox(width: 6.0),
                                Text(
                                  'PC Connected: ${widget.viewModel.serverIp}',
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
            index: _selectedTab.index,
            children: [
              ScannerTab(viewModel: widget.viewModel),
              HistoryTab(viewModel: widget.viewModel),
              CompanionTab(),
              const AboutTab(),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32.0),
                topRight: Radius.circular(32.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8.0,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32.0),
                topRight: Radius.circular(32.0),
              ),
              child: NavigationBar(
                backgroundColor: polishSurfaceContainerLow,
                selectedIndex: _selectedTab.index,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedTab = AppTab.values[index];
                  });
                },
                indicatorColor: polishPrimaryContainer,
                destinations: AppTab.values.map((tab) {
                  final isSelected = _selectedTab == tab;
                  return NavigationDestination(
                    icon: Icon(isSelected ? tab.iconSelected : tab.iconUnselected),
                    label: tab.title,
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
