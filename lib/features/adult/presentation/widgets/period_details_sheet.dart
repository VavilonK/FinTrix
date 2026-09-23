import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_modal_sheet.dart';
import '../../../periods/domain/game_period.dart';
import '../../../finance/domain/financial_transaction.dart';
import '../../../finance/presentation/financial_history_screen.dart';
import '../../../pet_progression/domain/pet_progression.dart';
import '../../../tasks/data/location_definitions.dart';

Future<void> showPeriodDetailsSheet({
  required BuildContext context,
  required GamePeriod period,
}) {
  return showAppModalSheet<void>(
    context: context,
    builder: (_) => PeriodDetailsSheet(period: period),
  );
}

class PeriodDetailsSheet extends StatelessWidget {
  const PeriodDetailsSheet({required this.period, super.key});

  final GamePeriod period;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Игровой день ${period.sequenceNumber}',
          style: AppTextStyles.heading,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          LocationDefinitions.byId(period.locationId).title,
          style: AppTextStyles.cardTitle.copyWith(color: AppColors.primaryBlue),
        ),
        Text(
          _missionThemeLabel(period.themeId),
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: AppSpacing.md),
        _DetailRow(
          label: 'Баланс',
          value:
              '${_coins(period.startingBalance)} → ${_coins(period.endingBalance)}',
        ),
        _DetailRow(
          label: 'Копилка',
          value:
              '${_coins(period.startingSavings)} → ${_coins(period.endingSavings)}',
        ),
        const Divider(height: AppSpacing.lg),
        _DetailRow(
          label: 'Заработано',
          value: '+${_coins(period.earnedCoins)}',
        ),
        _DetailRow(label: 'На важное', value: _coins(period.essentialSpent)),
        _DetailRow(label: 'На приятное', value: _coins(period.wantSpent)),
        _DetailRow(label: 'Отложено', value: _coins(period.depositedToSavings)),
        const Divider(height: AppSpacing.lg),
        _DetailRow(label: 'Задания', value: '${period.completedTaskCount}'),
        _DetailRow(
          label: 'Правильные ответы',
          value: '${period.correctTaskCount}',
        ),
        const Divider(height: AppSpacing.lg),
        _DetailRow(
          label: 'Очки развития Рыжика',
          value: '+${period.growthPointsAwarded}',
          valueColor: AppColors.purple,
        ),
        _DetailRow(
          label: 'Стадия',
          value:
              '${period.petStageAtStart.shortTitle} → ${period.petStageAtEnd.shortTitle}',
        ),
        const Divider(height: AppSpacing.lg),
        Text('Операции за этот день', style: AppTextStyles.cardTitle),
        const SizedBox(height: AppSpacing.xs),
        FutureBuilder<List<FinancialTransaction>>(
          future: state.financialTransactionsForPeriod(period.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final transactions = snapshot.data!;
            if (transactions.isEmpty) {
              return Text(
                'Подробная история этого дня недоступна.',
                style: AppTextStyles.bodySecondary,
              );
            }
            return Column(
              children: [
                for (var index = 0; index < transactions.length; index++) ...[
                  FinancialTransactionTile(
                    transaction: transactions[index],
                    showBalances: true,
                  ),
                  if (index != transactions.length - 1)
                    const Divider(height: 1, color: AppColors.borderLight),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.navy,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySecondary)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.body.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

String _missionThemeLabel(String id) => switch (id) {
  'math' => 'Математика',
  'logic' => 'Логика',
  'shopping' => 'Финансовые решения',
  'savings' => 'Накопления',
  'entertainment' => 'Развлечения',
  'mixed' => 'Смешанная тренировка',
  _ => 'Игровая тренировка',
};

String _coins(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ' ',
);
