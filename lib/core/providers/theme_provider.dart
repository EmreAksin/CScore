import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  bool _isDarkMode = false;
  bool _isLoading = true;
  static const String _isDarkModeKey = 'is_dark_mode';

  // Getter'lar
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;

  // Tema tipini döndür
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Tema verileri
  ThemeData get lightTheme => AppTheme.lightTheme;
  ThemeData get darkTheme => AppTheme.darkTheme;

  // ThemeProvider başlatma
  ThemeProvider() {
    _loadThemePreference();
  }

  // Kaydedilmiş tema ayarını yükle
  Future<void> _loadThemePreference() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode =
          prefs.getBool(_isDarkModeKey) ?? true; // Varsayılan olarak koyu tema
      _logger.i('Tema tercihi yüklendi: ${_isDarkMode ? 'Koyu' : 'Açık'} tema');
    } catch (e) {
      _logger.e('Tema tercihi yüklenirken hata: $e');
      _isDarkMode = true; // Hata durumunda koyu tema
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Temayı değiştir
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    _logger.i('Tema değiştirildi: ${_isDarkMode ? 'Koyu' : 'Açık'} tema');
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isDarkModeKey, _isDarkMode);
    } catch (e) {
      _logger.e('Tema tercihi kaydedilirken hata: $e');
    }
  }
}
