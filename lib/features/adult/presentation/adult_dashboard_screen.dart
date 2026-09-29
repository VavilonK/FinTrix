import 'package:flutter/material.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../domain/parent_access_service.dart';
import '../../periods/domain/game_period.dart';
import '../../pet_progression/domain/pet_progression.dart';
import '../../finance/domain/financial_transaction.dart';
import '../../finance/presentation/financial_history_screen.dart';
import '../../tasks/data/location_definitions.dart';
import 'widgets/period_details_sheet.dart';
import 'widgets/edit_child_profile_sheet.dart';

class AdultDashboardScreen extends StatelessWidget {
  const AdultDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final periods = state.completedGamePeriods
        .where((period) => period.isDemoPeriod == state.isDemoMode)
        .toList(growable: false);
    final lastPeriod = periods.isEmpty ? null : periods.last;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Для родителей'),
            Text(
              'Прогресс ребёнка',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (state.isDemoMode) const _DemoProfileBanner(),
                _ChildCard(state: state, completedPeriods: periods.length),
                const SizedBox(height: AppSpacing.sm),
                _ChildProfileManagementCard(state: state),
                const SizedBox(height: AppSpacing.sm),
                _GoalCard(state: state),
                const SizedBox(height: AppSpacing.sm),
                _CompletedGoalsCard(state: state),
                const SizedBox(height: AppSpacing.sm),
                _FinancialSummaryCard(state: state),
                const SizedBox(height: AppSpacing.sm),
                _RecentTransactionsCard(state: state),
                const SizedBox(height: AppSpacing.sm),
                _LastPeriodCard(period: lastPeriod),
                const SizedBox(height: AppSpacing.sm),
                _PeriodHistoryCard(periods: periods),
                const SizedBox(height: AppSpacing.sm),
                _LearningProgressCard(state: state, periods: periods),
                const SizedBox(height: AppSpacing.sm),
                _PetProgressionCard(state: state, lastPeriod: lastPeriod),
                const SizedBox(height: AppSpacing.sm),
                const _AppGoalsCard(),
                const SizedBox(height: AppSpacing.sm),
                _ParentRewardCard(state: state),
                const SizedBox(height: AppSpacing.sm),
                _ParentAccessCard(state: state),
                const SizedBox(height: AppSpacing.sm),
                _DataActionsCard(state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChildProfileManagementCard extends StatelessWidget {
  const _ChildProfileManagementCard({required this.state});

  final AppController state;

  @override
  Widget build(BuildContext context) {
    return _AdultCard(
      title: 'Данные ребёнка',
      child: Column(
        children: [
          _ActionTile(
            key: const ValueKey('adult_edit_child_name'),
            icon: Icons.person_outline_rounded,
            label: 'Имя — ${state.childName}',
            onTap: () => showEditChildProfileSheet(
              context: context,
              state: state,
              focusName: true,
            ),
          ),
          _ActionTile(
            key: const ValueKey('adult_edit_child_age'),
            icon: Icons.cake_outlined,
            label: 'Возраст — ${state.age} лет',
            onTap: () =>
                showEditChildProfileSheet(context: context, state: state),
          ),
          _ActionTile(
            key: const ValueKey('adult_edit_pet_name'),
            icon: Icons.pets_rounded,
            label: 'Питомец — ${state.petName}',
            onTap: () =>
                showEditChildProfileSheet(context: context, state: state),
          ),
        ],
      ),
    );
  }
}

class _DemoProfileBanner extends StatelessWidget {
  const _DemoProfileBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFEDE5FF),
        borderRadius: AppRadii.mediumBorder,
      ),
      child: const Row(
        children: [
          Icon(Icons.science_rounded, color: AppColors.purple),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text('Демонстрационный профиль', style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.state, required this.completedPeriods});

  final AppController state;
  final int completedPeriods;

  @override
  Widget build(BuildContext context) {
    return _AdultCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryBlueLight,
            child: Icon(
              Icons.person_rounded,
              size: 34,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.childName, style: AppTextStyles.cardTitle),
                Text('${state.age} лет', style: AppTextStyles.bodySecondary),
                const SizedBox(height: 3),
                Text(
                  'Вместе с Рыжиком: $completedPeriods ${_daysWord(completedPeriods)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.state});

  final AppController state;

  @override
  Widget build(BuildContext context) {
    return _AdultCard(
      title: 'Текущая цель',
      child: state.isSelectedGoalCompleted
          ? Text(
              'Новая цель пока не выбрана.',
              style: AppTextStyles.bodySecondary,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.selectedGoal.title, style: AppTextStyles.cardTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_coins(state.savings)} / ${_coins(state.goalPrice)} монет',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.xs),
                AppProgressBar(
                  value: state.goalProgress,
                  height: 12,
                  foregroundColor: AppColors.green,
                  semanticLabel: 'Прогресс текущей финансовой цели',
                ),
                const SizedBox(height: 5),
                Text(
                  'Осталось: ${_coins(state.goalRemaining)}',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
    );
  }
}

class _CompletedGoalsCard extends StatelessWidget {
  const _CompletedGoalsCard({required this.state});

  final AppController state;

  @override
  Widget build(BuildContext context) {
    final completed = state.goals
        .where((goal) => state.completedGoalIds.contains(goal.id))
        .toList(growable: false);
    return _AdultCard(
      title: 'Достигнутые цели',
      child: completed.isEmpty
          ? Text(
              'Пока нет завершённых целей.',
              style: AppTextStyles.bodySecondary,
            )
          : Column(
              children: [
                for (final goal in completed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.green,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            _completedGoalTitle(goal.title),
                            style: AppTextStyles.body,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  const _FinancialSummaryCard({required this.state});

  final AppController state;

  @override
  Widget build(BuildContext context) {
    return _AdultCard(
      title: 'Финансовая сводка',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Сейчас', style: AppTextStyles.bodySecondary),
          _ValueRow(label: 'Баланс', value: _coins(state.balance)),
          _ValueRow(label: 'Накопления', value: _coins(state.savings)),
          const Divider(height: AppSpacing.lg),
          Text('План текущего периода', style: AppTextStyles.body),
          if (!state.budgetPlanConfirmed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Бюджет пока не подтверждён',
                style: AppTextStyles.caption,
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          _BudgetFactRow(
            label: 'На важное',
            actual: state.budgetUsage.essentialsSpent,
            planned: state.budgetPlan.essentialsPlanned,
            confirmed: state.budgetPlanConfirmed,
          ),
          _BudgetFactRow(
            label: 'На приятное',
            actual: state.budgetUsage.wantsSpent,
            planned: state.budgetPlan.wantsPlanned,
            confirmed: state.budgetPlanConfirmed,
          ),
          _BudgetFactRow(
            label: 'На мечту',
            actual: state.budgetUsage.savingsDeposited,
            planned: state.budgetPlan.savingsPlanned,
            confirmed: state.budgetPlanConfirmed,
          ),
        ],
      ),
    );
  }
}

class _LastPeriodCard extends StatelessWidget {
  const _LastPeriodCard({required this.period});

  final GamePeriod? period;

  @override
  Widget build(BuildContext context) {
    final value = period;
    return _AdultCard(
      title: 'Последний игровой день',
      child: value == null
          ? Text(
              'Завершённых игровых дней пока нет.',
              style: AppTextStyles.bodySecondary,
            )
          : Column(
              children: [
                _ValueRow(
                  label: 'Заработано',
                  value: '+${_coins(value.earnedCoins)}',
                ),
                _ValueRow(
                  label: 'На важное',
                  value: _coins(value.essentialSpent),
                ),
                _ValueRow(label: 'На приятное', value: _coins(value.wantSpent)),
                _ValueRow(
                  label: 'Отложено',
                  value: _coins(value.depositedToSavings),
                ),
                const Divider(height: AppSpacing.lg),
                _ValueRow(
                  label: 'Заданий',
                  value: '${value.completedTaskCount}',
                ),
                _ValueRow(
                  label: 'Правильно',
                  value: '${value.correctTaskCount}',
                ),
              ],
            ),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard({required this.state});

  final AppController state;

  @override
  Widget build(BuildContext context) {
    return _AdultCard(
      title: 'Последние операции',
      child: FutureBuilder<List<FinancialTransaction>>(
        future: state.recentFinancialTransactions(limit: 5),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final transactions = snapshot.data!;
          return Column(
            children: [
              if (transactions.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Операций пока нет.',
                    style: AppTextStyles.bodySecondary,
                  ),
                )
              else
                for (var index = 0; index < transactions.length; index++) ...[
                  FinancialTransactionTile(
                    transaction: transactions[index],
                    showBalances: true,
                  ),
                  if (index != transactions.length - 1)
                    const Divider(height: 1, color: AppColors.borderLight),
                ],
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const ValueKey('adult_open_financial_history'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const FinancialHistoryScreen(adultView: true),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Вся история'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PeriodHistoryCard extends StatelessWidget {
  const _PeriodHistoryCard({required this.periods});

  final List<GamePeriod> periods;

  @override
  Widget build(BuildContext context) {
    final recent = periods.reversed.take(5).toList(growable: false);
    return _AdultCard(
      title: 'Последние игровые дни',
      child: recent.isEmpty
          ? Text('История пока пуста.', style: AppTextStyles.bodySecondary)
          : Column(
              children: [
                for (var index = 0; index < recent.length; index++) ...[
                  _PeriodTile(period: recent[index]),
                  if (index != recent.length - 1)
                    const Divider(height: 1, color: AppColors.borderLight),
                ],
              ],
            ),
    );
  }
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({required this.period});

  final GamePeriod period;

  @override
  Widget build(BuildContext context) {
    final location = LocationDefinitions.byId(period.locationId).title;
    return ListTile(
      key: ValueKey('adult_period_${period.id}'),
      minTileHeight: 56,
      contentPadding: EdgeInsets.zero,
      onTap: () => showPeriodDetailsSheet(context: context, period: period),
      leading: const CircleAvatar(
        backgroundColor: AppColors.primaryBlueLight,
        child: Icon(Icons.calendar_today_rounded, color: AppColors.primaryBlue),
      ),
      title: Text(
        'День ${period.sequenceNumber} • $location',
        style: AppTextStyles.body,
      ),
      subtitle: Text('${period.completedTaskCount} заданий'),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _LearningProgressCard extends StatelessWidget {
  const _LearningProgressCard({required this.state, required this.periods});

  final AppController state;
  final List<GamePeriod> periods;

  @override
  Widget build(BuildContext context) {
    final themeDays = <String, int>{};
    for (final period in periods) {
      for (final theme in period.trainedThemeIds.toSet()) {
        themeDays.update(theme, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    const order = [
      'math',
      'finance',
      'logic',
      'memory',
      'attention',
      'entertainment',
      'safety',
      'unexpected',
    ];

    return _AdultCard(
      title: 'Учебный прогресс',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ValueRow(
            label: 'Выполнено заданий',
            value: '${state.completedTasks}',
          ),
          _ValueRow(
            label: 'Завершено игровых дней',
            value: '${periods.length}',
          ),
          _ValueRow(
            label: 'Финансовых целей достигнуто',
            value: '${state.achievedGoals}',
          ),
          const Divider(height: AppSpacing.lg),
          Text('Что уже тренировалось', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.xs),
          if (themeDays.isEmpty)
            Text(
              'Темы появятся после первого игрового дня.',
              style: AppTextStyles.bodySecondary,
            )
          else
            for (final id in order)
              if ((themeDays[id] ?? 0) > 0)
                _ThemeRow(id: id, days: themeDays[id]!),
        ],
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({required this.id, required this.days});

  final String id;
  final int days;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.green,
            size: 21,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              _taskThemeLabel(id),
              style: AppTextStyles.bodySecondary,
            ),
          ),
          Text('$days ${_daysWord(days)}', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _PetProgressionCard extends StatelessWidget {
  const _PetProgressionCard({required this.state, required this.lastPeriod});

  final AppController state;
  final GamePeriod? lastPeriod;

  @override
  Widget build(BuildContext context) {
    final stage = state.petGrowthStage;
    final isGrown = stage == PetGrowthStage.grown;
    final threshold = PetProgressionConfig.nextStageThreshold(
      state.petGrowthPoints,
    );
    final transitioned =
        lastPeriod != null &&
        lastPeriod!.petStageAtStart != lastPeriod!.petStageAtEnd;

    return _AdultCard(
      title: 'Развитие питомца',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stage.title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(
            isGrown
                ? 'Максимальная стадия'
                : '${state.petGrowthPoints} / $threshold',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppProgressBar(
            value: PetProgressionConfig.progressToNextStage(
              state.petGrowthPoints,
            ),
            gradient: AppGradients.primaryCta,
            semanticLabel: 'Прогресс развития Рыжика',
          ),
          if (lastPeriod != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'За последний период: +${lastPeriod!.growthPointsAwarded} очков развития',
              style: AppTextStyles.body,
            ),
            if (transitioned)
              Text(
                'В прошлом периоде Рыжик перешёл на новую стадию.',
                style: AppTextStyles.bodySecondary,
              ),
          ],
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            key: const ValueKey('adult_growth_info'),
            onPressed: () => _showGrowthInfo(context),
            icon: const Icon(Icons.info_outline_rounded),
            label: const Text('Как развивается Рыжик?'),
          ),
        ],
      ),
    );
  }
}

class _DataActionsCard extends StatelessWidget {
  const _DataActionsCard({required this.state});

  final AppController state;

  @override
  Widget build(BuildContext context) {
    return _AdultCard(
      title: 'Приватность и данные',
      child: Column(
        children: [
          _ActionTile(
            key: const ValueKey('adult_stored_data_info'),
            icon: Icons.privacy_tip_outlined,
            label: 'Какие данные хранятся',
            onTap: () => _showStoredDataInfo(context),
          ),
          if (state.isDemoMode) ...[
            _ActionTile(
              key: const ValueKey('adult_reset_demo'),
              icon: Icons.restart_alt_rounded,
              label: 'Начать демо заново',
              onTap: () => _confirmResetDemo(context, state),
            ),
            _ActionTile(
              key: const ValueKey('adult_exit_demo'),
              icon: Icons.logout_rounded,
              label: 'Выйти из демо-режима',
              onTap: () => _exitDemo(context, state),
            ),
          ] else
            _ActionTile(
              key: const ValueKey('adult_delete_profile'),
              icon: Icons.delete_outline_rounded,
              label: 'Удалить профиль и данные',
              color: AppColors.pink,
              onTap: () => _confirmDeleteProfile(context, state),
            ),
        ],
      ),
    );
  }
}

class _ParentAccessCard extends StatelessWidget {
  const _ParentAccessCard({required this.state});

  final AppController state;

  @override
  Widget build(BuildContext context) {
    return _AdultCard(
      title: 'Родительский доступ',
      child: Column(
        children: [
          _ActionTile(
            key: const ValueKey('adult_change_pin'),
            icon: Icons.pin_outlined,
            label: 'Изменить PIN',
            onTap: () => _showChangePinSheet(context, state),
          ),
          FutureBuilder<bool>(
            future: state.isParentBiometricAvailable(),
            builder: (context, snapshot) {
              final available = snapshot.data ?? false;
              return SwitchListTile(
                key: const ValueKey('adult_biometric_switch'),
                minTileHeight: 56,
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(
                  Icons.fingerprint_rounded,
                  color: AppColors.primaryBlue,
                ),
                title: const Text('Использовать биометрию'),
                subtitle: Text(
                  available
                      ? 'PIN остаётся доступен на любом устройстве'
                      : 'Биометрия недоступна на этом устройстве',
                  style: AppTextStyles.caption,
                ),
                value: available && state.parentProfile.biometricEnabled,
                onChanged: available ? state.setParentBiometricEnabled : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.primaryBlue,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 56,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(label, style: AppTextStyles.body.copyWith(color: color)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _AdultCard extends StatelessWidget {
  const _AdultCard({this.title, required this.child, super.key});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RoundedSurfaceCard(
      borderRadius: AppRadii.card,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: AppTextStyles.cardTitle),
            const SizedBox(height: AppSpacing.sm),
          ],
          child,
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySecondary)),
          const SizedBox(width: AppSpacing.sm),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _BudgetFactRow extends StatelessWidget {
  const _BudgetFactRow({
    required this.label,
    required this.actual,
    required this.planned,
    required this.confirmed,
  });

  final String label;
  final int actual;
  final int planned;
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    return _ValueRow(
      label: label,
      value: confirmed
          ? '${_coins(actual)} из ${_coins(planned)}'
          : '${_coins(planned)} план',
    );
  }
}

Future<void> _showGrowthInfo(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.bottomSheet),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Как развивается Рыжик?', style: AppTextStyles.heading),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Рыжик развивается постепенно.\n\n'
              'На прогресс влияют:\n\n'
              '• планирование бюджета;\n'
              '• накопления;\n'
              '• движение к финансовой цели;\n'
              '• финансовые задания;\n'
              '• завершение игровых дней.\n\n'
              'Ошибки не уменьшают уже полученный прогресс.',
              style: AppTextStyles.bodySecondary,
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showStoredDataInfo(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.bottomSheet),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Какие данные хранятся', style: AppTextStyles.heading),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Локально на этом устройстве хранятся:\n\n'
              '• имя и возраст ребёнка;\n'
              '• игровой баланс и накопления;\n'
              '• игровые периоды;\n'
              '• прогресс заданий;\n'
              '• прогресс Рыжика;\n'
              '• настройки приложения.\n\n'
              'Приложение не использует реальную геолокацию ребёнка. '
              'Карта Москвы — это только игровой мир.',
              style: AppTextStyles.bodySecondary,
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showChangePinSheet(
  BuildContext context,
  AppController state,
) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.bottomSheet),
    builder: (_) => _ChangePinSheet(state: state),
  );
  if (changed == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Родительский PIN изменён')));
  }
}

class _ChangePinSheet extends StatefulWidget {
  const _ChangePinSheet({required this.state});

  final AppController state;

  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _repeatController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  Future<void> _changePin() async {
    if (_busy) return;
    final newPin = _newController.text;
    if (!ParentAccessService.isValidPinFormat(newPin)) {
      setState(() => _error = 'Новый PIN должен содержать 4–6 цифр.');
      return;
    }
    if (_repeatController.text != newPin) {
      setState(() => _error = 'Новые PIN-коды не совпадают.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final changed = await widget.state.changeParentPin(
      currentPin: _currentController.text,
      newPin: newPin,
    );
    if (!mounted) return;
    if (changed) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = 'Текущий PIN не совпал.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Изменить PIN', style: AppTextStyles.heading),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const ValueKey('adult_current_pin'),
                controller: _currentController,
                autofocus: true,
                obscureText: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Текущий PIN'),
              ),
              TextField(
                key: const ValueKey('adult_new_pin'),
                controller: _newController,
                obscureText: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Новый PIN'),
              ),
              TextField(
                key: const ValueKey('adult_repeat_new_pin'),
                controller: _repeatController,
                obscureText: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Повторите новый PIN',
                ),
              ),
              if (_error != null)
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: AppColors.pink),
                ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: const ValueKey('adult_change_pin_confirm'),
                onPressed: _busy ? null : _changePin,
                child: const Text('Сохранить новый PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmResetDemo(
  BuildContext context,
  AppController state,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Начать демонстрацию заново?'),
      content: const Text(
        'Текущий прогресс демо-профиля будет удалён.\n'
        'Обычный профиль не изменится.',
      ),
      actions: [
        TextButton(
          key: const ValueKey('adult_reset_demo_cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          key: const ValueKey('adult_reset_demo_confirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Начать заново'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await state.resetDemoMode();
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Демонстрация начата заново')));
}

Future<void> _exitDemo(BuildContext context, AppController state) async {
  final restored = await state.exitDemoMode();
  if (!context.mounted || !restored) return;
  Navigator.of(context).pop();
}

Future<void> _confirmDeleteProfile(
  BuildContext context,
  AppController state,
) async {
  final firstConfirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Удалить профиль?'),
      content: const Text(
        'Будут удалены:\n'
        '• баланс и накопления;\n'
        '• история игровых дней;\n'
        '• цель;\n'
        '• прогресс Рыжика;\n'
        '• настройки профиля.\n\n'
        'Это действие нельзя отменить.',
      ),
      actions: [
        TextButton(
          key: const ValueKey('adult_delete_cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          key: const ValueKey('adult_delete_continue'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Продолжить'),
        ),
      ],
    ),
  );
  if (firstConfirmed != true || !context.mounted) return;

  final controller = TextEditingController();
  var canDelete = false;
  final explicitlyConfirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Подтвердите удаление'),
        content: TextField(
          key: const ValueKey('adult_delete_word'),
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            setDialogState(() => canDelete = value.trim() == 'УДАЛИТЬ');
          },
          decoration: const InputDecoration(labelText: 'Введите слово УДАЛИТЬ'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            key: const ValueKey('adult_delete_confirm'),
            onPressed: canDelete
                ? () => Navigator.of(dialogContext).pop(true)
                : null,
            child: const Text('Удалить'),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  if (explicitlyConfirmed != true) return;
  final deleted = await state.deleteCurrentProfileData();
  if (!context.mounted || !deleted) return;
  Navigator.of(context).pop();
}

String _taskThemeLabel(String id) => switch (id) {
  'math' => 'Математика',
  'finance' => 'Финансовые решения',
  'logic' => 'Логика',
  'memory' => 'Память',
  'attention' => 'Внимание',
  'entertainment' => 'Развлечения',
  'safety' => 'Безопасность денег',
  'unexpected' => 'Непредвиденные расходы',
  _ => id,
};

String _daysWord(int count) {
  final mod100 = count % 100;
  final mod10 = count % 10;
  if (mod100 >= 11 && mod100 <= 14) return 'игровых дней';
  if (mod10 == 1) return 'игровой день';
  if (mod10 >= 2 && mod10 <= 4) return 'игровых дня';
  return 'игровых дней';
}

String _coins(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ' ',
);

String _completedGoalTitle(String title) {
  const prefix = 'Накопить на ';
  if (!title.startsWith(prefix)) return title;
  final value = title.substring(prefix.length);
  return value.isEmpty
      ? title
      : '${value[0].toUpperCase()}${value.substring(1)}';
}

/// What the app teaches (ТЗ 2.5.12): the learning goals, without grading
/// the child.
class _AppGoalsCard extends StatelessWidget {
  const _AppGoalsCard();

  static const goals = [
    (
      Icons.account_balance_wallet_rounded,
      'Планировать бюджет',
      'Распределять монеты на важное, приятное и копилку до начала дня.',
    ),
    (
      Icons.check_circle_rounded,
      'Различать нужное и желаемое',
      'Сначала еда и уход, приятные покупки — по возможности.',
    ),
    (
      Icons.savings_rounded,
      'Копить на цель',
      'Регулярно откладывать часть монет и видеть, как цель приближается.',
    ),
    (
      Icons.insights_rounded,
      'Оценивать решения',
      'Сравнивать план и факт и понимать, к чему привёл выбор.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _AdultCard(
      key: const ValueKey('adult_app_goals'),
      title: 'Чему учит приложение',
      child: Column(
        children: [
          for (final (icon, title, text) in goals)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: AppColors.primaryBlue),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.body),
                        Text(text, style: AppTextStyles.bodySecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Монеты в игре не имеют реальной стоимости. Взрослый поддерживает, '
            'но решения принимает ребёнок.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

/// Parent's extra coins (ТЗ 2.5.12): a fixed small amount with a reason the
/// child sees in the coin history. It never replaces the child's decisions.
class _ParentRewardCard extends StatefulWidget {
  const _ParentRewardCard({required this.state});

  final AppController state;

  @override
  State<_ParentRewardCard> createState() => _ParentRewardCardState();
}

class _ParentRewardCardState extends State<_ParentRewardCard> {
  static const reasons = [
    'За помощь по дому',
    'За хорошую учёбу',
    'За выполненное обещание',
  ];

  int _amount = AppController.parentRewardAmounts.first;
  String _reason = reasons.first;

  Future<void> _award() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Начислить монеты?'),
        content: Text(
          '$_amount игровых монет — «$_reason». Ребёнок увидит это '
          'начисление в истории монет.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            key: const ValueKey('parent_reward_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Начислить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (widget.state.awardCoinsFromParent(_amount, _reason)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Начислено $_amount монет: $_reason')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AdultCard(
      key: const ValueKey('adult_parent_reward'),
      title: 'Поощрить монетами',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Небольшое поощрение за дела вне игры. Как распорядиться монетами, '
            'решает ребёнок.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final amount in AppController.parentRewardAmounts)
                ChoiceChip(
                  key: ValueKey('parent_reward_$amount'),
                  label: Text('+$amount'),
                  selected: amount == _amount,
                  onSelected: (_) => setState(() => _amount = amount),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final reason in reasons)
                ChoiceChip(
                  label: Text(reason),
                  selected: reason == _reason,
                  onSelected: (_) => setState(() => _reason = reason),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            key: const ValueKey('parent_reward_award'),
            onPressed: _award,
            icon: const Icon(Icons.card_giftcard_rounded),
            label: Text('Начислить $_amount монет'),
          ),
        ],
      ),
    );
  }
}
