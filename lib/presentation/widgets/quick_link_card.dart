import 'package:flutter/material.dart';
import '../../core/animation/press_scale.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_constants.dart';

enum QuickLinkCardVariant { small, large }

class QuickLinkCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final QuickLinkCardVariant variant;
  final double? width;
  final double? height;

  const QuickLinkCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.variant = QuickLinkCardVariant.small,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        width: width ?? (variant == QuickLinkCardVariant.small ? 120 : double.infinity),
        height: height ?? (variant == QuickLinkCardVariant.small ? 130 : 80),
        padding: variant == QuickLinkCardVariant.small
            ? const EdgeInsets.all(AppPadding.sm)
            : const EdgeInsets.all(AppPadding.lg),
        decoration: BoxDecoration(
          color: Colors.red.shade100, // soft pink
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.primaryRed.withOpacity(0.7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: variant == QuickLinkCardVariant.small
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: AppColors.primaryRed),
            const SizedBox(height: AppPadding.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText1.copyWith(
                  fontWeight: FontWeight.w600, color: AppColors.primaryRed),
            ),
          ],
        )
            : Row(
          children: [
            Icon(icon, size: 40, color: AppColors.primaryRed),
            const SizedBox(width: AppPadding.lg),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.subtitle1
                    .copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryRed),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 20, color: AppColors.primaryRed),
          ],
        ),
      ),
    );
  }
}
