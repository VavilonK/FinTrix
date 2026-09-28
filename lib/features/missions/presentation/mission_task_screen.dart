import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../budget/domain/budget_usage.dart';
import '../../tasks/data/location_definitions.dart';
import '../domain/mission_models.dart';
import 'mission_result_screen.dart';
import 'widgets/location_scene_widgets.dart';

class MissionTaskScreen extends StatefulWidget {
  const MissionTaskScreen({required this.onReturnHome, super.key});

  final VoidCallback onReturnHome;

  @override
  State<MissionTaskScreen> createState() => _MissionTaskScreenState();
}

class _MissionTaskScreenState extends State<MissionTaskScreen> {
  String? _preparedTaskId;
  String? _selectedOptionId;
  final Map<String, int> _allocations = {};
  final Map<String, String> _classifications = {};

  void _prepare(MissionTask task) {
    if (_preparedTaskId == task.id) return;
    _preparedTaskId = task.id;
    _selectedOptionId = null;
    _allocations
      ..clear()
      ..addEntries(task.options.map((option) => MapEntry(option.id, 0)));
    _classifications.clear();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final mission = appState.activeMission;
    final task = appState.currentTask;
    if (mission == null || task == null) return const SizedBox.shrink();
    _prepare(task);
    final location = LocationDefinitions.byId(mission.locationId);

    final canSubmit = switch (task.type) {
      MissionTaskType.budgetSplit =>
        _allocations.values.fold<int>(0, (sum, value) => sum + value) ==
            task.totalAmount,
      MissionTaskType.classification =>
        _classifications.length == task.options.length,
      _ => _selectedOptionId != null,
    };

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          LocationSceneBackground(
            sceneAsset: location.sceneAsset,
            overlayOpacity: 0.87,
          ),
          const Positioned(
            right: -54,
            top: 120,
            child: _DecorativeBubble(size: 150, color: Color(0x1F8649F4)),
          ),
          const Positioned(
            left: -42,
            bottom: 120,
            child: _DecorativeBubble(size: 130, color: Color(0x2451A8FF)),
          ),
          SafeArea(
            child: Column(
              children: [
                _MissionHeader(
                  current: appState.currentTaskIndex + 1,
                  total: mission.tasks.length,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          children: [
                            _TaskQuestionCard(task: task),
                            const SizedBox(height: AppSpacing.md),
                            _buildMechanic(task),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xEFFFFFFF),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        offset: Offset(0, -4),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: PrimaryGradientButton(
                    key: const ValueKey('mission_submit'),
                    label: _submitLabel(task),
                    onPressed: canSubmit
                        ? () => _submit(context, appState, task)
                        : null,
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMechanic(MissionTask task) {
    if (task.type == MissionTaskType.budgetSplit) {
      final allocated = _allocations.values.fold<int>(
        0,
        (sum, value) => sum + value,
      );
      return Column(
        children: [
          _AllocationMeter(allocated: allocated, total: task.totalAmount ?? 0),
          const SizedBox(height: AppSpacing.sm),
          for (final option in task.options)
            _BudgetRow(
              option: option,
              amount: _allocations[option.id] ?? 0,
              step: task.stepAmount,
              canIncrease:
                  allocated + task.stepAmount <= (task.totalAmount ?? 0),
              onChanged: (value) {
                setState(() => _allocations[option.id] = value);
              },
            ),
        ],
      );
    }

    if (task.type == MissionTaskType.classification) {
      return Column(
        children: [
          for (final option in task.options)
            _ClassificationRow(
              option: option,
              selected: _classifications[option.id],
              onSelected: (category) {
                setState(() => _classifications[option.id] = category);
              },
            ),
        ],
      );
    }

    return Column(
      children: [
        for (final option in task.options)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _OptionCard(
              option: option,
              selected: _selectedOptionId == option.id,
              showCoin: task.theme == MissionTheme.math,
              // Real purchases the child cannot afford stay visible with the
              // missing amount instead of disappearing.
              shortBy: task.economyType == TaskEconomyType.realExpense
                  ? option.spendCoins - AppScope.of(context).balance
                  : 0,
              onTap: () => setState(() => _selectedOptionId = option.id),
            ),
          ),
      ],
    );
  }

  /// A real purchase names its price on the button, so tapping it is the
  /// purchase confirmation (ТЗ 2.5.6).
  String _submitLabel(MissionTask task) {
    if (task.economyType != TaskEconomyType.realExpense) return 'Ответить';
    final option = task.options
        .where((candidate) => candidate.id == _selectedOptionId)
        .firstOrNull;
    if (option == null) return 'Выбери вариант';
    return option.spendCoins > 0
        ? 'Купить за ${option.spendCoins}'
        : 'Не покупать';
  }

  Future<void> _submit(
    BuildContext context,
    AppController appState,
    MissionTask task,
  ) async {
    bool? correctOverride;
    if (task.type == MissionTaskType.budgetSplit) {
      correctOverride = true;
    } else if (task.type == MissionTaskType.classification) {
      correctOverride = task.options.every(
        (option) => _classifications[option.id] == option.category,
      );
    }

    MissionTaskOption? selectedOption;
    for (final option in task.options) {
      if (option.id == _selectedOptionId) selectedOption = option;
    }
    final category = selectedOption?.expenseCategory ?? task.expenseCategory;
    final expense = task.spendCoins + (selectedOption?.spendCoins ?? 0);
    final answerWillSpend =
        correctOverride == true || _selectedOptionId == task.correctOptionId;
    if (answerWillSpend &&
        category != null &&
        appState.wouldExceedBudgetPlan(expense, category)) {
      final confirmed = await _confirmBudgetOverrun(
        context,
        appState,
        category,
        expense,
      );
      if (!confirmed || !context.mounted) return;
    }

    appState.submitCurrentTask(
      selectedOptionId: _selectedOptionId,
      isCorrectOverride: correctOverride,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MissionResultScreen(onReturnHome: widget.onReturnHome),
      ),
    );
  }

  Future<bool> _confirmBudgetOverrun(
    BuildContext context,
    AppController appState,
    ExpenseCategory category,
    int amount,
  ) async {
    final label = category == ExpenseCategory.essential
        ? 'На важное'
        : 'На приятное';
    final planned = appState.plannedForExpense(category);
    final afterPurchase = appState.spentForExpense(category) + amount;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
            icon: const Icon(
              Icons.tips_and_updates_rounded,
              color: AppColors.orange,
              size: 42,
            ),
            title: const Text('Проверим план'),
            content: Text(
              '$label мы планировали $planned монет.\n'
              'Если купить это, получится $afterPurchase.\n\n'
              'Всё равно купить?',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Не сейчас'),
              ),
              FilledButton(
                key: const ValueKey('mission_overrun_confirm'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Купить'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _MissionHeader extends StatelessWidget {
  const _MissionHeader({
    required this.current,
    required this.total,
    required this.onBack,
  });

  final int current;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 50,
            child: RoundedSurfaceCard(
              onTap: onBack,
              semanticLabel: 'Назад',
              padding: EdgeInsets.zero,
              borderRadius: AppRadii.capsule,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RoundedSurfaceCard(
              borderRadius: AppRadii.mediumBorder,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Задание $current из $total',
                          style: AppTextStyles.cardTitle.copyWith(fontSize: 17),
                        ),
                      ),
                      const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.yellow,
                        size: 23,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  AppProgressBar(
                    value: current / total,
                    height: 9,
                    gradient: AppGradients.primaryCta,
                    semanticLabel: 'Прогресс ежедневной миссии',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskQuestionCard extends StatelessWidget {
  const _TaskQuestionCard({required this.task});

  final MissionTask task;

  @override
  Widget build(BuildContext context) {
    final junior = task.difficultyLevel == DifficultyLevel.junior;
    final showCoins = task.theme == MissionTheme.math;
    return RoundedSurfaceCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadii.heroCard,
      shadows: AppShadows.elevatedCard,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFFFFF), Color(0xFFEAF5FF)],
                ),
                borderRadius: AppRadii.heroCard,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE9DEFF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _taskIcon(task.type),
                    color: AppColors.purple,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  task.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  task.description,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.navy,
                    fontSize: junior ? 19 : 18,
                    height: 1.35,
                  ),
                ),
                if (showCoins) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 7,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF6D8),
                      borderRadius: AppRadii.capsule,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 4,
                      children: [
                        for (var index = 0; index < (junior ? 4 : 3); index++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Image.asset(
                              AppAssets.financeCoinSingle,
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                            ),
                          ),
                        const SizedBox(width: 5),
                        Text(
                          junior ? 'Считай по шагам' : 'Подумай и посчитай',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: -4,
            bottom: -12,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(
                  AppAssets.foxPeekingHappyLevel05,
                  width: 88,
                  height: 88,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.selected,
    required this.showCoin,
    required this.onTap,
    this.shortBy = 0,
  });

  final MissionTaskOption option;
  final bool selected;
  final bool showCoin;
  final VoidCallback onTap;

  /// Coins missing for this purchase; > 0 disables the option.
  final int shortBy;

  @override
  Widget build(BuildContext context) {
    final cost = option.spendFromSavings > 0
        ? '${option.spendFromSavings} из копилки'
        : option.spendCoins > 0
        ? 'Стоимость: ${option.spendCoins}'
        : null;

    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        key: ValueKey('mission_option_${option.id}'),
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 78),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE5F2FF) : AppColors.surface,
          borderRadius: AppRadii.card,
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.borderLight,
            width: selected ? 3 : 1,
          ),
          boxShadow: selected ? AppShadows.primaryControl : AppShadows.card,
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: AppRadii.card,
          child: InkWell(
            onTap: shortBy > 0 ? null : onTap,
            borderRadius: AppRadii.card,
            child: Opacity(
              opacity: shortBy > 0 ? 0.6 : 1,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryBlue
                            : const Color(0xFFF1F4FC),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: showCoin
                          ? Image.asset(
                              AppAssets.financeCoinSingle,
                              width: 34,
                              height: 34,
                            )
                          : Icon(
                              selected
                                  ? Icons.check_rounded
                                  : Icons.touch_app_rounded,
                              color: selected
                                  ? AppColors.surface
                                  : AppColors.purple,
                            ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(option.label, style: AppTextStyles.cardTitle),
                          if (option.subtitle != null || cost != null)
                            Text(
                              option.subtitle ?? cost!,
                              style: AppTextStyles.caption,
                            ),
                          if (shortBy > 0)
                            Text(
                              'Не хватает $shortBy монет',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.pink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected
                          ? AppColors.primaryBlue
                          : AppColors.disabled,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AllocationMeter extends StatelessWidget {
  const _AllocationMeter({required this.allocated, required this.total});

  final int allocated;
  final int total;

  @override
  Widget build(BuildContext context) {
    return RoundedSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          Text('$allocated / $total монет', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.xs),
          AppProgressBar(
            value: total == 0 ? 0 : allocated / total,
            gradient: AppGradients.primaryCta,
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.option,
    required this.amount,
    required this.step,
    required this.canIncrease,
    required this.onChanged,
  });

  final MissionTaskOption option;
  final int amount;
  final int step;
  final bool canIncrease;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: RoundedSurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlueLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(option.label, style: AppTextStyles.body)),
            _StepButton(
              key: ValueKey('budget_minus_${option.id}'),
              icon: Icons.remove_rounded,
              enabled: amount >= step,
              onTap: () => onChanged(amount - step),
            ),
            SizedBox(
              width: 58,
              child: Text(
                '$amount',
                textAlign: TextAlign.center,
                style: AppTextStyles.cardTitle,
              ),
            ),
            _StepButton(
              key: ValueKey('budget_plus_${option.id}'),
              icon: Icons.add_rounded,
              enabled: canIncrease,
              onTap: () => onChanged(amount + step),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: enabled ? onTap : null,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        disabledBackgroundColor: AppColors.track,
        foregroundColor: AppColors.surface,
      ),
      icon: Icon(icon),
    );
  }
}

class _ClassificationRow extends StatelessWidget {
  const _ClassificationRow({
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  final MissionTaskOption option;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: RoundedSurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Text(option.label, style: AppTextStyles.cardTitle),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (final category in const ['НУЖНО', 'ХОЧУ'])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        key: ValueKey('classify_${option.id}_$category'),
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(category, textAlign: TextAlign.center),
                        ),
                        selected: selected == category,
                        showCheckmark: true,
                        onSelected: (_) => onSelected(category),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativeBubble extends StatelessWidget {
  const _DecorativeBubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

IconData _taskIcon(MissionTaskType type) {
  return switch (type) {
    MissionTaskType.calculation => Icons.calculate_rounded,
    MissionTaskType.choice => Icons.balance_rounded,
    MissionTaskType.logic => Icons.psychology_rounded,
    MissionTaskType.classification => Icons.category_rounded,
    MissionTaskType.matching => Icons.compare_arrows_rounded,
    MissionTaskType.budgetSplit => Icons.account_balance_wallet_rounded,
    MissionTaskType.attention => Icons.visibility_rounded,
    MissionTaskType.quiz => Icons.quiz_rounded,
  };
}
