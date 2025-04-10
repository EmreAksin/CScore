import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: AppColors.lightColorScheme,
    textTheme: AppTextStyles.textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.csPrimary,
      foregroundColor: Colors.white,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.csPrimary,
      selectedItemColor: AppColors.csAccent,
      unselectedItemColor: Colors.white.withOpacity(0.7),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: AppColors.lightColorScheme.primary,
      unselectedLabelColor: AppColors.lightColorScheme.onSurfaceVariant,
      indicatorColor: AppColors.lightColorScheme.primary,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightColorScheme.surfaceContainerHighest.withAlpha(
        128,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.lightColorScheme.outline.withAlpha(128),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.lightColorScheme.primary,
          width: 2,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightColorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: AppColors.lightColorScheme.onSecondaryContainer,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: AppColors.darkColorScheme,
    textTheme: AppTextStyles.textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.csPrimary,
      foregroundColor: Colors.white,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.csPrimary,
      selectedItemColor: AppColors.csAccent,
      unselectedItemColor: Colors.white.withOpacity(0.7),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: AppColors.darkColorScheme.primary,
      unselectedLabelColor: AppColors.darkColorScheme.onSurfaceVariant,
      indicatorColor: AppColors.darkColorScheme.primary,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkColorScheme.surfaceContainerHighest.withAlpha(
        77,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.darkColorScheme.outline.withAlpha(128),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.darkColorScheme.primary,
          width: 2,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkColorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: AppColors.darkColorScheme.onSecondaryContainer,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
