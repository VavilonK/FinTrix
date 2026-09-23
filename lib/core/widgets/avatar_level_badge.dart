import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AvatarLevelBadge extends StatelessWidget {
  const AvatarLevelBadge({
    required this.avatar,
    required this.levelLabel,
    this.size = 64,
    this.compact = false,
    super.key,
  });

  final Widget avatar;
  final String levelLabel;
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size.clamp(52, 76).toDouble();

    return Semantics(
      image: true,
      label: levelLabel,
      child: SizedBox(
        width: effectiveSize,
        height: effectiveSize + (compact ? AppSpacing.sm : AppSpacing.md),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: effectiveSize,
              height: effectiveSize,
              padding: const EdgeInsets.all(AppSpacing.xxs),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: AppShadows.card,
              ),
              child: ClipOval(child: avatar),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                constraints: BoxConstraints(minHeight: compact ? 24 : 28),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 6 : AppSpacing.xs,
                  vertical: compact ? 2 : AppSpacing.xxs,
                ),
                decoration: const BoxDecoration(
                  gradient: AppGradients.levelBadge,
                  borderRadius: AppRadii.capsule,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    levelLabel,
                    maxLines: 1,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 14 : 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
