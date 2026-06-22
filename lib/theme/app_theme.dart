import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemeState {
  static bool isDark = false;
}

// Light theme constants
const Color _lightPrimary = Color(0xFF0061A4);
const Color _lightOnPrimary = Color(0xFFFFFFFF);
const Color _lightPrimaryContainer = Color(0xFFD1E4FF);
const Color _lightOnPrimaryContainer = Color(0xFF001D36);
const Color _lightSecondary = Color(0xFF535F70);
const Color _lightOnSecondary = Color(0xFFFFFFFF);
const Color _lightSecondaryContainer = Color(0xFFD6E4F7);
const Color _lightBackground = Color(0xFFFDFBFF);
const Color _lightOnBackground = Color(0xFF1A1C1E);
const Color _lightSurface = Color(0xFFFFFFFF);
const Color _lightOnSurface = Color(0xFF1A1C1E);
const Color _lightSurfaceVariant = Color(0xFFE1E2EC);
const Color _lightOnSurfaceVariant = Color(0xFF44474E);
const Color _lightOutline = Color(0xFFC4C6D0);
const Color _lightError = Color(0xFFBA1A1A);
const Color _lightErrorContainer = Color(0xFFFFDAD6);
const Color _lightOnError = Color(0xFFFFFFFF);
const Color _lightSurfaceContainerLow = Color(0xFFF3F3FA);

// Dark theme constants (harmonious dark mode palette)
const Color _darkPrimary = Color(0xFF9ECAFF);
const Color _darkOnPrimary = Color(0xFF003258);
const Color _darkPrimaryContainer = Color(0xFF00497D);
const Color _darkOnPrimaryContainer = Color(0xFFD1E4FF);
const Color _darkSecondary = Color(0xFFBBC7DB);
const Color _darkOnSecondary = Color(0xFF253140);
const Color _darkSecondaryContainer = Color(0xFF3B4858);
const Color _darkBackground = Color(0xFF121314);
const Color _darkOnBackground = Color(0xFFE2E2E6);
const Color _darkSurface = Color(0xFF1A1C1E);
const Color _darkOnSurface = Color(0xFFE2E2E6);
const Color _darkSurfaceVariant = Color(0xFF44474E);
const Color _darkOnSurfaceVariant = Color(0xFFC4C6D0);
const Color _darkOutline = Color(0xFF8E9099);
const Color _darkError = Color(0xFFFFB4AB);
const Color _darkErrorContainer = Color(0xFF93000A);
const Color _darkOnError = Color(0xFF690005);
const Color _darkSurfaceContainerLow = Color(0xFF0F1113);

// Dynamic Getters for polish colors
Color get polishPrimary => AppThemeState.isDark ? _darkPrimary : _lightPrimary;
Color get polishOnPrimary => AppThemeState.isDark ? _darkOnPrimary : _lightOnPrimary;
Color get polishPrimaryContainer => AppThemeState.isDark ? _darkPrimaryContainer : _lightPrimaryContainer;
Color get polishOnPrimaryContainer => AppThemeState.isDark ? _darkOnPrimaryContainer : _lightOnPrimaryContainer;
Color get polishSecondary => AppThemeState.isDark ? _darkSecondary : _lightSecondary;
Color get polishOnSecondary => AppThemeState.isDark ? _darkOnSecondary : _lightOnSecondary;
Color get polishSecondaryContainer => AppThemeState.isDark ? _darkSecondaryContainer : _lightSecondaryContainer;
Color get polishBackground => AppThemeState.isDark ? _darkBackground : _lightBackground;
Color get polishOnBackground => AppThemeState.isDark ? _darkOnBackground : _lightOnBackground;
Color get polishSurface => AppThemeState.isDark ? _darkSurface : _lightSurface;
Color get polishOnSurface => AppThemeState.isDark ? _darkOnSurface : _lightOnSurface;
Color get polishSurfaceVariant => AppThemeState.isDark ? _darkSurfaceVariant : _lightSurfaceVariant;
Color get polishOnSurfaceVariant => AppThemeState.isDark ? _darkOnSurfaceVariant : _lightOnSurfaceVariant;
Color get polishOutline => AppThemeState.isDark ? _darkOutline : _lightOutline;
Color get polishError => AppThemeState.isDark ? _darkError : _lightError;
Color get polishErrorContainer => AppThemeState.isDark ? _darkErrorContainer : _lightErrorContainer;
Color get polishOnError => AppThemeState.isDark ? _darkOnError : _lightOnError;
Color get polishSurfaceContainerLow => AppThemeState.isDark ? _darkSurfaceContainerLow : _lightSurfaceContainerLow;

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: _lightPrimary,
    onPrimary: _lightOnPrimary,
    primaryContainer: _lightPrimaryContainer,
    onPrimaryContainer: _lightOnPrimaryContainer,
    secondary: _lightSecondary,
    onSecondary: _lightOnSecondary,
    secondaryContainer: _lightSecondaryContainer,
    background: _lightBackground,
    onBackground: _lightOnBackground,
    surface: _lightSurface,
    onSurface: _lightOnSurface,
    surfaceVariant: _lightSurfaceVariant,
    onSurfaceVariant: _lightOnSurfaceVariant,
    outline: _lightOutline,
    error: _lightError,
    onError: _lightOnError,
    errorContainer: _lightErrorContainer,
  ),
  scaffoldBackgroundColor: _lightBackground,
  textTheme: GoogleFonts.publicSansTextTheme(),
);

final ThemeData darkAppTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: _darkPrimary,
    onPrimary: _darkOnPrimary,
    primaryContainer: _darkPrimaryContainer,
    onPrimaryContainer: _darkOnPrimaryContainer,
    secondary: _darkSecondary,
    onSecondary: _darkOnSecondary,
    secondaryContainer: _darkSecondaryContainer,
    background: _darkBackground,
    onBackground: _darkOnBackground,
    surface: _darkSurface,
    onSurface: _darkOnSurface,
    surfaceVariant: _darkSurfaceVariant,
    onSurfaceVariant: _darkOnSurfaceVariant,
    outline: _darkOutline,
    error: _darkError,
    onError: _darkOnError,
    errorContainer: _darkErrorContainer,
  ),
  scaffoldBackgroundColor: _darkBackground,
  textTheme: GoogleFonts.publicSansTextTheme(Typography.whiteMountainView),
);

