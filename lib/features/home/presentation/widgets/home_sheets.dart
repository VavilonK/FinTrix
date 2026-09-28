import 'package:flutter/material.dart';

import '../../../../core/state/app_controller.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_modal_sheet.dart';
import '../../../../core/widgets/rounded_surface_card.dart';
import '../../../adult/presentation/adult_dashboard_screen.dart';
import '../../../adult/presentation/parent_unlock_sheet.dart';
import '../../../onboarding/presentation/game_intro_screen.dart';

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
            key: const ValueKey('settings_intro'),
            icon: Icons.school_rounded,
            color: AppColors.orange,
            label: 'Как играть',
            onTap: () {
              Navigator.of(sheetContext).pop();
              GameIntroScreen.open(context);
            },
          ),
          _SheetAction(
            key: const ValueKey('settings_glossary'),
            icon: Icons.menu_book_rounded,
            color: AppColors.green,
            label: 'Словарик',
            onTap: () {
              Navigator.of(sheetContext).pop();
              GlossaryScreen.open(context);
            },
          ),
          const SizedBox(height: AppSpacing.xs),
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

/// Resolves to the food that was bought and fed, or null if nothing was.
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
