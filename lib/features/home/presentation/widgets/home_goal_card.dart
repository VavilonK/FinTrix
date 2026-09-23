import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_progress_bar.dart';
import '../../../../core/widgets/rounded_surface_card.dart';
import '../../../goals/domain/savings_goal.dart';

class HomeGoalCard extends StatelessWidget {
  const HomeGoalCard({
    required this.savings,
    required this.goal,
    required this.onTap,
    this.completed = false,
    super.key,
  });

  final int savings;
  final SavingsGoal goal;
  final VoidCallback onTap;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return RoundedSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageSize = (constraints.maxWidth * 0.21)
              .clamp(70.0, 80.0)
              .toDouble();

          return Row(
            children: [
              Container(
                width: imageSize,
                height: 64,
                padding: const EdgeInsets.all(AppSpacing.xxs),
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlueLight,
                  borderRadius: AppRadii.mediumBorder,
                ),
                child: goal.assetPath != null
                    ? Image.asset(goal.assetPath!, fit: BoxFit.contain)
                    : Icon(
                        goal.id == 'scooter'
                            ? Icons.electric_scooter_rounded
                            : Icons.extension_rounded,
                        color: goal.id == 'scooter'
                            ? AppColors.purple
                            : AppColors.primaryBlue,
                        size: 42,
                      ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        completed ? 'Выбери новую цель' : goal.title,
                        maxLines: 1,
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 17),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    if (completed)
                      Text(
                        'Предыдущая мечта достигнута!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySecondary,
                      )
                    else
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: _formatCoins(savings),
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: ' / ${_formatCoins(goal.price)} монет',
                              style: AppTextStyles.bodySecondary,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (!completed) ...[
                      const SizedBox(height: 6),
                      AppProgressBar(
                        value: goal.price <= 0
                            ? 0
                            : (savings / goal.price).clamp(0, 1).toDouble(),
                        height: 10,
                        foregroundColor: AppColors.green,
                        semanticLabel: 'Прогресс цели ${goal.title}',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Material(
                color: AppColors.backgroundLavender,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: const SizedBox.square(
                    dimension: 44,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.secondaryText,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _formatCoins(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
}
