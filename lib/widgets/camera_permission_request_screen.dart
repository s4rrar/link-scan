import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CameraPermissionRequestScreen extends StatelessWidget {
  final VoidCallback onRequestPermission;

  const CameraPermissionRequestScreen({super.key, required this.onRequestPermission});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            color: polishPrimary,
            size: 96.0,
          ),
          const SizedBox(height: 24.0),
          Text(
            'Camera Permission Required',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
              color: polishOnBackground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12.0),
          Text(
            'To scan physical product barcodes or QR codes in real-time, please authorize camera use below.',
            style: TextStyle(
              fontSize: 14.0,
              color: polishOnSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32.0),
          SizedBox(
            width: double.infinity,
            height: 50.0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: polishPrimary,
                foregroundColor: polishOnPrimary,
                shape: roundedCornerShape(12.0),
              ),
              onPressed: onRequestPermission,
              child: const Text(
                'Authorize Camera',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper rounded shape
  OutlinedBorder roundedCornerShape(double radius) {
    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
  }
}
