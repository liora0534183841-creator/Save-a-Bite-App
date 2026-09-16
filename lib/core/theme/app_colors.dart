import 'package:flutter/material.dart';

/// A centralized utility class managing all application colors.
/// 
/// Provides consistent brand colors, typography colors, and supports
/// dynamic color switching for Light and Dark modes.
/// Instances of this class should not be created.
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // --- Brand Colors ---
  /// Primary deep blue used for app bars and main elements.
  static const Color deepBlue = Color(0xFF0D47A1);    
  /// Accent blue used for buttons, icons, and highlights.
  static const Color accentBlue = Color(0xFF1976D2);  
  /// Default background color for light mode.
  static const Color mainBackgroundBlue = Color(0xFFE3F2FD); 
  
  // --- UI & Typography Colors ---
  /// Default color for cards and elevated surfaces in light mode.
  static const Color whiteCard = Colors.white;
  /// Secondary text color for subtitles and hints.
  static const Color textLight = Colors.grey;
  /// Primary text color for standard readability in light mode.
  static const Color textDark = Colors.black87; 
  
  // --- Dark Mode Colors ---
  /// Main background color when dark mode is active.
  static const Color darkBackground = Color(0xFF121212);
  /// Surface color for cards and dialogs when dark mode is active.
  static const Color darkSurface = Color(0xFF1E1E1E);
  /// Primary text color when dark mode is active.
  static const Color darkText = Color(0xFFE0E0E0);

  /// Dynamically returns the correct background color based on the current theme (Light/Dark).
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBackground 
        : mainBackgroundBlue;
  }

  /// Dynamically returns the correct card surface color based on the current theme (Light/Dark).
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkSurface 
        : whiteCard;
  }
}