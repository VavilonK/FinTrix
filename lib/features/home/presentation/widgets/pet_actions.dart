import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class PetActions extends StatelessWidget {
  const PetActions({
    required this.onFeed,
    required this.onPlay,
    required this.onPet,
    super.key,
  });

  final VoidCallback onFeed;
  final VoidCallback onPlay;
  final VoidCallback onPet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: _PetActionButton(
              key: const ValueKey('home_feed_pet'),
              label: 'Покормить',
              color: AppColors.orange,
              assetPath: AppAssets.careFoodBowl,
              onTap: onFeed,
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _PetActionButton(
              key: const ValueKey('home_play_pet'),
              label: 'Поиграть',
              color: AppColors.purple,
              assetPath: AppAssets.itemGameController,
              onTap: onPlay,
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _PetActionButton(
              key: const ValueKey('home_pet_fox'),
              label: 'Погладить',
              color: AppColors.pink,
              assetPath: AppAssets.actionPetting,
              onTap: onPet,
            ),
          ),
        ],
      ),
    );
  }
}

class _PetActionButton extends StatelessWidget {
  const _PetActionButton({
    required this.label,
    required this.color,
    this.assetPath,
    this.icon,
    required this.onTap,
    super.key,
  }) : assert(assetPath != null || icon != null);

  final String label;
  final Color color;
  final String? assetPath;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = Color.lerp(color, AppColors.surface, 0.18)!;

    return Semantics(
      button: true,
      label: label,
      child: Container(
        height: 86,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [highlight, color],
          ),
          borderRadius: AppRadii.actionButton,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(72),
              offset: const Offset(0, 7),
              blurRadius: 16,
            ),
          ],
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: AppRadii.actionButton,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.actionButton,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (assetPath != null)
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.asset(assetPath!, fit: BoxFit.contain),
                    )
                  else
                    SizedBox.square(
                      dimension: 56,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Icon(icon, color: AppColors.surface, size: 52),
                      ),
                    ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: AppTextStyles.button.copyWith(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
