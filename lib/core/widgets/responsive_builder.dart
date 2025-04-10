import 'package:flutter/material.dart';

// Ekran boyutları
enum DeviceScreenType { mobile, tablet, desktop }

// Farklı ekran boyutları için varsayılan genişlik sınırları
class ScreenBreakpoints {
  static const double tabletSmall = 600;
  static const double tabletLarge = 900;
  static const double desktopSmall = 1200;
  static const double desktopLarge = 1440;
}

// Ekran boyutunu tespit et
DeviceScreenType getDeviceScreenType(BuildContext context) {
  final width = MediaQuery.of(context).size.width;

  if (width >= ScreenBreakpoints.tabletLarge) {
    return DeviceScreenType.desktop;
  }

  if (width >= ScreenBreakpoints.tabletSmall) {
    return DeviceScreenType.tablet;
  }

  return DeviceScreenType.mobile;
}

// Responsive yapı için widget builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    DeviceScreenType deviceScreenType,
    Widget? child,
  )
  builder;
  final Widget? child;

  const ResponsiveBuilder({super.key, required this.builder, this.child});

  @override
  Widget build(BuildContext context) {
    return builder(context, getDeviceScreenType(context), child);
  }
}

// Kolaylaştırıcı extension
extension ResponsiveExtension on BuildContext {
  DeviceScreenType get deviceScreenType => getDeviceScreenType(this);

  bool get isMobile => deviceScreenType == DeviceScreenType.mobile;
  bool get isTablet => deviceScreenType == DeviceScreenType.tablet;
  bool get isDesktop => deviceScreenType == DeviceScreenType.desktop;

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // Ekrana oranla genişlik hesapla
  double widthPercent(double percent) => screenWidth * percent;

  // Ekrana oranla yükseklik hesapla
  double heightPercent(double percent) => screenHeight * percent;
}

// Farklı ekran boyutları için özel widget
class ScreenTypeLayout extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ScreenTypeLayout({super.key, this.mobile, this.tablet, this.desktop});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceScreenType, child) {
        switch (deviceScreenType) {
          case DeviceScreenType.desktop:
            return desktop ?? (tablet ?? mobile ?? Container());
          case DeviceScreenType.tablet:
            return tablet ?? (mobile ?? Container());
          case DeviceScreenType.mobile:
            return mobile ?? Container();
        }
      },
    );
  }
}
