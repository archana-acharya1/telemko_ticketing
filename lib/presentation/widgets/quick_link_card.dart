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
  final Color textColor; // ✅ NEW PARAMETER
  final Color? backgroundColor; // Optional background override

  const QuickLinkCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.variant = QuickLinkCardVariant.small,
    this.width,
    this.height,
    this.textColor = Colors.black87, // default
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmall = variant == QuickLinkCardVariant.small;

    return PressScale(
      onTap: onTap,
      child: Container(
        width: width ?? (isSmall ? 120 : double.infinity),
        height: height ??
            (isSmall
                ? 140
                : 120), //For large cards
        padding: isSmall
            ? const EdgeInsets.all(AppPadding.sm)
            : const EdgeInsets.all(AppPadding.lg),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white, // keeping white as default
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isSmall
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: AppColors.primaryBlue),
            const SizedBox(height: AppPadding.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyText1.copyWith(
                  fontWeight: FontWeight.w600, color: textColor),
            ),
          ],
        )
            : Row(
          children: [
            Icon(icon, size: 40, color: AppColors.primaryBlue),
            const SizedBox(width: AppPadding.lg),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 20, color: AppColors.primaryBlue),
          ],
        ),
      ),
    );
  }
}
