import 'package:flutter/material.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../events/domain/game_event.dart';
import '../../pet_progression/domain/pet_progression.dart';
import '../../pet_progression/presentation/pet_visual_resolver.dart';
import '../data/demo_period_definitions.dart';
import 'period_summary_screen.dart';

/// Demo tools for showing every feature quickly: Рыжик's growth stage, any
/// game day, hunger, test coins and the end-of-day summary.
Future<void> showDemoControlSheet(BuildContext context) {
  return showAppModalSheet<void>(
    context: context,
    builder: (sheetContext) => DemoControlSheet(
      onDayOpened: (day) {
        Navigator.of(sheetContext).pop();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Открыт день $day')));
      },
      onFinishDay: () {
        Navigator.of(sheetContext).pop();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PeriodSummaryScreen(onReturnHome: () {}),
          ),
        );
      },
    ),
  );
}

/// What each demo day shows, for the day picker.
String demoDayDescription(int day) {
  final event = GameEvents.demoSchedule[day];
  final base = switch (day) {
    1 => 'Школа · математика и логика',
    2 => 'Игровой центр · логика',
    3 => 'Супермаркет · покупки',
    4 => 'Музей · память и внимание',
    _ => 'Научный центр · всё вместе',
  };
  if (event == null) return base;
  return '$base · событие «${GameEvents.of(event).title}»';
}

class DemoControlSheet extends StatelessWidget {
  const DemoControlSheet({
    required this.onDayOpened,
    required this.onFinishDay,
    super.key,
  });

  final ValueChanged<int> onDayOpened;
  final VoidCallback onFinishDay;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final hungry = state.petState.isHungry;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Панель демо',
          textAlign: TextAlign.center,
          style: AppTextStyles.sectionTitle.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        const Text(
          'Меняй возраст Рыжика и игровые дни, чтобы посмотреть все функции.',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.md),
        const _SectionTitle('Возраст Рыжика'),
        Row(
          children: [
            for (final stage in PetGrowthStage.values) ...[
              if (stage != PetGrowthStage.values.first)
                const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _StageOption(
                  stage: stage,
                  selected: state.petGrowthStage == stage,
                  onTap: () => state.setDemoGrowthStage(stage),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const _SectionTitle('Игровой день'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var day = 1; day <= DemoPeriodDefinitions.count; day++)
              _DayOption(
                day: day,
                selected: state.demoPeriodIndex == day,
                onTap: () => _openDay(context, state, day),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Сейчас: день ${state.demoPeriodIndex} · '
          '${demoDayDescription(state.demoPeriodIndex)}',
          key: const ValueKey('demo_day_description'),
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.xxs),
        const Text(
          'Выбранный день начнётся сначала.',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.md),
        const _SectionTitle('Быстрые действия'),
        _DemoAction(
          key: const ValueKey('demo_toggle_hungry'),
          icon: hungry
              ? Icons.restaurant_rounded
              : Icons.sentiment_dissatisfied_rounded,
          color: AppColors.orange,
          label: hungry ? 'Накормить Рыжика' : 'Сделать Рыжика голодным',
          onTap: () => state.setDemoHungry(!hungry),
        ),
        _DemoAction(
          key: const ValueKey('demo_add_coins'),
          icon: Icons.add_circle_rounded,
          color: AppColors.green,
          label: 'Добавить 500 монет',
          onTap: () => state.addDemoCoins(500),
        ),
        _DemoAction(
          key: const ValueKey('demo_finish_day'),
          icon: Icons.flag_rounded,
          color: AppColors.purple,
          label: 'Завершить день и открыть итоги',
          onTap: () {
            state.completeCurrentPeriod();
            onFinishDay();
          },
        ),
      ],
    );
  }

  Future<void> _openDay(
    BuildContext context,
    AppController state,
    int day,
  ) async {
    final opened = await state.jumpToDemoDay(day);
    if (opened) onDayOpened(day);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: AppTextStyles.cardTitle),
    );
  }
}

class _StageOption extends StatelessWidget {
  const _StageOption({
    required this.stage,
    required this.selected,
    required this.onTap,
  });

  final PetGrowthStage stage;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RoundedSurfaceCard(
      key: ValueKey('demo_stage_${stage.name}'),
      onTap: onTap,
      semanticLabel: stage.title,
      padding: const EdgeInsets.all(AppSpacing.xs),
      backgroundColor: selected
          ? AppColors.primaryBlueLight
          : AppColors.surface,
      borderColor: selected ? AppColors.primaryBlue : AppColors.borderLight,
      child: Column(
        children: [
          SizedBox(
            height: 64,
            child: Image.asset(
              PetVisualResolver.assetFor(
                stage: stage,
                emotionalState: PetEmotionalState.happy,
                context: PetVisualContext.profile,
              ),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              stage.shortTitle,
              style: AppTextStyles.label.copyWith(
                color: selected ? AppColors.primaryBlue : AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayOption extends StatelessWidget {
  const _DayOption({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasEvent = GameEvents.demoSchedule.containsKey(day);
    return Semantics(
      button: true,
      selected: selected,
      label: 'День $day',
      child: Material(
        color: selected ? AppColors.primaryBlue : AppColors.backgroundLavender,
        shape: const CircleBorder(),
        child: InkWell(
          key: ValueKey('demo_day_$day'),
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$day',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: selected ? AppColors.surface : AppColors.navy,
                  ),
                ),
                if (hasEvent)
                  Positioned(
                    top: 6,
                    right: 8,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoAction extends StatelessWidget {
  const _DemoAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
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
      borderRadius: AppRadii.mediumBorder,
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
      ),
    );
  }
}
