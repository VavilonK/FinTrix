import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../domain/budget_plan.dart';

/// Plan against fact for one game period (ТЗ 2.5.5, 2.5.9): every direction
/// with its planned and real amounts, a status in words and an icon (never
/// colour alone), and one sentence with the next step.
class PlanFactCard extends StatelessWidget {
  const PlanFactCard({
    required this.plan,
    required this.planConfirmed,
    required this.essentialSpent,
    required this.wantSpent,
    required this.saved,
    super.key,
  });

  final BudgetPlan plan;
  final bool planConfirmed;
  final int essentialSpent;
  final int wantSpent;
  final int saved;

  /// The advice shown under the table; public for tests and other screens.
  static String adviceFor({
    required BudgetPlan plan,
    required bool planConfirmed,
    required int essentialSpent,
    required int wantSpent,
    required int saved,
  }) {
    if (!planConfirmed) {
      return 'Бюджет не был подтверждён. В начале следующего дня распредели '
          'монеты и нажми «Подтвердить бюджет».';
    }
    if (wantSpent > plan.wantsPlanned) {
      return 'На приятное ушло больше плана на '
          '${wantSpent - plan.wantsPlanned}. В следующий раз приятную покупку '
          'можно отложить на потом.';
    }
    if (essentialSpent > plan.essentialsPlanned) {
      return 'На важное понадобилось больше, чем планировали. В следующем '
          'бюджете выдели на важное побольше.';
    }
    if (saved < plan.savingsPlanned) {
      return 'В копилку попало меньше плана на ${plan.savingsPlanned - saved}. '
          'Попробуй отложить монеты в начале дня.';
    }
    return 'Ты уложился в план! Так держать.';
  }

  @override
  Widget build(BuildContext context) {
    final advice = adviceFor(
      plan: plan,
      planConfirmed: planConfirmed,
      essentialSpent: essentialSpent,
      wantSpent: wantSpent,
      saved: saved,
    );
    return RoundedSurfaceCard(
      key: const ValueKey('plan_fact_card'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'План и факт',
            style: AppTextStyles.cardTitle.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Expanded(child: SizedBox()),
              SizedBox(
                width: 64,
                child: Text(
                  'План',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.caption,
                ),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  'Факт',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          _Row(
            label: 'На важное',
            planned: plan.essentialsPlanned,
            actual: essentialSpent,
            spending: true,
          ),
          _Row(
            label: 'На приятное',
            planned: plan.wantsPlanned,
            actual: wantSpent,
            spending: true,
          ),
          _Row(
            label: 'В копилку',
            planned: plan.savingsPlanned,
            actual: saved,
            spending: false,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            advice,
            key: const ValueKey('plan_fact_advice'),
            style: AppTextStyles.body.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.planned,
    required this.actual,
    required this.spending,
  });

  final String label;
  final int planned;
  final int actual;

  /// Spending should stay within the plan; savings should reach it.
  final bool spending;

  @override
  Widget build(BuildContext context) {
    final ok = spending ? actual <= planned : actual >= planned;
    final status = spending
        ? (actual <= planned ? 'в плане' : 'больше на ${actual - planned}')
        : (actual >= planned
              ? 'план выполнен'
              : 'меньше на ${planned - actual}');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.info_rounded,
            size: 20,
            color: ok ? AppColors.green : AppColors.orange,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.body),
                Text(
                  status,
                  style: AppTextStyles.caption.copyWith(
                    color: ok ? AppColors.green : AppColors.orange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '$planned',
              textAlign: TextAlign.end,
              style: AppTextStyles.body,
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '$actual',
              textAlign: TextAlign.end,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
