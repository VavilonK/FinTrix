import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_progress_bar.dart';
import '../pet_animation/pet_animation_coordinator.dart';
import '../pet_animation/pet_animation_viewport.dart';

class PetStage extends StatelessWidget {
  const PetStage({
    required this.height,
    required this.mood,
    required this.satiety,
    required this.care,
    required this.foxAsset,
    required this.message,
    required this.animation,
    this.isActive = true,
    super.key,
  });

  final double height;
  final int mood;
  final int satiety;
  final int care;
  final String foxAsset;
  final String message;
  final PetAnimationCoordinator animation;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final foxOverflow = (constraints.maxWidth * 0.06)
              .clamp(18.0, 28.0)
              .toDouble();
          final meterWidth =
              (constraints.maxWidth * (textScale >= 1.5 ? 0.6 : 0.43))
                  .clamp(150.0, textScale >= 1.5 ? 225.0 : 175.0)
                  .toDouble();

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -foxOverflow,
                right: -foxOverflow,
                top: -32,
                bottom: -4,
                child: PetAnimationViewport(
                  coordinator: animation,
                  fallbackAsset: foxAsset,
                  isActive: isActive,
                ),
              ),
              Positioned(
                top: 0,
                right: -4,
                child: Container(
                  width: meterWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceTranslucent,
                    borderRadius: AppRadii.card,
                    boxShadow: AppShadows.card,
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                bottom: AppSpacing.sm,
                width: meterWidth,
                child: Column(
                  children: [
                    _PetStatusMeter(
                      label: 'Настроение',
                      value: mood / 100,
                      color: AppColors.green,
                      icon: Icons.sentiment_very_satisfied_rounded,
                    ),
                    const SizedBox(height: 6),
                    _PetStatusMeter(
                      label: 'Сытость',
                      value: satiety / 100,
                      color: AppColors.orange,
                      icon: Icons.restaurant_rounded,
                    ),
                    const SizedBox(height: 6),
                    _PetStatusMeter(
                      label: 'Забота',
                      value: care / 100,
                      color: AppColors.pink,
                      icon: Icons.favorite_rounded,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PetStatusMeter extends StatelessWidget {
  const _PetStatusMeter({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return SizedBox(
      height: textScale >= 1.5 ? 58 : 37 + (textScale - 1) * 28,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceTranslucent,
          borderRadius: AppRadii.capsule,
          boxShadow: AppShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(3, 2, 8, 2),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: Icon(icon, color: AppColors.surface, size: 17),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, maxLines: 1, style: AppTextStyles.caption),
                    const SizedBox(height: 2),
                    AppProgressBar(
                      value: value,
                      height: 8,
                      foregroundColor: color,
                      animationDuration: Duration.zero,
                      semanticLabel: label,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
