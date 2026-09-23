import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../../../../core/widgets/rounded_surface_card.dart';

class HomeTaskCard extends StatelessWidget {
  const HomeTaskCard({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return RoundedSurfaceCard(
      onTap: onPressed,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          const _TaskPreview(),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сегодня новое задание!',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 15,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Узнай, как зарабатывать монеты и становиться финансово умнее!',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10.5,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 104,
            child: PrimaryGradientButton(
              label: 'Посмотреть',
              height: 48,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: AppSpacing.xs,
              ),
              itemSpacing: AppSpacing.xxs,
              textStyle: AppTextStyles.body.copyWith(
                color: AppColors.surface,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
              onPressed: onPressed,
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.surface,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskPreview extends StatelessWidget {
  const _TaskPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 78,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.primaryBlueLight,
        borderRadius: AppRadii.mediumBorder,
      ),
      child: Image.asset(AppAssets.homeTaskPreviewMap, fit: BoxFit.cover),
    );
  }
}
