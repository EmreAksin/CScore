// Özelleştirilmiş metin girişi bileşeni

import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(
          prefixIcon,
          color: AppConstants.accentColor.withAlpha(179),
        ),
        filled: true,
        fillColor: isDarkMode ? AppConstants.cardColor : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withAlpha(51), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppConstants.accentColor.withAlpha(128),
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2.0),
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      style: TextStyle(
        color:
            isDarkMode ? AppConstants.textColorPrimary : Colors.grey.shade900,
      ),
    );
  }
}
