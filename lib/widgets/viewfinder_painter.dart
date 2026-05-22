import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Camera scanner overlay viewport custom painter
class ViewfinderPainter extends CustomPainter {
  final double laserOffset;

  ViewfinderPainter({required this.laserOffset});

  @override
  void paint(Canvas canvas, Size size) {
    const overlayColor = Color(0x77000000);
    final strokeColor = polishPrimary;

    final viewfinderWidth = size.width * 0.75;
    final viewfinderHeight = size.height * 0.42;
    final left = (size.width - viewfinderWidth) / 2.0;
    final top = (size.height - viewfinderHeight) / 2.0;
    final right = left + viewfinderWidth;
    final bottom = top + viewfinderHeight;

    // Dimmed background
    final paintDim = Paint()..color = overlayColor;
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, top), paintDim);
    canvas.drawRect(Rect.fromLTRB(0, bottom, size.width, size.height), paintDim);
    canvas.drawRect(Rect.fromLTRB(0, top, left, bottom), paintDim);
    canvas.drawRect(Rect.fromLTRB(right, top, size.width, bottom), paintDim);

    // Viewfinder light border outline
    final paintOutline = Paint()
      ..color = strokeColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paintOutline);

    // Custom viewfinder corner brackets
    const cornerLength = 24.0;
    const thickness = 4.0;
    final paintCorner = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    // Top-Left corner
    canvas.drawPath(
      Path()
        ..moveTo(left + cornerLength, top)
        ..lineTo(left, top)
        ..lineTo(left, top + cornerLength),
      paintCorner,
    );

    // Top-Right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, top)
        ..lineTo(right, top)
        ..lineTo(right, top + cornerLength),
      paintCorner,
    );

    // Bottom-Left corner
    canvas.drawPath(
      Path()
        ..moveTo(left + cornerLength, bottom)
        ..lineTo(left, bottom)
        ..lineTo(left, bottom - cornerLength),
      paintCorner,
    );

    // Bottom-Right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, bottom)
        ..lineTo(right, bottom)
        ..lineTo(right, bottom - cornerLength),
      paintCorner,
    );

    // Animated Red Laser Line
    final laserY = top + (laserOffset * viewfinderHeight);
    final paintLaser = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawLine(
      Offset(left + 8.0, laserY),
      Offset(right - 8.0, laserY),
      paintLaser,
    );
  }

  @override
  bool shouldRepaint(covariant ViewfinderPainter oldDelegate) {
    return oldDelegate.laserOffset != laserOffset;
  }
}
