import 'package:flutter/material.dart';
import '../../core/animation/press_scale.dart';
import '../../core/theme/app_constants.dart';

enum QuickLinkCardVariant { small, large }

class QuickLinkCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final QuickLinkCardVariant variant;
  final double? width;
  final double? height;
  final Color textColor;
  final Color? backgroundColor;

  const QuickLinkCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.variant = QuickLinkCardVariant.small,
    this.width,
    this.height,
    this.textColor = Colors.black87,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bool isSmall = variant == QuickLinkCardVariant.small;

    return PressScale(
      onTap: onTap,
      child: Container(
        width: width ?? (isSmall ? 120 : double.infinity),
        height: height ?? (isSmall ? 140 : 120),
        padding: isSmall
            ? const EdgeInsets.all(AppPadding.sm)
            : const EdgeInsets.all(AppPadding.lg),
        decoration: BoxDecoration(
          color: backgroundColor ?? cs.surface, // Theme-aware background
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: cs.primary.withOpacity(0.3), // Theme-aware border
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
            Icon(
              icon,
              size: 36,
              color: cs.primary, // Theme-aware icon color
            ),
            const SizedBox(height: AppPadding.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle( // Fixed: Use TextStyle instead of AppTextStyles
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor, // Use passed textColor parameter
              ),
            ),
          ],
        )
            : Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: cs.primary, // Theme-aware icon color
            ),
            const SizedBox(width: AppPadding.lg),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle( // Fixed: Use TextStyle instead of AppTextStyles
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor, // Use passed textColor parameter
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: cs.primary, // Theme-aware icon color
            ),
          ],
        ),
      ),
    );
  }
}