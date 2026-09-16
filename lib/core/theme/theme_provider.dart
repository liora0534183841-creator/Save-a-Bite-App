import 'package:flutter/material.dart';

/// A global state provider that manages the application's visual theme.
/// 
/// Allows users to manually toggle between Light and Dark modes.
/// When the theme changes, it notifies all listening widgets to seamlessly
/// rebuild with the updated [AppColors] scheme.
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Toggles the active application theme.
  /// 
  /// [isOn] should be true to activate Dark Mode, and false for Light Mode.
  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}