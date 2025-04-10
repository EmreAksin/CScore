import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  final String _themePreferenceKey = 'isDarkMode';

  ThemeProvider() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;
  ThemeData get themeData =>
      _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  void _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool(_themePreferenceKey);
      if (isDarkMode != null) {
        _isDarkMode = isDarkMode;
        notifyListeners();
      }
    } catch (e) {
      Logger.error('Tema tercihi yüklenirken hata: $e');
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePreferenceKey, _isDarkMode);
    } catch (e) {
      Logger.error('Tema tercihi kaydedilirken hata: $e');
    }
  }

  Future<void> setTheme(bool isDarkMode) async {
    _isDarkMode = isDarkMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePreferenceKey, _isDarkMode);
    } catch (e) {
      Logger.error('Tema tercihi kaydedilirken hata: $e');
    }
  }
}
