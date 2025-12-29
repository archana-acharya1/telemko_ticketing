import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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
    this.color = AppColors.primaryBlue,
    this.width, //  Custom width
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final childWidget = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed == null ? Colors.grey : color,
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
        style: AppTextStyles.buttonText,
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