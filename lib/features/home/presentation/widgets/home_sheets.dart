import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/state/app_controller.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_modal_sheet.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../../../../core/widgets/rounded_surface_card.dart';
import '../../../budget/domain/budget_usage.dart';
import '../../../adult/presentation/adult_dashboard_screen.dart';
import '../../../adult/presentation/parent_unlock_sheet.dart';
import '../../domain/pet_models.dart';

Future<void> showBalanceSummarySheet({
  required BuildContext context,
  required VoidCallback onOpenBudget,
  required VoidCallback onOpenTasks,
  required VoidCallback onOpenGoals,
}) {
  return showAppModalSheet<void>(
    context: context,
    builder: (sheetContext) {
      final state = AppScope.of(sheetContext);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Твой баланс', style: AppTextStyles.heading),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${_coins(state.balance)} монет',
            style: AppTextStyles.display.copyWith(color: AppColors.primaryBlue),
          ),
          const SizedBox(height: AppSpacing.md),
          _BudgetRow(
            icon: Icons.shopping_basket_rounded,
            color: AppColors.orange,
            label: 'На важное',
            amount: state.budgetPlan.essentialsPlanned,
          ),
          const SizedBox(height: AppSpacing.xs),
          _BudgetRow(
            icon: Icons.sports_esports_rounded,
            color: AppColors.purple,
            label: 'На приятное',
            amount: state.budgetPlan.wantsPlanned,
          ),
          const SizedBox(height: AppSpacing.xs),
          _BudgetRow(
            icon: Icons.savings_rounded,
            color: AppColors.green,
            label: 'На мечту',
            amount: state.budgetPlan.savingsPlanned,
          ),
          const SizedBox(height: AppSpacing.md),
          _SheetAction(
            key: const ValueKey('balance_open_budget'),
            icon: Icons.account_balance_wallet_rounded,
            label: 'Открыть бюджет',
            onTap: () => _closeAndRun(sheetContext, onOpenBudget),
          ),
          _SheetAction(
            key: const ValueKey('balance_open_tasks'),
            icon: Icons.location_on_rounded,
            label: 'Выполнить задания',
            onTap: () => _closeAndRun(sheetContext, onOpenTasks),
          ),
          _SheetAction(
            key: const ValueKey('balance_open_goals'),
            icon: Icons.star_rounded,
            label: 'Перейти к цели',
            onTap: () => _closeAndRun(sheetContext, onOpenGoals),
          ),
        ],
      );
    },
  );
}

Future<void> showQuickActionsSheet({
  required BuildContext context,
  required VoidCallback onOpenTasks,
  required VoidCallback onOpenBudget,
  required VoidCallback onOpenGoals,
}) {
  return showAppModalSheet<void>(
    context: context,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Как получить или распределить монеты?',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.md),
        _SheetAction(
          key: const ValueKey('quick_open_tasks'),
          icon: Icons.task_alt_rounded,
          color: AppColors.green,
          label: 'Выполнить задания',
          onTap: () => _closeAndRun(sheetContext, onOpenTasks),
        ),
        _SheetAction(
          key: const ValueKey('quick_open_budget'),
          icon: Icons.account_balance_wallet_rounded,
          label: 'Распределить бюджет',
          onTap: () => _closeAndRun(sheetContext, onOpenBudget),
        ),
        _SheetAction(
          key: const ValueKey('quick_open_goals'),
          icon: Icons.savings_rounded,
          color: AppColors.purple,
          label: 'Положить в копилку',
          onTap: () => _closeAndRun(sheetContext, onOpenGoals),
        ),
      ],
    ),
  );
}

Future<void> showSettingsSheet(BuildContext context) {
  return showAppModalSheet<void>(
    context: context,
    builder: (sheetContext) {
      final state = AppScope.of(sheetContext);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Настройки', style: AppTextStyles.heading),
          const SizedBox(height: AppSpacing.md),
          _SettingsSwitch(
            key: const ValueKey('settings_sound'),
            icon: Icons.volume_up_rounded,
            label: 'Звук',
            value: state.soundEnabled,
            onChanged: state.setSoundEnabled,
          ),
          const SizedBox(height: AppSpacing.xs),
          _SettingsSwitch(
            key: const ValueKey('settings_hints'),
            icon: Icons.lightbulb_rounded,
            label: 'Подсказки',
            value: state.hintsEnabled,
            onChanged: state.setHintsEnabled,
          ),
          const SizedBox(height: AppSpacing.md),
          _SheetAction(
            key: const ValueKey('settings_adult_section'),
            icon: Icons.family_restroom_rounded,
            color: AppColors.primaryBlue,
            label: 'Для родителей',
            onTap: () =>
                _openAdultSection(context: context, sheetContext: sheetContext),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (!state.isDemoMode) ...[
            _SheetAction(
              key: const ValueKey('settings_enter_demo'),
              icon: Icons.play_circle_fill_rounded,
              color: AppColors.purple,
              label: 'Демо-режим',
              onTap: () => _confirmEnterDemo(
                context: context,
                sheetContext: sheetContext,
                state: state,
              ),
            ),
          ] else ...[
            RoundedSurfaceCard(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                'Демо • День ${state.demoPeriodIndex} из 5',
                textAlign: TextAlign.center,
                style: AppTextStyles.cardTitle.copyWith(
                  color: AppColors.purple,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _SheetAction(
              key: const ValueKey('settings_restart_demo'),
              icon: Icons.restart_alt_rounded,
              color: AppColors.orange,
              label: 'Начать демо заново',
              onTap: () => _confirmRestartDemo(
                context: context,
                sheetContext: sheetContext,
                state: state,
              ),
            ),
            _SheetAction(
              key: const ValueKey('settings_exit_demo'),
              icon: Icons.logout_rounded,
              label: 'Выйти из демо-режима',
              onTap: () async {
                final restored = await state.exitDemoMode();
                if (!sheetContext.mounted || !context.mounted) return;
                if (restored) Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ],
      );
    },
  );
}

Future<void> _openAdultSection({
  required BuildContext context,
  required BuildContext sheetContext,
}) async {
  final unlocked = await showParentUnlockSheet(sheetContext);
  if (!unlocked || !sheetContext.mounted || !context.mounted) return;
  Navigator.of(sheetContext).pop();
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const AdultDashboardScreen()));
}

Future<void> _confirmEnterDemo({
  required BuildContext context,
  required BuildContext sheetContext,
  required AppController state,
}) async {
  final confirmed = await showDialog<bool>(
    context: sheetContext,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Запустить демонстрационный режим?'),
      content: const Text(
        'Будет создан отдельный тестовый сценарий из пяти игровых дней.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          key: const ValueKey('confirm_enter_demo'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Запустить'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  final started = await state.enterDemoMode();
  if (!sheetContext.mounted || !context.mounted) return;
  if (started) {
    Navigator.of(sheetContext).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Демо-режим запущен')));
  }
}

Future<void> _confirmRestartDemo({
  required BuildContext context,
  required BuildContext sheetContext,
  required AppController state,
}) async {
  final confirmed = await showDialog<bool>(
    context: sheetContext,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Начать демо заново?'),
      content: const Text(
        'Прогресс демо будет удалён. Обычный профиль сохранится.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          key: const ValueKey('confirm_restart_demo'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Начать заново'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await state.resetDemoMode();
  if (!sheetContext.mounted || !context.mounted) return;
  Navigator.of(sheetContext).pop();
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Демо начато с первого дня')));
}

Future<void> showFeedPetSheet({
  required BuildContext context,
  required VoidCallback onOpenTasks,
}) {
  return showAppModalSheet<void>(
    context: context,
    builder: (sheetContext) => _FeedPetSheet(
      onOpenTasks: () => _closeAndRun(sheetContext, onOpenTasks),
    ),
  );
}

class _FeedPetSheet extends StatefulWidget {
  const _FeedPetSheet({required this.onOpenTasks});

  final VoidCallback onOpenTasks;

  @override
  State<_FeedPetSheet> createState() => _FeedPetSheetState();
}

class _FeedPetSheetState extends State<_FeedPetSheet> {
  bool _insufficientFunds = false;
  FoodType? _pendingFood;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Чем угостим Рыжика?', style: AppTextStyles.heading),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Баланс: ${_coins(state.balance)} монет',
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final food in FoodType.values) ...[
          _FoodOption(
            key: ValueKey('feed_${food.name}'),
            type: food,
            onTap: () => _feed(state, food),
          ),
          if (food != FoodType.values.last)
            const SizedBox(height: AppSpacing.xs),
        ],
        if (_insufficientFunds) ...[
          const SizedBox(height: AppSpacing.md),
          RoundedSurfaceCard(
            backgroundColor: AppColors.backgroundLavender,
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: [
                Text(
                  'Сейчас монет не хватает.\nДавай сначала выполним задание!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryGradientButton(
                  key: const ValueKey('feed_open_tasks'),
                  label: 'К заданиям',
                  height: 52,
                  onPressed: widget.onOpenTasks,
                ),
              ],
            ),
          ),
        ],
        if (_pendingFood case final food?) ...[
          const SizedBox(height: AppSpacing.md),
          RoundedSurfaceCard(
            backgroundColor: const Color(0xFFFFF3D8),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: [
                Text(
                  '${food.expenseCategory == ExpenseCategory.essential ? 'На важное' : 'На приятное'} мы планировали '
                  '${_coins(state.plannedForExpense(food.expenseCategory))} монет.\n'
                  'Если купить это, получится '
                  '${_coins(state.spentForExpense(food.expenseCategory) + food.cost)}.\n\n'
                  'Всё равно купить?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        key: const ValueKey('feed_overrun_cancel'),
                        onPressed: () => setState(() => _pendingFood = null),
                        child: const Text('Не сейчас'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: PrimaryGradientButton(
                        key: const ValueKey('feed_overrun_confirm'),
                        label: 'Купить',
                        height: 50,
                        onPressed: () =>
                            _feed(state, food, confirmPlanOverrun: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _feed(
    AppController state,
    FoodType food, {
    bool confirmPlanOverrun = false,
  }) {
    final result = state.feedPet(food, confirmPlanOverrun: confirmPlanOverrun);
    if (result == FeedPetResult.insufficientFunds) {
      setState(() {
        _insufficientFunds = true;
        _pendingFood = null;
      });
      return;
    }
    if (result == FeedPetResult.requiresConfirmation) {
      setState(() {
        _pendingFood = food;
        _insufficientFunds = false;
      });
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Рыжик сыт и доволен!')));
  }
}

class _FoodOption extends StatelessWidget {
  const _FoodOption({required this.type, required this.onTap, super.key});

  final FoodType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, asset) = switch (type) {
      FoodType.basic => ('Обычный корм', AppAssets.foodBasicBowl),
      FoodType.healthy => ('Полезный перекус', AppAssets.foodHealthySnack),
      FoodType.treat => ('Вкусняшка', AppAssets.foodTreatDessert),
    };
    final details = switch (type) {
      FoodType.basic => 'Сытость +30 · Настроение +4',
      FoodType.healthy => 'Сытость +22 · Настроение +8 · Забота +3',
      FoodType.treat => 'Сытость +15 · Настроение +15',
    };

    return RoundedSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: AppColors.primaryBlueLight,
              borderRadius: AppRadii.mediumBorder,
            ),
            child: Image.asset(asset, fit: BoxFit.contain),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.cardTitle),
                const SizedBox(height: 3),
                Text(details, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            children: [
              Image.asset(AppAssets.financeCoinSingle, width: 25, height: 25),
              Text('${type.cost}', style: AppTextStyles.body),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withAlpha(35),
          foregroundColor: color,
          child: Icon(icon),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTextStyles.body)),
        Text('${_coins(amount)} монет', style: AppTextStyles.body),
      ],
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
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
    return Material(
      color: AppColors.transparent,
      child: ListTile(
        onTap: onTap,
        minTileHeight: 56,
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(32),
          foregroundColor: color,
          child: Icon(icon),
        ),
        title: Text(label, style: AppTextStyles.body),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return RoundedSurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: AppColors.primaryBlue),
        title: Text(label, style: AppTextStyles.body),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

void _closeAndRun(BuildContext context, VoidCallback action) {
  Navigator.of(context).pop();
  action();
}

String _coins(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
}
