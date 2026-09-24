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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return RoundedSurfaceCard(
      onTap: onPressed,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const _TaskPreview(),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Сегодня новое задание!', style: AppTextStyles.label),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Узнай, как зарабатывать монеты!',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: textScale >= 1.5 ? double.infinity : 150,
              child: PrimaryGradientButton(
                label: 'Посмотреть',
                height: 48,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                itemSpacing: AppSpacing.xxs,
                textStyle: AppTextStyles.buttonCompact,
                onPressed: onPressed,
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.surface,
                  size: 18,
                ),
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
