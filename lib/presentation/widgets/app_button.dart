import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final double? width;
  final bool expanded;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color = Colors.blue, // Default color, will be overridden
    this.width,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color == Colors.blue
        ? theme.colorScheme.primary
        : color;

    final childWidget = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed == null
            ? theme.colorScheme.surfaceVariant
            : buttonColor,
        foregroundColor: onPressed == null
            ? theme.colorScheme.onSurface.withOpacity(0.5)
            : theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          vertical: AppPadding.md,
          horizontal: AppPadding.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: onPressed == null
              ? theme.colorScheme.onSurface.withOpacity(0.5)
              : theme.colorScheme.onPrimary,
        ),
      ),
    );

    if (width != null) {
      return SizedBox(
        width: width,
        child: childWidget,
      );
    }

    if (expanded) {
      return SizedBox(
        width: double.infinity,
        child: childWidget,
      );
    }

    return childWidget;
  }
}