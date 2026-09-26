import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/rounded_surface_card.dart';
import '../../../../core/widgets/speech_bubble.dart';

class TasksHeroBanner extends StatelessWidget {
  const TasksHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final showBubble =
        MediaQuery.sizeOf(context).width >= 380 && textScale < 1.3;
    return RoundedSurfaceCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        0,
        AppSpacing.xs,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Row(
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
                    padding: EdgeInsets.only(right: showBubble ? 158 : 86),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Задание дня',
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Исследуй Москву и узнавай больше о деньгах!',
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showBubble)
            const Positioned(
              right: 52,
              top: 2,
              width: 126,
              child: SpeechBubble(
                text: 'Маленькие шаги к большим мечтам!',
                tail: SpeechBubbleTail.right,
                tilt: -5,
                padding: EdgeInsets.fromLTRB(8, 6, 6, 7),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 10.5,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          Positioned(
            right: -3,
            bottom: -14,
            child: Image.asset(
              AppAssets.foxPeekingHappyLevel05,
              width: 90,
              height: 90,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ],
      ),
    );
  }
}
