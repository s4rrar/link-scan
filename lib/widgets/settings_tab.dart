import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../viewmodels/barcode_viewmodel.dart';

class SettingsTab extends StatefulWidget {
  final BarcodeViewModel viewModel;

  const SettingsTab({super.key, required this.viewModel});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final TextEditingController _ipController;
  late final TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.viewModel.serverIp);
    _portController = TextEditingController(text: widget.viewModel.serverPort.toString());

    _ipController.addListener(() {
      final ip = _ipController.text.trim();
      if (ip.isNotEmpty) {
        widget.viewModel.updateServerIp(ip);
      }
    });

    _portController.addListener(() {
      final port = int.tryParse(_portController.text.trim());
      if (port != null && port >= 1 && port <= 65535) {
        widget.viewModel.updateServerPort(port);
      }
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'COMPANION CONFIGURATION',
          style: TextStyle(
            color: polishPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4.0),
        const Text(
          'Manage your wireless settings, transmission ports, haptic feel, and hardware simulation delays.',
          style: TextStyle(
            color: polishOnSurfaceVariant,
            fontSize: 13.0,
          ),
        ),
        const SizedBox(height: 16.0),

        // Connection Card Group
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
            side: BorderSide(color: polishOutline.withOpacity(0.4), width: 1.0),
          ),
          color: polishSurface,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PC SERVER IP ADDRESS',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: polishPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: _ipController,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(
                    color: polishOnSurface,
                    fontSize: 16.0,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. 192.168.1.15',
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: polishPrimary),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: polishOutline.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'SERVER PORT',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: polishPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: polishOnSurface,
                    fontSize: 16.0,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. 8080',
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: polishPrimary),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: polishOutline.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                ),
                const SizedBox(height: 20.0),

                // Connection Test Button
                SizedBox(
                  width: double.infinity,
                  height: 48.0,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: polishPrimary,
                      foregroundColor: polishOnPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                    onPressed: viewModel.isTestingConnection ? null : () => viewModel.testConnection(),
                    icon: viewModel.isTestingConnection
                        ? const SizedBox(
                            width: 20.0,
                            height: 20.0,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
                          )
                        : const Icon(Icons.wifi_find, size: 18.0),
                    label: Text(
                      viewModel.isTestingConnection ? 'Pinging Companion...' : 'Test PC Connection',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                    ),
                  ),
                ),

                // Connection status log container
                if (viewModel.connectionStatusMessage != null) ...[
                  const SizedBox(height: 16.0),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: polishSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: polishOutline.withOpacity(0.2), width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              viewModel.connectionStatusMessage!.contains('Connected') ? Icons.check_circle : Icons.error,
                              color: viewModel.connectionStatusMessage!.contains('Connected')
                                  ? const Color(0xFF2E7D32)
                                  : polishError,
                              size: 16.0,
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              'DIAGNOSTIC STATUS LOG',
                              style: TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: viewModel.connectionStatusMessage!.contains('Connected')
                                    ? const Color(0xFF2E7D32)
                                    : polishError,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          viewModel.connectionStatusMessage ?? '',
                          style: const TextStyle(fontSize: 12.0, color: polishOnSurface, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0),

        // Delay slider card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
            side: BorderSide(color: polishOutline.withOpacity(0.4), width: 1.0),
          ),
          color: polishSurface,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ANTI-DUPLICATE SCAN COOLDOWN',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: polishPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${(viewModel.scanDelayMs / 1000.0).toStringAsFixed(1)}s',
                      style: const TextStyle(
                        color: polishPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                const Text(
                  'Configured delay window between scanned codes. Stops accidental scan trigger noise.',
                  style: TextStyle(color: polishOnSurfaceVariant, fontSize: 11.0),
                ),
                const SizedBox(height: 16.0),
                Slider(
                  value: viewModel.scanDelayMs,
                  min: 500.0,
                  max: 5000.0,
                  divisions: 9,
                  activeColor: polishPrimary,
                  inactiveColor: polishSurfaceVariant,
                  onChanged: (newValue) {
                    viewModel.updateScanDelay(newValue);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0),

        // Beep & feel preference card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
            side: BorderSide(color: polishOutline.withOpacity(0.4), width: 1.0),
          ),
          color: polishSurface,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HAPTIC FEEDBACK PREFERENCES',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: polishPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16.0),

                // Sound Beep Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            viewModel.soundEnabled ? Icons.volume_up : Icons.volume_off,
                            color: polishOnSurfaceVariant,
                            size: 20.0,
                          ),
                          const SizedBox(width: 12.0),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Synthesized Beep Indicator',
                                  style: TextStyle(color: polishOnSurface, fontSize: 14.0, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Play high-pitch buzzer tone on scan read',
                                  style: TextStyle(color: polishOnSurfaceVariant, fontSize: 11.0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: viewModel.soundEnabled,
                      activeTrackColor: polishPrimary,
                      activeThumbColor: Colors.white,
                      onChanged: (newValue) {
                        viewModel.updateSoundEnabled(newValue);
                      },
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(color: Color(0x33C4C6D0), height: 1.0),
                ),

                // Vibration Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.vibration,
                            color: polishOnSurfaceVariant,
                            size: 20.0,
                          ),
                          const SizedBox(width: 12.0),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tactile Vibration Impulse',
                                  style: TextStyle(color: polishOnSurface, fontSize: 14.0, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Emits vibration click on detection',
                                  style: TextStyle(color: polishOnSurfaceVariant, fontSize: 11.0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: viewModel.vibrationEnabled,
                      activeTrackColor: polishPrimary,
                      activeThumbColor: Colors.white,
                      onChanged: (newValue) {
                        viewModel.updateVibrationEnabled(newValue);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
