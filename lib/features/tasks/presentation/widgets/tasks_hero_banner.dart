import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/rounded_surface_card.dart';

class TasksHeroBanner extends StatelessWidget {
  const TasksHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: RoundedSurfaceCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          0,
          AppSpacing.xs,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlueLight,
                    borderRadius: AppRadii.mediumBorder,
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_rounded,
                    color: AppColors.primaryBlue,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 150),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Задание дня',
                          style: AppTextStyles.cardTitle.copyWith(fontSize: 19),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Исследуй Москву и узнавай больше о деньгах!',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10.5,
                            height: 1.18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 54,
              top: -1,
              child: Container(
                width: 82,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.capsule,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Text(
                  'Маленькие шаги\nк большим мечтам!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 8.2,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -3,
              bottom: -14,
              child: Image.asset(
                AppAssets.foxPeekingHappyLevel05,
                width: 86,
                height: 86,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
