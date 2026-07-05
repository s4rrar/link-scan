import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_styles.dart';
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

  void _showCustomColorPickerDialog() {
    final colors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = widget.viewModel.isDarkMode;
        final primaryColor = polishPrimary;
        return BackdropFilter(
          filter: AppStyles.glassBlurFilter,
          child: AlertDialog(
            backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
              side: BorderSide(
                color: (isDark ? Colors.white : primaryColor).withOpacity(0.2),
                width: 1.2,
              ),
            ),
            title: const Text('Select Custom Color', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 260,
              height: 260,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: colors.length,
                itemBuilder: (context, index) {
                  final color = colors[index];
                  return GestureDetector(
                    onTap: () {
                      widget.viewModel.updateCustomColor(color);
                      widget.viewModel.updatePrimaryColor(PrimaryColorOption.custom);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.viewModel.customColor.value == color.value
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 4.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final isDark = viewModel.isDarkMode;
    final primaryColor = polishPrimary;

    return ListView(
      padding: const EdgeInsets.all(AppStyles.spacingNormal),
      children: [
        Text(
          'COMPANION CONFIGURATION',
          style: TextStyle(
            color: polishPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: AppStyles.spacingTiny),
        Text(
          'Manage your wireless settings, transmission ports, haptic feel, and hardware simulation delays.',
          style: TextStyle(
            color: polishOnSurfaceVariant,
            fontSize: 13.0,
          ),
        ),
        const SizedBox(height: AppStyles.spacingNormal),

        // Connection Card Group
        GlassContainer(
          isDark: isDark,
          primaryColor: primaryColor,
          borderRadius: AppStyles.radiusLarge,
          padding: const EdgeInsets.all(AppStyles.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PC SERVER IP ADDRESS',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: polishPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppStyles.spacingSmall),
              TextField(
                controller: _ipController,
                keyboardType: TextInputType.text,
                style: TextStyle(
                  color: polishOnSurface,
                  fontSize: 16.0,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 192.168.1.15',
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: polishPrimary, width: 1.5),
                    borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: polishOutline.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                  ),
                  filled: true,
                  fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
              ),
              const SizedBox(height: AppStyles.spacingNormal),
              Text(
                'SERVER PORT',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: polishPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppStyles.spacingSmall),
              TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: polishOnSurface,
                  fontSize: 16.0,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 8080',
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: polishPrimary, width: 1.5),
                    borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: polishOutline.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                  ),
                  filled: true,
                  fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
              ),
              const SizedBox(height: AppStyles.spacingLarge),

              // Connection Test Button
              SizedBox(
                width: double.infinity,
                height: 48.0,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: polishPrimary,
                    foregroundColor: polishOnPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusMedium)),
                    elevation: 0,
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
                const SizedBox(height: AppStyles.spacingNormal),
                GlassContainer(
                  isDark: isDark,
                  primaryColor: primaryColor,
                  borderRadius: AppStyles.radiusMedium,
                  padding: const EdgeInsets.all(AppStyles.spacingMedium),
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
                        style: TextStyle(fontSize: 12.0, color: polishOnSurface, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppStyles.spacingNormal),

        // Delay slider card
        GlassContainer(
          isDark: isDark,
          primaryColor: primaryColor,
          borderRadius: AppStyles.radiusLarge,
          padding: const EdgeInsets.all(AppStyles.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
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
                    style: TextStyle(
                      color: polishPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.spacingTiny),
              Text(
                'Configured delay window between scanned codes. Stops accidental scan trigger noise.',
                style: TextStyle(color: polishOnSurfaceVariant, fontSize: 11.0),
              ),
              const SizedBox(height: AppStyles.spacingNormal),
              Slider(
                value: viewModel.scanDelayMs,
                min: 500.0,
                max: 5000.0,
                divisions: 9,
                activeColor: polishPrimary,
                inactiveColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                onChanged: (newValue) {
                  viewModel.updateScanDelay(newValue);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppStyles.spacingNormal),

        // Beep & feel preference card
        GlassContainer(
          isDark: isDark,
          primaryColor: primaryColor,
          borderRadius: AppStyles.radiusLarge,
          padding: const EdgeInsets.all(AppStyles.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HAPTIC FEEDBACK PREFERENCES',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: polishPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppStyles.spacingNormal),

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
                        Expanded(
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
                child: Divider(color: Color(0x11C4C6D0), height: 1.0),
              ),

              // Vibration Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.vibration,
                          color: polishOnSurfaceVariant,
                          size: 20.0,
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
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
        const SizedBox(height: AppStyles.spacingNormal),

        // Appearance / Theme preference card
        GlassContainer(
          isDark: isDark,
          primaryColor: primaryColor,
          borderRadius: AppStyles.radiusLarge,
          padding: const EdgeInsets.all(AppStyles.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'APPEARANCE PREFERENCES',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: polishPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppStyles.spacingNormal),

              // Dark Theme Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          viewModel.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: polishOnSurfaceVariant,
                          size: 20.0,
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dark Theme Mode',
                                style: TextStyle(color: polishOnSurface, fontSize: 14.0, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Switch between light and dark visual aesthetics',
                                style: TextStyle(color: polishOnSurfaceVariant, fontSize: 11.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: viewModel.isDarkMode,
                    activeTrackColor: polishPrimary,
                    activeThumbColor: Colors.white,
                    onChanged: (newValue) {
                      viewModel.updateDarkMode(newValue);
                    },
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(color: Color(0x11C4C6D0), height: 1.0),
              ),

              // Primary Color Selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Primary Accent Color',
                    style: TextStyle(color: polishOnSurface, fontSize: 14.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppStyles.spacingTiny),
                  Text(
                    'Customize the primary color of the glassmorphic panels and borders',
                    style: TextStyle(color: polishOnSurfaceVariant, fontSize: 11.0),
                  ),
                  const SizedBox(height: AppStyles.spacingMedium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: PrimaryColorOption.values.map((option) {
                      final isSelected = viewModel.primaryColor == option;
                      final optionColor = isDark ? option.darkPrimary : option.lightPrimary;

                      return GestureDetector(
                        onTap: () {
                          if (option == PrimaryColorOption.custom) {
                            _showCustomColorPickerDialog();
                          } else {
                            viewModel.updatePrimaryColor(option);
                          }
                        },
                        child: Container(
                          width: 44.0,
                          height: 44.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: optionColor,
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? Colors.white : Colors.black)
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: optionColor.withOpacity(0.3),
                                blurRadius: 6.0,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20.0,
                                )
                              : (option == PrimaryColorOption.custom
                                  ? const Icon(
                                      Icons.palette_outlined,
                                      color: Colors.white70,
                                      size: 20.0,
                                    )
                                  : null),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
