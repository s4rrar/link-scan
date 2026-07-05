import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Enum representing the primary color options in the app.
enum PrimaryColorOption {
  blue('Classic Blue'),
  purple('Violet Purple'),
  custom('Custom Color'),
  orange('Sunset Orange'),
  rose('Elegant Rose');

  final String name;
  const PrimaryColorOption(this.name);

  Color get lightPrimary {
    switch (this) {
      case PrimaryColorOption.blue: return const Color(0xFF3B82F6);
      case PrimaryColorOption.purple: return const Color(0xFF8B5CF6);
      case PrimaryColorOption.orange: return const Color(0xFFF97316);
      case PrimaryColorOption.rose: return const Color(0xFFEC4899);
      case PrimaryColorOption.custom: return AppThemeState.customColorValue;
    }
  }

  Color get darkPrimary {
    switch (this) {
      case PrimaryColorOption.blue: return const Color(0xFF9ECAFF);
      case PrimaryColorOption.purple: return const Color(0xFFD0BCFF);
      case PrimaryColorOption.orange: return const Color(0xFFFFB49A);
      case PrimaryColorOption.rose: return const Color(0xFFFFB1C8);
      case PrimaryColorOption.custom:
        final hsl = HSLColor.fromColor(AppThemeState.customColorValue);
        return hsl.withLightness((hsl.lightness + 0.25).clamp(0.5, 0.9)).toColor();
    }
  }

  Color get lightPrimaryContainer => lightPrimary.withOpacity(0.15);
  Color get darkPrimaryContainer => darkPrimary.withOpacity(0.24);
  Color get lightOnPrimaryContainer => lightPrimary;
  Color get darkOnPrimaryContainer => darkPrimary;
}

/// Global styles repository containing layout constraints, glassmorphic configurations,
/// padding constants, and visual gradients.
class AppStyles {
  // Border radius values
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 20.0;
  static const double radiusLarge = 28.0;
  static const double radiusExtraLarge = 36.0;

  // Blur values for glassmorphism (enhanced for premium diffusion)
  static const double glassBlurSigma = 24.0;

  // Opacities for glass panels
  static const double bgLightOpacity = 0.42; // Translucent white
  static const double bgDarkOpacity = 0.35; // Translucent dark violet
  static const double borderLightOpacity = 0.45; // Stronger reflective edge
  static const double borderDarkOpacity = 0.15;

  // Margin and padding values
  static const double spacingTiny = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingNormal = 16.0;
  static const double spacingLarge = 20.0;
  static const double spacingExtraLarge = 24.0;
  static const double spacingHuge = 32.0;

  // Backdrop Filter configurations
  static ImageFilter get glassBlurFilter => ImageFilter.blur(
        sigmaX: glassBlurSigma,
        sigmaY: glassBlurSigma,
      );

  // Background gradients - rich and aesthetic
  static BoxDecoration getBackgroundDecoration(bool isDark, Color primaryColor) {
    if (isDark) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B081B), // Deep dark violet
            Color(0xFF0F0E2A), // Deep dark indigo
            Color(0xFF070614), // Dark background base
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      );
    } else {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEEF0FC), // Pastel lavender-blue
            Color(0xFFFFF3F0), // Warm rose-peach cream
            Color(0xFFE0F7FA), // Soft mint / sky blue
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      );
    }
  }

  // Base glass panel decoration (crisp white highlight borders on light mode)
  static BoxDecoration getGlassDecoration({
    required bool isDark,
    required Color primaryColor,
    double radius = radiusMedium,
  }) {
    final bgOpacity = isDark ? bgDarkOpacity : bgLightOpacity;
    final borderOpacity = isDark ? borderDarkOpacity : borderLightOpacity;

    // Pure reflective white for light mode, deep textured dark violet for dark mode
    final glassColor = isDark 
        ? const Color(0xFF17132B).withOpacity(bgOpacity)
        : Colors.white.withOpacity(bgOpacity);

    // Light reflective edge is crucial for light glassmorphism to stand out from the canvas
    final borderColor = isDark
        ? Colors.white.withOpacity(borderOpacity)
        : Colors.white.withOpacity(borderOpacity);

    return BoxDecoration(
      color: glassColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          // Colored shadow (indigo-tinted) gives light mode depth without looking muddy
          color: (isDark ? Colors.black : const Color(0xFF6356A2)).withOpacity(isDark ? 0.35 : 0.08),
          blurRadius: 28.0,
          spreadRadius: -4.0,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}

/// A reusable glassmorphic container that wraps child elements in a blurred panel.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isDark;
  final Color primaryColor;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    required this.isDark,
    required this.primaryColor,
    this.borderRadius = AppStyles.radiusMedium,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: AppStyles.glassBlurFilter,
          child: Container(
            padding: padding,
            decoration: AppStyles.getGlassDecoration(
              isDark: isDark,
              primaryColor: primaryColor,
              radius: borderRadius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A wrapper widget that places glowing ambient color blobs behind its child widget,
/// making the glassmorphism visual pops.
class GlassBackground extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color primaryColor;

  const GlassBackground({
    super.key,
    required this.child,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppStyles.getBackgroundDecoration(isDark, primaryColor),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Blob 1: Top Right glow
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withOpacity(isDark ? 0.22 : 0.26),
                    primaryColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Blob 2: Bottom Left glow (Vibrant Lavender-Purple)
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFD380FF).withOpacity(isDark ? 0.18 : 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Blob 3: Middle Center glow (Cyan/Teal accent)
          Positioned(
            top: 250,
            left: -120,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00E5FF).withOpacity(isDark ? 0.12 : 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Blob 4: Bottom Right glow
          Positioned(
            bottom: 100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withOpacity(isDark ? 0.14 : 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Screen contents
          child,
        ],
      ),
    );
  }
}
