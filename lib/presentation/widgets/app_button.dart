import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_constants.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = AppColors.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
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
  }
}
