// Uygulama tema yönetimi için provider sınıfı

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../theme/colors.dart';

class ThemeProvider extends ChangeNotifier {
  // Varsayılan olarak koyu tema
  ThemeMode _themeMode = ThemeMode.dark;

  // Tema modunu döndürür
  ThemeMode get themeMode => _themeMode;

  // Temanın karanlık olup olmadığını kontrol et
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Başlangıçta tema tercihini yükle
  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isLightMode = prefs.getBool(AppConstants.themeKey) ?? false;

    _themeMode = isLightMode ? ThemeMode.light : ThemeMode.dark;
    _updateSystemUIOverlay(); // Sistem UI stilini güncelle
    notifyListeners();
  }

  // Temayı değiştir
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

    // Sistem UI stilini güncelle
    _updateSystemUIOverlay();

    // Tema tercihini kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.themeKey, _themeMode == ThemeMode.light);

    notifyListeners();
  }

  // Sistem UI stilini güncelle
  void _updateSystemUIOverlay() {
    if (_themeMode == ThemeMode.dark) {
      // Karanlık tema için sistem UI ayarları
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.csPrimary,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    } else {
      // Açık tema için sistem UI ayarları
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    }
  }
}

// Karanlık tema
ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppConstants.backgroundColor,
  primaryColor: AppConstants.primaryColor,
  colorScheme: const ColorScheme.dark(
    primary: AppConstants.primaryColor,
    secondary: AppConstants.accentColor,
    surface: AppConstants.cardColor,
  ),
  cardColor: AppConstants.cardColor,
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      color: AppConstants.textColorPrimary,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      color: AppConstants.textColorPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(color: AppConstants.textColorPrimary, fontSize: 16),
    bodyMedium: TextStyle(color: AppConstants.textColorSecondary, fontSize: 14),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppConstants.primaryColor,
    foregroundColor: AppConstants.textColorPrimary,
    elevation: 0,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppConstants.primaryColor,
    selectedItemColor: AppConstants.accentColor,
    unselectedItemColor: AppConstants.textColorSecondary,
  ),
  tabBarTheme: const TabBarTheme(
    labelColor: AppConstants.accentColor,
    unselectedLabelColor: AppConstants.textColorSecondary,
    indicator: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: AppConstants.accentColor, width: 2),
      ),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppConstants.accentColor,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppConstants.accentColor,
      side: const BorderSide(color: AppConstants.accentColor),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  iconTheme: const IconThemeData(color: AppConstants.textColorPrimary),
  dividerTheme: const DividerThemeData(color: Color(0xFF3D3E50), thickness: 1),
);

// Aydınlık tema
ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  primaryColor: AppConstants.primaryColor,
  colorScheme: ColorScheme.light(
    primary: AppConstants.primaryColor,
    secondary: AppConstants.accentColor,
    surface: Colors.grey[100]!,
  ),
  cardColor: Colors.white,
  textTheme: TextTheme(
    titleLarge: TextStyle(
      color: Colors.grey[900],
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      color: Colors.grey[900],
      fontSize: 18,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(color: Colors.grey[900], fontSize: 16),
    bodyMedium: TextStyle(color: Colors.grey[700], fontSize: 14),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppConstants.primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: AppConstants.accentColor,
    unselectedItemColor: Colors.grey[600],
  ),
  tabBarTheme: TabBarTheme(
    labelColor: AppConstants.accentColor,
    unselectedLabelColor: Colors.grey[600],
    indicator: const BoxDecoration(
      border: Border(
        bottom: BorderSide(color: AppConstants.accentColor, width: 2),
      ),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppConstants.accentColor,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppConstants.accentColor,
      side: const BorderSide(color: AppConstants.accentColor),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  iconTheme: IconThemeData(color: Colors.grey[900]),
  dividerTheme: const DividerThemeData(color: Color(0xFFE0E0E0), thickness: 1),
);
