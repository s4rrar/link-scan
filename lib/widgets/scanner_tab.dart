import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../viewmodels/barcode_viewmodel.dart';
import 'camera_permission_request_screen.dart';
import 'viewfinder_painter.dart';

class ScannerTab extends StatefulWidget {
  final BarcodeViewModel viewModel;

  const ScannerTab({super.key, required this.viewModel});

  @override
  State<ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<ScannerTab> with SingleTickerProviderStateMixin {
  late final AnimationController _laserController;
  final MobileScannerController _cameraController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  String getBarcodeFormatName(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.code128:
        return 'Code 128';
      case BarcodeFormat.code39:
        return 'Code 39';
      case BarcodeFormat.code93:
        return 'Code 93';
      case BarcodeFormat.codabar:
        return 'Codabar';
      case BarcodeFormat.dataMatrix:
        return 'Data Matrix';
      case BarcodeFormat.ean13:
        return 'EAN-13';
      case BarcodeFormat.ean8:
        return 'EAN-8';
      case BarcodeFormat.itf:
        return 'ITF';
      case BarcodeFormat.qrCode:
        return 'QR Code';
      case BarcodeFormat.upcA:
        return 'UPC-A';
      case BarcodeFormat.upcE:
        return 'UPC-E';
      case BarcodeFormat.pdf417:
        return 'PDF417';
      case BarcodeFormat.aztec:
        return 'Aztec';
      default:
        return 'Barcode';
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32.0),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Camera preview
                  MobileScanner(
                    controller: _cameraController,
                    fit: BoxFit.cover,
                    onDetect: (capture) {
                      if (!viewModel.isCoolingDown) {
                        for (final barcode in capture.barcodes) {
                          final value = barcode.rawValue;
                          if (value != null) {
                            viewModel.onBarcodeScanned(
                              value,
                              getBarcodeFormatName(barcode.format),
                            );
                            break;
                          }
                        }
                      }
                    },
                    errorBuilder: (context, error, child) {
                      return CameraPermissionRequestScreen(
                        onRequestPermission: () => _cameraController.start(),
                      );
                    },
                  ),

                  // Translucent Viewfinder Overlay
                  AnimatedBuilder(
                    animation: _laserController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: ViewfinderPainter(laserOffset: _laserController.value),
                        child: const SizedBox.expand(),
                      );
                    },
                  ),

                  // Inner border overlay (draws stroke strictly inside to avoid layout gaps, on top of viewfinder overlay to prevent dimming)
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32.0),
                        border: Border.all(color: polishPrimaryContainer, width: 8.0),
                      ),
                    ),
                  ),

                  // Connection active badge in top-right
                  Positioned(
                    top: 16.0,
                    right: 16.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(100.0),
                        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.0),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi, color: Colors.white, size: 14.0),
                          SizedBox(width: 6.0),
                          Text(
                            'Local Link Active',
                            style: TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Flash toggle button in top-left
                  Positioned(
                    top: 16.0,
                    left: 16.0,
                    child: ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _cameraController,
                      builder: (context, state, child) {
                        final isTorchOn = state.torchState == TorchState.on;
                        return IconButton(
                          icon: Icon(
                            isTorchOn ? Icons.flash_on : Icons.flash_off,
                            color: isTorchOn ? Colors.yellow : Colors.white,
                            size: 20.0,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.4),
                            shape: const CircleBorder(),
                            side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.0),
                            minimumSize: const Size(40.0, 40.0),
                          ),
                          onPressed: () => _cameraController.toggleTorch(),
                        );
                      },
                    ),
                  ),

                  // Cooldown Progress Overlay Screen
                  if (viewModel.isCoolingDown)
                    Container(
                      color: Colors.black.withOpacity(0.4),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: polishError.withOpacity(0.3), width: 1.0),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 54.0,
                              height: 54.0,
                              child: CircularProgressIndicator(
                                value: viewModel.cooldownProgress,
                                color: polishError,
                                strokeWidth: 4.0,
                                backgroundColor: Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            const Text(
                              'PREVENTING DUPLICATE',
                              style: TextStyle(
                                color: polishError,
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Cooldown active: ${(viewModel.scanDelayMs * viewModel.cooldownProgress / 1000.0).toStringAsFixed(1)}s',
                              style: const TextStyle(
                                color: polishOnSurface,
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Bottom card with details of last scanned item
          if (viewModel.lastScannedValue != null)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
                side: BorderSide(color: polishOutline.withOpacity(0.5), width: 1.0),
              ),
              color: polishSurface,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: polishPrimaryContainer,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.qr_code,
                        color: polishOnPrimaryContainer,
                        size: 24.0,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LAST SCANNED • ${viewModel.lastScannedFormat ?? "FORMAT"}',
                            style: const TextStyle(
                              color: polishPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.0,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            viewModel.lastScannedValue ?? '',
                            style: const TextStyle(
                              color: polishOnSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4.0),
                          const Text(
                            'Sent to companion in real-time',
                            style: TextStyle(
                              color: polishOnSurfaceVariant,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF2E7D32),
                      size: 24.0,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
