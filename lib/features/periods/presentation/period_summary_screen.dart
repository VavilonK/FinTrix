import 'package:flutter/material.dart';

import '../../budget/presentation/plan_fact_card.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../data/demo_period_definitions.dart';
import '../domain/game_period.dart';
import '../../pet_progression/domain/pet_progression.dart';
import '../../pet_progression/presentation/pet_visual_resolver.dart';
import 'demo_complete_screen.dart';

class PeriodSummaryScreen extends StatelessWidget {
  const PeriodSummaryScreen({required this.onReturnHome, super.key});

  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final period = state.activeGamePeriod;
    if (period == null) {
      return const Scaffold(body: Center(child: Text('Итоги недоступны')));
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF4FF), Color(0xFFFFF3E9)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: Column(
                          children: [
                            if (state.isDemoMode)
                              _DemoBadge(day: state.demoPeriodIndex),
                            Image.asset(
                              PetVisualResolver.assetFor(
                                stage: period.petStageAtEnd,
                                emotionalState: PetEmotionalState.celebrating,
                                context: PetVisualContext.periodSummary,
                              ),
                              width: 170,
                              height: 155,
                              fit: BoxFit.contain,
                            ),
                            Text(
                              'День завершён!',
                              style: AppTextStyles.heading,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Отличный день! Посмотрим, что будет дальше?',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySecondary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _GrowthSummaryCard(period: period),
                            const SizedBox(height: AppSpacing.md),
                            PlanFactCard(
                              plan: period.budgetPlanSnapshot,
                              planConfirmed: period.budgetWasConfirmed,
                              essentialSpent: period.essentialSpent,
                              wantSpent: period.wantSpent,
                              saved: period.intentionalSavingsDeposited,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            RoundedSurfaceCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                children: [
                                  _MoneyRow(
                                    label: 'Заработано',
                                    value: '+${period.earnedCoins}',
                                    color: AppColors.green,
                                  ),
                                  _MoneyRow(
                                    label: 'На важное',
                                    value: '-${period.essentialSpent}',
                                    color: AppColors.orange,
                                  ),
                                  _MoneyRow(
                                    label: 'На приятное',
                                    value: '-${period.wantSpent}',
                                    color: AppColors.pink,
                                  ),
                                  _MoneyRow(
                                    label: 'В копилку',
                                    value: '+${period.depositedToSavings}',
                                    color: AppColors.purple,
                                  ),
                                  const Divider(height: AppSpacing.lg),
                                  _ChangeRow(
                                    label: 'Баланс',
                                    before: period.startingBalance,
                                    after: period.endingBalance,
                                  ),
                                  _ChangeRow(
                                    label: 'Копилка',
                                    before: period.startingSavings,
                                    after: period.endingSavings,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      state.selectedGoal.title,
                                      style: AppTextStyles.cardTitle,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  AppProgressBar(
                                    value: period.goalProgressAtEnd,
                                    height: 12,
                                    foregroundColor: AppColors.green,
                                    semanticLabel: 'Прогресс финансовой цели',
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${_percent(period.goalProgressAtStart)}% → '
                                      '${_percent(period.goalProgressAtEnd)}%',
                                      style: AppTextStyles.caption,
                                    ),
                                  ),
                                  const Divider(height: AppSpacing.lg),
                                  _InfoRow(
                                    label: 'Задания',
                                    value:
                                        '${period.completedTaskCount} из ${state.activeMission?.tasks.length ?? period.completedTaskCount}',
                                  ),
                                  _InfoRow(
                                    label: 'Правильно',
                                    value: '${period.correctTaskCount}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    PrimaryGradientButton(
                      key: ValueKey(
                        state.isDemoMode
                            ? 'period_summary_continue'
                            : 'mission_return_home',
                      ),
                      label: _buttonLabel(state),
                      onPressed: () => _continue(context, state),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.surface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buttonLabel(AppController state) {
    if (!state.isDemoMode) return 'Готово';
    return state.demoPeriodIndex < DemoPeriodDefinitions.count
        ? 'Следующий день'
        : 'Демо завершено';
  }

  Future<void> _continue(BuildContext context, AppController state) async {
    if (!state.isDemoMode) {
      state.finishMission();
      onReturnHome();
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (state.demoPeriodIndex < DemoPeriodDefinitions.count) {
      await state.startNextDemoPeriod();
      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => DemoCompleteScreen(onReturnHome: onReturnHome),
      ),
    );
  }
}

class _GrowthSummaryCard extends StatelessWidget {
  const _GrowthSummaryCard({required this.period});

  final GamePeriod period;

  @override
  Widget build(BuildContext context) {
    final changedStage = period.petStageAtStart != period.petStageAtEnd;
    final isGrown = period.petStageAtEnd == PetGrowthStage.grown;
    final threshold = PetProgressionConfig.nextStageThreshold(
      period.petGrowthPointsAtEnd,
    );
    final name = AppScope.of(context).petName;
    final title = changedStage
        ? isGrown
              ? '$name стал ещё взрослее!'
              : '$name подрос!'
        : '$name становится опытнее!';

    return RoundedSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlueLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Развитие питомца', style: AppTextStyles.cardTitle),
                    Text(title, style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),
              Text(
                '+${period.growthPointsAwarded}',
                style: AppTextStyles.cardTitle.copyWith(
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
          if (changedStage) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Ты помог ему стать взрослее, принимая финансовые решения.',
              style: AppTextStyles.bodySecondary,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppProgressBar(
            value: PetProgressionConfig.progressToNextStage(
              period.petGrowthPointsAtEnd,
            ),
            gradient: AppGradients.primaryCta,
            semanticLabel: 'Очки развития Рыжика',
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${period.petStageAtEnd.title} • очки развития',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                isGrown
                    ? 'Максимальная стадия'
                    : '${period.petGrowthPointsAtEnd} / $threshold',
                style: AppTextStyles.caption.copyWith(color: AppColors.navy),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge({required this.day});
  final int day;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.purple,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'Демо • День $day из ${DemoPeriodDefinitions.count}',
        style: AppTextStyles.caption.copyWith(color: Colors.white),
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySecondary)),
          Text(value, style: AppTextStyles.cardTitle.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.label,
    required this.before,
    required this.after,
  });
  final String label;
  final int before;
  final int after;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Text('$before → $after', style: AppTextStyles.cardTitle),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySecondary)),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

int _percent(double value) => (value * 100).round();
