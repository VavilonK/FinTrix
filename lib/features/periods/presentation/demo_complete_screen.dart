import 'package:flutter/material.dart';

import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../pet_progression/domain/pet_progression.dart';
import '../../pet_progression/presentation/pet_visual_resolver.dart';

class DemoCompleteScreen extends StatelessWidget {
  const DemoCompleteScreen({required this.onReturnHome, super.key});

  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final demoPeriods = state.completedGamePeriods
        .where((period) => period.isDemoPeriod)
        .toList();
    final startProgress = demoPeriods.isEmpty
        ? state.goalProgress
        : demoPeriods.first.goalProgressAtStart;
    final startStage = demoPeriods.isEmpty
        ? state.petGrowthStage
        : demoPeriods.first.petStageAtStart;
    final endStage = demoPeriods.isEmpty
        ? state.petGrowthStage
        : demoPeriods.last.petStageAtEnd;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Image.asset(
                    PetVisualResolver.assetFor(
                      stage: endStage,
                      emotionalState: PetEmotionalState.celebrating,
                      context: PetVisualContext.demoComplete,
                    ),
                    width: 200,
                    height: 190,
                    fit: BoxFit.contain,
                  ),
                  Text(
                    '5 дней вместе с Рыжиком!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RoundedSurfaceCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        _ResultRow('Выполнено заданий', state.demoTotalTasks),
                        _ResultRow('Заработано', state.demoTotalEarned),
                        _ResultRow(
                          'Потрачено на важное',
                          state.demoTotalEssentialSpent,
                        ),
                        _ResultRow(
                          'Потрачено на приятное',
                          state.demoTotalWantSpent,
                        ),
                        _ResultRow('Отложено', state.demoTotalDeposited),
                        _ResultRow(
                          'Рыжик',
                          '${startStage.shortTitle} → ${endStage.shortTitle}',
                        ),
                        _ResultRow(
                          'Очков развития получено',
                          state.demoTotalGrowthPoints,
                        ),
                        const Divider(height: AppSpacing.lg),
                        _ResultRow(
                          state.selectedGoal.title,
                          '${(startProgress * 100).round()}% → '
                          '${(state.goalProgress * 100).round()}%',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryGradientButton(
                    key: const ValueKey('demo_exit'),
                    label: 'Вернуться в обычный режим',
                    onPressed: () async {
                      final restored = await state.exitDemoMode();
                      if (!context.mounted || !restored) return;
                      onReturnHome();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton.icon(
                    key: const ValueKey('demo_restart'),
                    onPressed: () async {
                      await state.resetDemoMode();
                      if (!context.mounted) return;
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Начать демо заново'),
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

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.label, this.value);
  final String label;
  final Object value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySecondary)),
          Text(
            '$value',
            style: AppTextStyles.cardTitle.copyWith(color: AppColors.navy),
          ),
        ],
      ),
    );
  }
}
