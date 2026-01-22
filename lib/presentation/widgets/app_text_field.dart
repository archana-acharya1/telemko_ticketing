import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData? prefixIcon;
  final int maxLines;
  final int minLines;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final bool isTextFormField;

  const AppTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.maxLines = 1,
    this.minLines = 1,
    this.validator,
    this.onSaved,
    this.isTextFormField = false, // Default to TextField
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Common decoration
    InputDecoration decoration = InputDecoration(
      labelText: labelText,
      hintText: hintText,
      floatingLabelBehavior: FloatingLabelBehavior.auto,

      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: cs.primary)
          : null,
      suffixIcon: suffixIcon,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: cs.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: cs.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      filled: true,
      fillColor: cs.surface,
      contentPadding: const EdgeInsets.symmetric(
        vertical: AppPadding.md,
        horizontal: AppPadding.lg,
      ),
      hintStyle: TextStyle(
        color: cs.onSurface.withOpacity(0.5),
        fontSize: 16,
      ),
    );

    // If it's a TextFormField (for forms with validation)
    if (isTextFormField && (validator != null || onSaved != null)) {
      return TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        maxLines: maxLines,
        minLines: minLines,
        validator: validator,
        onSaved: onSaved,
        decoration: decoration,
        style: TextStyle(
          fontSize: 16,
          color: cs.onSurface,
          fontWeight: FontWeight.normal,
        ),
      );
    }

    // Regular TextField
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLines: maxLines,
      minLines: minLines,
      decoration: decoration,
      style: TextStyle(
        fontSize: 16,
        color: cs.onSurface,
        fontWeight: FontWeight.normal,
      ),
    );
  }
}