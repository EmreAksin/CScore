import 'package:flutter/material.dart';

class AppTextStyles {
  static const String fontFamily = 'Poppins';

  static const TextStyle headline1 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: 28,
    letterSpacing: -0.5,
  );

  static const TextStyle headline2 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: 24,
    letterSpacing: -0.5,
  );

  static const TextStyle headline3 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    letterSpacing: -0.25,
  );

  static const TextStyle headline4 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    letterSpacing: -0.25,
  );

  static const TextStyle headline5 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  static const TextStyle headline6 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 14,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 16,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 14,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.normal,
    fontSize: 16,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.normal,
    fontSize: 14,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.normal,
    fontSize: 12,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 10,
    letterSpacing: 0.5,
  );

  static TextTheme get textTheme => const TextTheme(
    displayLarge: headline1,
    displayMedium: headline2,
    displaySmall: headline3,
    headlineMedium: headline4,
    headlineSmall: headline5,
    titleLarge: headline6,
    titleMedium: subtitle1,
    titleSmall: subtitle2,
    bodyLarge: bodyText1,
    bodyMedium: bodyText2,
    labelLarge: button,
    bodySmall: caption,
    labelSmall: overline,
  );

  // CS2 için özel stiller
  static TextStyle get tournamentTitle =>
      headline5.copyWith(fontWeight: FontWeight.bold);

  static TextStyle get matchTitle =>
      headline6.copyWith(fontWeight: FontWeight.bold);

  static TextStyle get tierLabel =>
      caption.copyWith(fontWeight: FontWeight.bold);

  static TextStyle get liveLabel =>
      caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold);

  static TextStyle get dateText =>
      caption.copyWith(color: Colors.grey.shade700);

  static TextStyle get scoreText =>
      headline4.copyWith(fontWeight: FontWeight.bold);

  static TextStyle get tabLabel => button.copyWith(fontWeight: FontWeight.w600);
}
