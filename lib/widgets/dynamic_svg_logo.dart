import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

class DynamicSvgLogo extends StatelessWidget {
  final double width;
  final double height;
  final Color primaryColor;

  const DynamicSvgLogo({
    super.key,
    required this.width,
    required this.height,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString('logo/logo.svg'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final hexColor = '#${primaryColor.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';
          
          final hsl = HSLColor.fromColor(primaryColor);
          final lighterColor = hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor();
          final hexLighterColor = '#${lighterColor.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';

          String svgString = snapshot.data!;
          svgString = svgString.replaceAll('#0F9BFC', hexLighterColor);
          svgString = svgString.replaceAll('#0374E6', hexColor);

          return SvgPicture.string(
            svgString,
            width: width,
            height: height,
          );
        }
        
        return SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: SizedBox(
              width: 16.0,
              height: 16.0,
              child: CircularProgressIndicator(strokeWidth: 2.0),
            ),
          ),
        );
      },
    );
  }
}
