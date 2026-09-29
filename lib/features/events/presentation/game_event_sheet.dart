import 'package:flutter/material.dart';

import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../domain/game_event.dart';

/// Shows the pending event: the child must pick an option (the sheet can't be
/// swiped away), then sees what changed and why. Resolves to the outcome, or
/// null when the child went to earn coins first.
Future<GameEventOutcome?> showGameEventSheet({
  required BuildContext context,
  required GameEventId eventId,
  required VoidCallback onOpenTasks,
}) {
  return showAppModalSheet<GameEventOutcome>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => GameEventSheet(
      event: GameEvents.of(eventId),
      onOpenTasks: () {
        Navigator.of(sheetContext).pop();
        onOpenTasks();
      },
    ),
  );
}

class GameEventSheet extends StatefulWidget {
  const GameEventSheet({
    required this.event,
    required this.onOpenTasks,
    super.key,
  });

  final GameEvent event;
  final VoidCallback onOpenTasks;

  @override
  State<GameEventSheet> createState() => _GameEventSheetState();
}

class _GameEventSheetState extends State<GameEventSheet> {
  GameEventOutcome? _outcome;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return PopScope(
      canPop: _outcome != null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Text(
              event.emoji,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 44),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            event.title,
            key: const ValueKey('event_title'),
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_outcome case final outcome?)
            _OutcomeView(
              outcome: outcome,
              onDone: () => Navigator.of(context).pop(outcome),
            )
          else
            _ChoiceView(
              event: event,
              onChoose: _choose,
              onOpenTasks: widget.onOpenTasks,
            ),
        ],
      ),
    );
  }

  void _choose(GameEventOption option) {
    final outcome = AppScope.of(context).resolveEvent(option.id);
    if (outcome != null) setState(() => _outcome = outcome);
  }
}

class _ChoiceView extends StatelessWidget {
  const _ChoiceView({
    required this.event,
    required this.onChoose,
    required this.onOpenTasks,
  });

  final GameEvent event;
  final ValueChanged<GameEventOption> onChoose;
  final VoidCallback onOpenTasks;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final paidOptions = event.options.where(
      (option) =>
          option.effect == GameEventEffect.payFromBalance ||
          option.effect == GameEventEffect.payFromSavings,
    );
    final cannotPay =
        paidOptions.isNotEmpty &&
        paidOptions.every((option) => !state.canChooseEventOption(option));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          event.situation,
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.sm),
        RoundedSurfaceCard(
          backgroundColor: AppColors.backgroundLavender,
          shadows: const [],
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Text(
            'Рыжик: «${event.petLine}»',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final option in event.options) ...[
          _OptionButton(
            option: option,
            enabled: state.canChooseEventOption(option),
            shortBy: switch (option.effect) {
              GameEventEffect.payFromBalance => option.amount - state.balance,
              GameEventEffect.payFromSavings => option.amount - state.savings,
              _ => 0,
            },
            onTap: () => onChoose(option),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (cannotPay) ...[
          const SizedBox(height: AppSpacing.xs),
          RoundedSurfaceCard(
            key: const ValueKey('event_cannot_pay'),
            backgroundColor: AppColors.backgroundLavender,
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: [
                const Text(
                  'Не хватает монет на ветеринара. Выполни задание — '
                  'заработаешь монеты, и мы вылечим лапку.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryGradientButton(
                  key: const ValueKey('event_open_tasks'),
                  label: 'К заданиям',
                  height: 52,
                  onPressed: onOpenTasks,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.option,
    required this.enabled,
    required this.shortBy,
    required this.onTap,
  });

  final GameEventOption option;
  final bool enabled;
  final int shortBy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = switch (option.effect) {
      GameEventEffect.payFromBalance ||
      GameEventEffect.payFromSavings => ' · ${option.amount} монет',
      _ => '',
    };
    return RoundedSurfaceCard(
      key: ValueKey('event_option_${option.id}'),
      onTap: enabled ? onTap : null,
      semanticLabel: option.label,
      borderRadius: AppRadii.card,
      backgroundColor: enabled ? AppColors.surface : AppColors.surfaceSoft,
      borderColor: enabled ? AppColors.primaryBlueLight : AppColors.borderLight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${option.label}$price',
            style: AppTextStyles.cardTitle.copyWith(
              color: enabled ? AppColors.navy : AppColors.disabled,
            ),
          ),
          if (!enabled && shortBy > 0)
            Text(
              'Не хватает $shortBy монет',
              style: AppTextStyles.caption.copyWith(color: AppColors.pink),
            ),
        ],
      ),
    );
  }
}

class _OutcomeView extends StatelessWidget {
  const _OutcomeView({required this.outcome, required this.onDone});

  final GameEventOutcome outcome;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final changes = <String>[
      if (outcome.balanceAfter != outcome.balanceBefore)
        'Кошелёк: ${outcome.balanceBefore} → ${outcome.balanceAfter}',
      if (outcome.savingsAfter != outcome.savingsBefore)
        'Копилка: ${outcome.savingsBefore} → ${outcome.savingsAfter}',
      if (outcome.careAfter != outcome.careBefore)
        'Забота: ${outcome.careBefore} → ${outcome.careAfter}',
    ];
    return Column(
      key: const ValueKey('event_outcome'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          outcome.option.explanation,
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
        if (changes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          for (final change in changes)
            Text(
              change,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle,
            ),
        ],
        const SizedBox(height: AppSpacing.sm),
        RoundedSurfaceCard(
          backgroundColor: AppColors.backgroundLavender,
          shadows: const [],
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Text(
            '💡 ${outcome.event.advice}',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryGradientButton(
          key: const ValueKey('event_done'),
          label: 'Понятно',
          height: 56,
          onPressed: onDone,
        ),
      ],
    );
  }
}
