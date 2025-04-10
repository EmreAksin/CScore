// Uygulama genelinde kullanılan sabit değerleri içerir

import 'package:flutter/material.dart';

class AppConstants {
  // Uygulama adı ve sürüm
  static const String appName = 'CScore';
  static const String appVersion = '1.0.0';

  // Dil ve ülke kodları
  static const String defaultLocale = 'tr';
  static const List<String> supportedLanguages = ['tr', 'en', 'ru', 'uk'];
  static const Map<String, String> languageNames = {
    'tr': 'Türkçe',
    'en': 'English',
    'ru': 'Русский',
    'uk': 'Українська',
  };

  // Tema sabitleri
  static const Color primaryColor = Color(0xFF2C2E3B);
  static const Color accentColor = Color(0xFFFF4655);
  static const Color backgroundColor = Color(0xFF1A1C27);
  static const Color cardColor = Color(0xFF242736);
  static const Color textColorPrimary = Color(0xFFF1F1F1);
  static const Color textColorSecondary = Color(0xFFABABAB);

  // Asset yolları
  static const String logoPath = 'assets/images/logo.png';
  static const String placeholderImage = 'assets/images/placeholder.png';

  // Yerel depolama anahtarları
  static const String themeKey = 'theme';
  static const String languageKey = 'language';
  static const String userIdKey = 'userId';
  static const String authTokenKey = 'authToken';
  static const String favoritesKey = 'favorites';
}
