// Özelleştirilmiş buton bileşeni

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../constants/app_constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.borderRadius = 12.0,
    this.padding,
    this.width,
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppConstants.accentColor,
          foregroundColor: textColor ?? Colors.white,
          padding:
              padding ??
              const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          disabledBackgroundColor: AppConstants.accentColor.withAlpha(128),
        ),
        child:
            isLoading
                ? SpinKitFadingCircle(
                  color: textColor ?? Colors.white,
                  size: 24.0,
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
