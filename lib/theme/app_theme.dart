import 'package:flutter/material.dart';

// Color scheme constants matching the Kotlin app theme
const Color polishPrimary = Color(0xFF0061A4);
const Color polishOnPrimary = Color(0xFFFFFFFF);
const Color polishPrimaryContainer = Color(0xFFD1E4FF);
const Color polishOnPrimaryContainer = Color(0xFF001D36);
const Color polishSecondary = Color(0xFF535F70);
const Color polishOnSecondary = Color(0xFFFFFFFF);
const Color polishSecondaryContainer = Color(0xFFD6E4F7);
const Color polishBackground = Color(0xFFFDFBFF);
const Color polishOnBackground = Color(0xFF1A1C1E);
const Color polishSurface = Color(0xFFFFFFFF);
const Color polishOnSurface = Color(0xFF1A1C1E);
const Color polishSurfaceVariant = Color(0xFFE1E2EC);
const Color polishOnSurfaceVariant = Color(0xFF44474E);
const Color polishOutline = Color(0xFFC4C6D0);
const Color polishError = Color(0xFFBA1A1A);
const Color polishErrorContainer = Color(0xFFFFDAD6);
const Color polishOnError = Color(0xFFFFFFFF);
const Color polishSurfaceContainerLow = Color(0xFFF3F3FA);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: polishPrimary,
    onPrimary: polishOnPrimary,
    primaryContainer: polishPrimaryContainer,
    onPrimaryContainer: polishOnPrimaryContainer,
    secondary: polishSecondary,
    onSecondary: polishOnSecondary,
    secondaryContainer: polishSecondaryContainer,
    background: polishBackground,
    onBackground: polishOnBackground,
    surface: polishSurface,
    onSurface: polishOnSurface,
    surfaceVariant: polishSurfaceVariant,
    onSurfaceVariant: polishOnSurfaceVariant,
    outline: polishOutline,
    error: polishError,
    onError: polishOnError,
    errorContainer: polishErrorContainer,
  ),
  scaffoldBackgroundColor: polishBackground,
  fontFamily: 'Roboto',
);
