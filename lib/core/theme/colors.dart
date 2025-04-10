import 'package:flutter/material.dart';

class AppColors {
  // CS2 Ana Renk Paleti
  static const csPrimary = Color(
    0xFF1E2235,
  ); // Koyu lacivert (CS2 arayüz arka planı)
  static const csSecondary = Color(0xFF252B47); // Biraz daha açık lacivert
  static const csAccent = Color(0xFF34B4EB); // CS2 mavi vurgu
  static const csAccentAlt = Color(0xFF3EEAC2); // CS2 turkuaz vurgu
  static const csWarn = Color(0xFFFF5C51); // CS2 kırmızı/uyarı
  static const csSuccess = Color(0xFF39D98A); // Yeşil (başarı)
  static const csBlack = Color(0xFF151820); // Saf siyah yerine koyu lacivert

  // Metalik tonlar
  static const csGold = Color(0xFFFFD700); // Altın (S Tier)
  static const csSilver = Color(0xFFB9B9B9); // Gümüş (A Tier)
  static const csBronze = Color(0xFFCD7F32); // Bronz (B Tier)

  // Nötr tonlar
  static const csGray1 = Color(0xFF303446); // En koyu gri
  static const csGray2 = Color(0xFF414868); // Orta gri
  static const csGray3 = Color(0xFF8087A2); // Açık gri
  static const csGray4 = Color(0xFFC0CAF5); // En açık gri

  // Light theme color scheme
  static final ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: csAccent,
    onPrimary: Colors.white,
    primaryContainer: csAccent.withAlpha(26),
    onPrimaryContainer: csAccent.withAlpha(230),

    secondary: csAccentAlt,
    onSecondary: Colors.white,
    secondaryContainer: csAccentAlt.withAlpha(26),
    onSecondaryContainer: csAccentAlt.withAlpha(230),

    tertiary: csBronze,
    onTertiary: Colors.white,
    tertiaryContainer: csBronze.withAlpha(26),
    onTertiaryContainer: csBronze,

    error: csWarn,
    onError: Colors.white,
    errorContainer: csWarn.withAlpha(26),
    onErrorContainer: csWarn,

    surface: Colors.white,
    onSurface: csBlack,

    surfaceContainerHighest: csGray4.withAlpha(102),
    onSurfaceVariant: csGray2,

    outline: csGray3.withAlpha(128),
    shadow: csBlack.withAlpha(26),

    inverseSurface: csPrimary,
    onInverseSurface: Colors.white,
    inversePrimary: Colors.white,
    surfaceTint: csAccent.withAlpha(13),
  );

  // Dark theme color scheme
  static final ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: csAccent,
    onPrimary: Colors.white,
    primaryContainer: csAccent.withAlpha(38),
    onPrimaryContainer: Colors.white,

    secondary: csAccentAlt,
    onSecondary: Colors.white,
    secondaryContainer: csAccentAlt.withAlpha(38),
    onSecondaryContainer: Colors.white,

    tertiary: csBronze,
    onTertiary: Colors.white,
    tertiaryContainer: csBronze.withAlpha(38),
    onTertiaryContainer: Colors.white,

    error: csWarn,
    onError: Colors.white,
    errorContainer: csWarn.withAlpha(38),
    onErrorContainer: Colors.white,

    surface: csSecondary,
    onSurface: Colors.white,

    surfaceContainerHighest: csGray1,
    onSurfaceVariant: csGray4,

    outline: csGray3.withAlpha(77),
    shadow: Colors.black,

    inverseSurface: Colors.white,
    onInverseSurface: csBlack,
    inversePrimary: csAccent,
    surfaceTint: csBlack,
  );

  // Tier renkleri
  static Color getTierColor(String? tier, {bool darkMode = false}) {
    if (tier == null) return darkMode ? csGray1 : csGray4.withAlpha(77);

    switch (tier.toUpperCase()) {
      case 'S':
        return darkMode ? csGold.withAlpha(51) : csGold.withAlpha(38);
      case 'A':
        return darkMode ? csSilver.withAlpha(51) : csSilver.withAlpha(38);
      case 'B':
        return darkMode ? csBronze.withAlpha(51) : csBronze.withAlpha(38);
      default:
        return darkMode ? csGray1 : csGray4.withAlpha(77);
    }
  }

  static Color getTierTextColor(String? tier, {bool darkMode = false}) {
    if (tier == null) return darkMode ? csGray4 : csGray2;

    switch (tier.toUpperCase()) {
      case 'S':
        return darkMode ? csGold : csGold.withAlpha(204);
      case 'A':
        return darkMode ? csSilver : csSilver.withAlpha(204);
      case 'B':
        return darkMode ? csBronze : csBronze.withAlpha(204);
      default:
        return darkMode ? csGray4 : csGray2;
    }
  }

  // Lig için renk üreteci - daha uyumlu renkler için HSL kullanımı
  static Color generateLeagueColor(String leagueName, {bool darkMode = false}) {
    // İsmin hash değeri
    final hash = leagueName.hashCode.abs();

    // Sabit doygunluk ve parlaklık ile sınırlı renk çeşitliliği
    double hue = (hash % 360).toDouble();
    double saturation = darkMode ? 0.55 : 0.65; // Koyu modda daha az doygun
    double lightness = darkMode ? 0.35 : 0.45; // Koyu modda daha karanlık

    // HSL'den RGB'ye dönüşüm
    return _hslToColor(hue, saturation, lightness);
  }

  // HSL renk formatını Color objesine dönüştürme
  static Color _hslToColor(double h, double s, double l) {
    // HSL'den RGB'ye dönüşüm algoritması
    double r, g, b;

    if (s == 0) {
      r = g = b = l;
    } else {
      double hue2rgb(double p, double q, double t) {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
        return p;
      }

      final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      final p = 2 * l - q;
      r = hue2rgb(p, q, h / 360 + 1 / 3);
      g = hue2rgb(p, q, h / 360);
      b = hue2rgb(p, q, h / 360 - 1 / 3);
    }

    return Color.fromRGBO(
      (r * 255).round(),
      (g * 255).round(),
      (b * 255).round(),
      1,
    );
  }
}
