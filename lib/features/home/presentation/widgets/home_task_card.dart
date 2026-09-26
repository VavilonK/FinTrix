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
    final action = PrimaryGradientButton(
      label: 'Посмотреть',
      height: 48,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      itemSpacing: 0,
      textStyle: AppTextStyles.buttonCompact.copyWith(fontSize: 13.5),
      onPressed: onPressed,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.surface,
        size: 18,
      ),
    );
    final description = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Сегодня новое задание!',
            maxLines: 1,
            style: AppTextStyles.label.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Узнай, как зарабатывать монеты и становиться финансово умнее!',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption,
        ),
      ],
    );
    return RoundedSurfaceCard(
      onTap: onPressed,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: textScale <= 1.2
          ? Row(
              children: [
                const SizedBox(width: 62, height: 60, child: _TaskPreview()),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: description),
                const SizedBox(width: AppSpacing.xs),
                SizedBox(width: 118, child: action),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const _TaskPreview(),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: description),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: textScale >= 1.5 ? double.infinity : 150,
                    child: action,
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
