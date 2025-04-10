import 'package:flutter/material.dart';

extension ColorExtension on Color {
  // withOpacity metodu yerine kullanılabilecek extension metodu
  Color withOpacitySafe(double opacity) {
    return withValues(
      red: red.toDouble(),
      green: green.toDouble(),
      blue: blue.toDouble(),
      alpha: opacity,
    );
  }
}
