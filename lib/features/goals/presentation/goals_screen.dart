import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/account_header.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../../core/widgets/secondary_capsule_button.dart';
import '../../budget/domain/budget_usage.dart';
import '../domain/savings_goal.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final selectedGoal = appState.selectedGoal;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppAssets.backgroundBedroomDay,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xC5E7EDFF), Color(0xE8FFF4EC)],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              AccountHeader(
                avatar: Image.asset(
                  AppAssets.avatarChildDefault,
                  fit: BoxFit.cover,
                ),
                levelLabel: 'Ур. ${appState.petLevel}',
                balance: _formatCoins(appState.balance),
                savings: _formatCoins(appState.savings),
                balanceLeading: Image.asset(
                  AppAssets.financeCoinSingle,
                  width: 28,
                  height: 28,
                ),
                savingsLeading: Image.asset(
                  AppAssets.financePiggyBank,
                  width: 34,
                  height: 34,
                ),
                showSavingsChevron: false,
                trailing: const _SettingsButton(),
                useSafeArea: false,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.sm,
                    AppSpacing.md,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _GoalsHeroBanner(),
                          const SizedBox(height: AppSpacing.sm),
                          _CurrentGoalCard(
                            appState: appState,
                            goal: selectedGoal,
                            onContribute: () =>
                                _showContributionSheet(context, appState),
                            onWithdraw: () =>
                                _showWithdrawalSheet(context, appState),
                            onComplete: () => _completeGoal(context, appState),
                            onChooseNewGoal: () =>
                                _showGoalPicker(context, appState),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Следующая мечта',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          for (final goal in appState.goals)
                            if (goal.id != selectedGoal.id)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xs,
                                ),
                                child: _NextGoalCard(
                                  goal: goal,
                                  completed: appState.isGoalCompleted(goal.id),
                                  onChoose: appState.isGoalCompleted(goal.id)
                                      ? null
                                      : () => _showGoalConfirmation(
                                          context,
                                          appState,
                                          goal,
                                        ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showWithdrawalSheet(
    BuildContext context,
    AppController appState,
  ) async {
    final maximum = appState.savings;
    if (maximum <= 0) return;
    var amount = maximum >= 300 ? 300 : maximum;
    final presets = const [
      100,
      300,
      500,
    ].where((value) => value <= maximum).toList(growable: false);

    await showAppModalSheet<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final after = appState.savings - amount;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Сколько возьмём?', style: AppTextStyles.heading),
              const SizedBox(height: 4),
              Text(
                'В копилке ${_formatCoins(appState.savings)} монет',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatCoins(amount),
                    key: const ValueKey('withdraw_selected_amount'),
                    style: AppTextStyles.display.copyWith(fontSize: 48),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Image.asset(
                    AppAssets.financeCoinSingle,
                    width: 48,
                    height: 48,
                  ),
                ],
              ),
              Slider(
                key: const ValueKey('withdraw_amount_slider'),
                value: amount.toDouble(),
                min: 0,
                max: maximum.toDouble(),
                activeColor: AppColors.primaryBlue,
                inactiveColor: AppColors.track,
                onChanged: (value) => setModalState(
                  () => amount = value.round().clamp(0, maximum),
                ),
              ),
              if (presets.isNotEmpty) ...[
                Row(
                  children: [
                    for (var index = 0; index < presets.length; index++) ...[
                      if (index > 0) const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: _AmountPreset(
                          key: ValueKey('withdraw_preset_${presets[index]}'),
                          amount: presets[index],
                          selected: amount == presets[index],
                          enabled: true,
                          onTap: () =>
                              setModalState(() => amount = presets[index]),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlueLight,
                  borderRadius: AppRadii.mediumBorder,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Сейчас: ${appState.selectedGoal.title}',
                      style: AppTextStyles.body,
                    ),
                    Text(
                      '${_formatCoins(appState.savings)} / ${_formatCoins(appState.goalPrice)} монет',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('После:', style: AppTextStyles.body),
                    Text(
                      '${_formatCoins(after)} / ${_formatCoins(appState.goalPrice)} монет',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amount == 0
                          ? 'Выбери сумму.'
                          : 'До цели станет дальше на ${_formatCoins(amount)} монет.',
                      style: AppTextStyles.bodySecondary.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryGradientButton(
                key: const ValueKey('withdraw_confirm'),
                label: 'Взять ${_formatCoins(amount)} монет',
                onPressed: amount > 0
                    ? () {
                        final result = appState.withdrawFromSavings(amount);
                        if (result == SavingsWithdrawalResult.success) {
                          Navigator.of(sheetContext).pop();
                        }
                      }
                    : null,
                leading: const Icon(
                  Icons.outbox_rounded,
                  color: AppColors.surface,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Оставить в копилке'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _completeGoal(
    BuildContext context,
    AppController appState,
  ) async {
    final goal = appState.selectedGoal;
    final result = appState.completeSelectedGoal();
    if (result != GoalCompletionResult.success || !context.mounted) return;
    final chooseNext = await showAppModalSheet<bool>(
      context: context,
      isDismissible: false,
      builder: (sheetContext) => _GoalCompletionCelebration(
        goal: goal,
        savingsRemaining: appState.savings,
        onChooseNext: () => Navigator.of(sheetContext).pop(true),
        onClose: () => Navigator.of(sheetContext).pop(false),
      ),
    );
    if (chooseNext == true && context.mounted) {
      await _showGoalPicker(context, appState);
    }
  }

  Future<void> _showContributionSheet(
    BuildContext context,
    AppController appState,
  ) async {
    final maximum = appState.maxSavingsContribution;
    final plannedSuggestion = appState.savingsPlanRemaining
        .clamp(0, maximum)
        .toInt();
    var amount = plannedSuggestion > 0
        ? plannedSuggestion
        : maximum >= 300
        ? 300
        : maximum;
    var saved = false;
    var savedMoreThanPlanned = false;
    var awaitingPlanConfirmation = false;

    await showAppModalSheet<void>(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (saved) {
              return _SavingsSuccess(
                goal: appState.selectedGoal,
                remaining: appState.goalRemaining,
                savedMoreThanPlanned: savedMoreThanPlanned,
                onClose: () => Navigator.of(sheetContext).pop(),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Сколько отложим?', style: AppTextStyles.heading),
                const SizedBox(height: 4),
                Text(
                  'Доступно ${_formatCoins(appState.balance)} монет',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlueLight,
                    borderRadius: AppRadii.mediumBorder,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_note_rounded,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'По плану: ${_formatCoins(appState.budgetPlan.savingsPlanned)} монет',
                              style: AppTextStyles.body,
                            ),
                            Text(
                              appState.budgetUsage.savingsDeposited == 0
                                  ? 'Эту сумму ты выбрал в бюджете'
                                  : 'Уже отложено по плану: '
                                        '${_formatCoins(appState.budgetUsage.savingsDeposited)}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatCoins(amount),
                      key: const ValueKey('goal_selected_amount'),
                      style: AppTextStyles.display.copyWith(fontSize: 48),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Image.asset(
                      AppAssets.financeCoinSingle,
                      width: 48,
                      height: 48,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Slider(
                  key: const ValueKey('goal_amount_slider'),
                  value: maximum == 0 ? 0 : amount.toDouble(),
                  min: 0,
                  max: maximum == 0 ? 1 : maximum.toDouble(),
                  activeColor: AppColors.primaryBlue,
                  inactiveColor: AppColors.track,
                  onChanged: maximum == 0
                      ? null
                      : (value) {
                          setModalState(() {
                            amount = value.round();
                            awaitingPlanConfirmation = false;
                          });
                        },
                ),
                if (plannedSuggestion > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    child: SecondaryCapsuleButton(
                      key: const ValueKey('goal_plan_amount'),
                      label: 'По плану — ${_formatCoins(plannedSuggestion)}',
                      onPressed: () {
                        setModalState(() {
                          amount = plannedSuggestion;
                          awaitingPlanConfirmation = false;
                        });
                      },
                      leading: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Row(
                  children: [
                    for (final preset in const [100, 300, 500]) ...[
                      if (preset != 100) const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: _AmountPreset(
                          key: ValueKey('goal_preset_$preset'),
                          amount: preset,
                          selected: amount == preset,
                          enabled: preset <= maximum,
                          onTap: () {
                            setModalState(() {
                              amount = preset;
                              awaitingPlanConfirmation = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F8EA),
                    borderRadius: AppRadii.mediumBorder,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        AppAssets.foxPeekingHappyLevel05,
                        width: 62,
                        height: 62,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          amount == 0
                              ? 'Выбери сумму, которую хочешь отложить.'
                              : 'После этого до цели останется '
                                    '${_formatCoins((appState.goalRemaining - amount).clamp(0, appState.goalPrice))} монет.',
                          style: AppTextStyles.body.copyWith(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                if (awaitingPlanConfirmation) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3D8),
                      borderRadius: AppRadii.mediumBorder,
                      border: Border.all(color: const Color(0xFFFFD785)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.tips_and_updates_rounded,
                          color: AppColors.orange,
                          size: 34,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Ты планировал отложить '
                          '${_formatCoins(appState.budgetPlan.savingsPlanned)} монет.\n'
                          'Если отложить ${_formatCoins(amount)}, '
                          'на текущие расходы останется '
                          '${_formatCoins(appState.balance - amount)}.\n\n'
                          'Всё равно отложить?',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                key: const ValueKey('goal_overrun_cancel'),
                                onPressed: () => setModalState(
                                  () => awaitingPlanConfirmation = false,
                                ),
                                child: const Text('Не сейчас'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: PrimaryGradientButton(
                                key: const ValueKey('goal_overrun_confirm'),
                                label: 'Отложить',
                                height: 50,
                                onPressed: () {
                                  final result = appState.addToSavings(
                                    amount,
                                    confirmPlanOverrun: true,
                                  );
                                  if (result == SavingsDepositResult.success) {
                                    setModalState(() {
                                      saved = true;
                                      savedMoreThanPlanned = true;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                PrimaryGradientButton(
                  key: const ValueKey('goal_save_confirm'),
                  label: 'Отложить ${_formatCoins(amount)}',
                  onPressed: amount > 0
                      ? () {
                          final result = appState.addToSavings(amount);
                          switch (result) {
                            case SavingsDepositResult.success:
                              setModalState(() {
                                saved = true;
                                savedMoreThanPlanned =
                                    appState.budgetUsage.savingsDeposited >
                                    appState.budgetPlan.savingsPlanned;
                              });
                            case SavingsDepositResult.requiresConfirmation:
                              setModalState(
                                () => awaitingPlanConfirmation = true,
                              );
                            case SavingsDepositResult.insufficientFunds:
                              break;
                          }
                        }
                      : null,
                  leading: Image.asset(
                    AppAssets.financePiggyBank,
                    width: 34,
                    height: 34,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Не сейчас'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showGoalConfirmation(
    BuildContext context,
    AppController appState,
    SavingsGoal goal,
  ) async {
    await showAppModalSheet<void>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Выбрать новую цель?', style: AppTextStyles.heading),
          const SizedBox(height: AppSpacing.md),
          _GoalArtwork(goal: goal, size: 130),
          const SizedBox(height: AppSpacing.sm),
          Text(goal.title, style: AppTextStyles.cardTitle),
          Text(
            '${_formatCoins(goal.price)} монет',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.primaryBlueLight,
              borderRadius: AppRadii.mediumBorder,
            ),
            child: Text(
              'Накопленные монеты останутся в копилке.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryGradientButton(
            key: ValueKey('confirm_goal_${goal.id}'),
            label: 'Выбрать',
            onPressed: () {
              appState.selectGoal(goal.id);
              Navigator.of(sheetContext).pop();
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Оставить текущую'),
          ),
        ],
      ),
    );
  }

  Future<void> _showGoalPicker(
    BuildContext context,
    AppController appState,
  ) async {
    final goal = await showAppModalSheet<SavingsGoal>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Выбери новую мечту', style: AppTextStyles.heading),
          const SizedBox(height: AppSpacing.md),
          for (final goal in appState.goals)
            if (goal.id != appState.selectedGoalId &&
                !appState.isGoalCompleted(goal.id))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: RoundedSurfaceCard(
                  key: ValueKey('goal_picker_${goal.id}'),
                  onTap: () => Navigator.of(sheetContext).pop(goal),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      _GoalArtwork(goal: goal, size: 68),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(goal.title, style: AppTextStyles.body),
                            Text(
                              '${_formatCoins(goal.price)} монет',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primaryBlue,
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );

    if (goal != null && context.mounted) {
      await _showGoalConfirmation(context, appState, goal);
    }
  }
}

class _GoalsHeroBanner extends StatelessWidget {
  const _GoalsHeroBanner();

  @override
  Widget build(BuildContext context) {
    return RoundedSurfaceCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        108,
        AppSpacing.sm,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF2C4),
                  borderRadius: AppRadii.mediumBorder,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: AppColors.yellow,
                  size: 38,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Мои цели', style: AppTextStyles.cardTitle),
                    Text(
                      'Большие мечты начинаются\nс маленьких шагов!',
                      style: AppTextStyles.bodySecondary.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: -100,
            bottom: -13,
            child: Image.asset(
              AppAssets.foxPeekingHappyLevel05,
              width: 112,
              height: 112,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentGoalCard extends StatelessWidget {
  const _CurrentGoalCard({
    required this.appState,
    required this.goal,
    required this.onContribute,
    required this.onWithdraw,
    required this.onComplete,
    required this.onChooseNewGoal,
  });

  final AppController appState;
  final SavingsGoal goal;
  final VoidCallback onContribute;
  final VoidCallback onWithdraw;
  final VoidCallback onComplete;
  final VoidCallback onChooseNewGoal;

  @override
  Widget build(BuildContext context) {
    final reached = appState.isGoalReached;
    final completed = appState.isSelectedGoalCompleted;
    final progressPercent = completed
        ? 100
        : (appState.goalProgress * 100).round();
    return RoundedSurfaceCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadii.heroCard,
      shadows: AppShadows.elevatedCard,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 238,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE9F4FF), Color(0xFFFFF4E7)],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadii.extraLarge),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned(
                  left: 24,
                  top: 24,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.yellow,
                    size: 34,
                  ),
                ),
                _GoalArtwork(goal: goal, size: 220),
                if (reached || completed)
                  Positioned(
                    right: 18,
                    top: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        borderRadius: AppRadii.capsule,
                      ),
                      child: Text(
                        '🎉 Готово!',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reached || completed ? '🎉 Мечта достигнута!' : goal.title,
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _formatCoins(
                          completed ? goal.price : appState.savings,
                        ),
                        style: AppTextStyles.cardTitle,
                      ),
                      TextSpan(
                        text: ' / ${_formatCoins(goal.price)} монет',
                        style: AppTextStyles.bodySecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: AppProgressBar(
                        value: completed ? 1 : appState.goalProgress,
                        height: 14,
                        foregroundColor: AppColors.green,
                        semanticLabel: 'Прогресс цели ${goal.title}',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text('$progressPercent%', style: AppTextStyles.body),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _GoalStat(
                        imagePath: AppAssets.financePiggyBank,
                        label: completed
                            ? 'Осталось в копилке'
                            : 'Уже накоплено',
                        value: _formatCoins(appState.savings),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _GoalStat(
                        icon: Icons.star_rounded,
                        label: completed ? 'Цель' : 'Осталось',
                        value: completed
                            ? 'Готово'
                            : _formatCoins(appState.goalRemaining),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryGradientButton(
                  key: ValueKey(
                    completed
                        ? 'choose_new_goal'
                        : reached
                        ? 'complete_goal'
                        : 'open_savings_sheet',
                  ),
                  label: completed
                      ? 'Выбрать новую цель'
                      : reached
                      ? 'Получить ${_dreamName(goal)}'
                      : 'Положить в копилку',
                  onPressed: completed
                      ? onChooseNewGoal
                      : reached
                      ? onComplete
                      : onContribute,
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.surface,
                  ),
                ),
                if (!completed && appState.savings > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  SecondaryCapsuleButton(
                    key: const ValueKey('open_withdrawal_sheet'),
                    label: 'Взять из копилки',
                    expand: true,
                    onPressed: onWithdraw,
                    leading: const Icon(Icons.outbox_rounded),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalStat extends StatelessWidget {
  const _GoalStat({
    this.imagePath,
    this.icon,
    required this.label,
    required this.value,
  });

  final String? imagePath;
  final IconData? icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: AppRadii.mediumBorder,
      ),
      child: Row(
        children: [
          if (imagePath != null)
            Image.asset(imagePath!, width: 38, height: 38)
          else
            Icon(icon, color: AppColors.yellow, size: 38),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
                Text(value, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextGoalCard extends StatelessWidget {
  const _NextGoalCard({
    required this.goal,
    required this.completed,
    required this.onChoose,
  });

  final SavingsGoal goal;
  final bool completed;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) {
    return RoundedSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          _GoalArtwork(goal: goal, size: 88),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title, style: AppTextStyles.cardTitle),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Image.asset(
                        AppAssets.financeCoinSingle,
                        width: 22,
                        height: 22,
                      ),
                      const SizedBox(width: 4),
                      Text(_formatCoins(goal.price), style: AppTextStyles.body),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SecondaryCapsuleButton(
            key: ValueKey('choose_goal_${goal.id}'),
            label: completed ? 'Достигнута ✓' : 'Выбрать',
            onPressed: onChoose,
            trailing: completed
                ? null
                : const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _GoalArtwork extends StatelessWidget {
  const _GoalArtwork({required this.goal, required this.size});

  final SavingsGoal goal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = goal.assetPath;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: _goalColor(goal.id),
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: asset != null
          ? Image.asset(asset, fit: BoxFit.contain)
          : Icon(
              goal.id == 'scooter'
                  ? Icons.electric_scooter_rounded
                  : Icons.extension_rounded,
              color: goal.id == 'scooter'
                  ? AppColors.purple
                  : AppColors.primaryBlue,
              size: size * 0.58,
            ),
    );
  }
}

class _AmountPreset extends StatelessWidget {
  const _AmountPreset({
    required this.amount,
    required this.selected,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final int amount;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryBlue : AppColors.surfaceSoft,
      borderRadius: AppRadii.capsule,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadii.capsule,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minimumTouchTarget,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadii.capsule,
            border: Border.all(
              color: selected ? AppColors.primaryBlue : AppColors.borderLight,
            ),
          ),
          child: Text(
            '$amount',
            style: AppTextStyles.body.copyWith(
              color: !enabled
                  ? AppColors.disabled
                  : selected
                  ? AppColors.surface
                  : AppColors.navy,
            ),
          ),
        ),
      ),
    );
  }
}

class _SavingsSuccess extends StatelessWidget {
  const _SavingsSuccess({
    required this.goal,
    required this.remaining,
    required this.savedMoreThanPlanned,
    required this.onClose,
  });

  final SavingsGoal goal;
  final int remaining;
  final bool savedMoreThanPlanned;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AppAssets.foxPeekingHappyLevel05,
          width: 140,
          height: 140,
          fit: BoxFit.contain,
        ),
        Text('Отлично!', style: AppTextStyles.heading),
        const SizedBox(height: AppSpacing.xs),
        Text(
          savedMoreThanPlanned
              ? 'Ты отложил даже больше, чем планировал!'
              : remaining == 0
              ? 'На цель «${goal.title}» уже накоплено!'
              : 'До цели осталось ${_formatCoins(remaining)} монет.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryGradientButton(
          key: const ValueKey('goal_savings_done'),
          label: 'Готово',
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _GoalCompletionCelebration extends StatelessWidget {
  const _GoalCompletionCelebration({
    required this.goal,
    required this.savingsRemaining,
    required this.onChooseNext,
    required this.onClose,
  });

  final SavingsGoal goal;
  final int savingsRemaining;
  final VoidCallback onChooseNext;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AppAssets.foxPeekingHappyLevel05,
          width: 145,
          height: 145,
          fit: BoxFit.contain,
        ),
        Text('Мечта достигнута!', style: AppTextStyles.heading),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ты накопил на ${_dreamName(goal).toLowerCase()}!',
          textAlign: TextAlign.center,
          style: AppTextStyles.cardTitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F8EA),
            borderRadius: AppRadii.mediumBorder,
          ),
          child: Text(
            'Осталось в копилке: ${_formatCoins(savingsRemaining)} монет',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryGradientButton(
          key: const ValueKey('goal_completion_choose_next'),
          label: 'Выбрать новую цель',
          onPressed: onChooseNext,
        ),
        TextButton(onPressed: onClose, child: const Text('Готово')),
      ],
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return const RoundedSurfaceCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadii.capsule,
      child: SizedBox.square(
        dimension: 50,
        child: Icon(Icons.settings_rounded, color: AppColors.secondaryText),
      ),
    );
  }
}

Color _goalColor(String id) {
  return switch (id) {
    'scooter' => const Color(0xFFE9DEFF),
    'building_set' => const Color(0xFFFFF2C4),
    _ => AppColors.primaryBlueLight,
  };
}

String _formatCoins(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
}

String _dreamName(SavingsGoal goal) {
  const prefix = 'Накопить на ';
  if (!goal.title.startsWith(prefix)) return goal.title;
  final value = goal.title.substring(prefix.length);
  return value.isEmpty
      ? goal.title
      : '${value[0].toUpperCase()}${value.substring(1)}';
}
