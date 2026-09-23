import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import 'widgets/onboarding_frame.dart';

class ParentWelcomeScreen extends StatelessWidget {
  const ParentWelcomeScreen({required this.onContinue, super.key});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return OnboardingFrame(
      icon: Icons.family_restroom_rounded,
      title: 'Добро пожаловать!',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Сначала настроим приложение вместе со взрослым.',
            textAlign: TextAlign.center,
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Здесь ребёнок будет учиться распоряжаться игровыми монетами, '
            'планировать бюджет и копить на цели.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          const RoundedSurfaceCard(
            backgroundColor: AppColors.surface,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline_rounded, color: AppColors.primaryBlue),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Данные профиля и игровой прогресс хранятся локально '
                    'на устройстве. Родитель сможет изменить данные ребёнка '
                    'или удалить профиль.',
                    style: AppTextStyles.bodySecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryGradientButton(
            key: const ValueKey('onboarding_welcome_continue'),
            label: 'Начать настройку',
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
