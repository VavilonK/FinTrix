import 'package:flutter/material.dart';

import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../domain/financial_transaction.dart';

class FinancialHistoryScreen extends StatefulWidget {
  const FinancialHistoryScreen({this.adultView = false, super.key});

  final bool adultView;

  @override
  State<FinancialHistoryScreen> createState() => _FinancialHistoryScreenState();
}

class _FinancialHistoryScreenState extends State<FinancialHistoryScreen> {
  FinancialTransactionType? _filter;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLavender,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        title: Text(
          widget.adultView ? 'История операций' : 'История монет',
          style: AppTextStyles.cardTitle,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        color: AppColors.yellow,
                        size: 34,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          widget.adultView
                              ? 'Посмотрим, откуда приходили и куда уходили монеты.'
                              : 'Посмотрим, куда приходили и уходили монетки',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Все',
                        selected: _filter == null,
                        onTap: () => setState(() => _filter = null),
                      ),
                      _FilterChip(
                        label: 'Получено',
                        selected: _filter == FinancialTransactionType.earning,
                        onTap: () => setState(
                          () => _filter = FinancialTransactionType.earning,
                        ),
                      ),
                      _FilterChip(
                        label: 'Важное',
                        selected:
                            _filter ==
                            FinancialTransactionType.essentialExpense,
                        onTap: () => setState(
                          () => _filter =
                              FinancialTransactionType.essentialExpense,
                        ),
                      ),
                      _FilterChip(
                        label: 'Приятное',
                        selected:
                            _filter == FinancialTransactionType.wantExpense,
                        onTap: () => setState(
                          () => _filter = FinancialTransactionType.wantExpense,
                        ),
                      ),
                      _FilterChip(
                        label: 'В копилку',
                        selected:
                            _filter == FinancialTransactionType.savingsDeposit,
                        onTap: () => setState(
                          () =>
                              _filter = FinancialTransactionType.savingsDeposit,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<FinancialTransaction>>(
                    future: state.recentFinancialTransactions(
                      limit: 100,
                      type: _filter,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final transactions = snapshot.data!;
                      if (transactions.isEmpty) {
                        return const _EmptyHistory();
                      }
                      final groups = _groupTransactions(
                        transactions,
                        isDemo: state.isDemoMode,
                        periodNumbers: {
                          for (final period in [
                            ...state.completedGamePeriods,
                            if (state.activeGamePeriod != null)
                              state.activeGamePeriod!,
                          ])
                            period.id: period.sequenceNumber,
                        },
                      );
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.sm,
                          AppSpacing.xs,
                          AppSpacing.sm,
                          AppSpacing.lg,
                        ),
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups.entries.elementAt(index);
                          return _TransactionGroup(
                            title: group.key,
                            transactions: group.value,
                            adultView: widget.adultView,
                          );
                        },
                      );
                    },
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

class FinancialTransactionTile extends StatelessWidget {
  const FinancialTransactionTile({
    required this.transaction,
    this.showBalances = false,
    super.key,
  });

  final FinancialTransaction transaction;
  final bool showBalances;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(transaction.type);
    final sign = switch (transaction.type) {
      FinancialTransactionType.earning => '+',
      FinancialTransactionType.savingsDeposit => '→ ',
      FinancialTransactionType.savingsWithdrawal => '← ',
      FinancialTransactionType.goalPurchase => '−',
      FinancialTransactionType.essentialExpense ||
      FinancialTransactionType.wantExpense => '−',
    };
    return Semantics(
      label:
          '${transaction.title}. ${visual.semanticLabel}. ${transaction.amount} монет',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: visual.background,
              foregroundColor: visual.foreground,
              child: Icon(visual.icon, size: 24),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.title, style: AppTextStyles.body),
                  Text(
                    _categoryLabel(transaction),
                    style: AppTextStyles.caption,
                  ),
                  if (showBalances && transaction.description != null)
                    Text(
                      transaction.description!,
                      style: AppTextStyles.bodySmall,
                    ),
                  if (showBalances)
                    Text(
                      _balanceChange(transaction),
                      style: AppTextStyles.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$sign${_coins(transaction.amount)}',
              style: AppTextStyles.body.copyWith(
                color: visual.foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionGroup extends StatelessWidget {
  const _TransactionGroup({
    required this.title,
    required this.transactions,
    required this.adultView,
  });

  final String title;
  final List<FinancialTransaction> transactions;
  final bool adultView;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xs,
              6,
            ),
            child: Text(title, style: AppTextStyles.cardTitle),
          ),
          RoundedSurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Column(
              children: [
                for (var index = 0; index < transactions.length; index++) ...[
                  FinancialTransactionTile(
                    transaction: transactions[index],
                    showBalances: adultView,
                  ),
                  if (index != transactions.length - 1)
                    const Divider(height: 1, color: AppColors.borderLight),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryBlueLight,
        side: BorderSide(
          color: selected ? AppColors.primaryBlue : AppColors.borderLight,
        ),
        labelStyle: AppTextStyles.caption.copyWith(
          color: selected ? AppColors.primaryBlue : AppColors.secondaryText,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: RoundedSurfaceCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.yellow,
                size: 52,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('История пока пуста', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Выполняй задания, заботься о Рыжике и копи на мечту — здесь появится история.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Map<String, List<FinancialTransaction>> _groupTransactions(
  List<FinancialTransaction> transactions, {
  required bool isDemo,
  required Map<String, int> periodNumbers,
}) {
  final groups = <String, List<FinancialTransaction>>{};
  final today = DateTime.now();
  for (final transaction in transactions) {
    final title = isDemo
        ? 'День ${periodNumbers[transaction.gamePeriodId] ?? '—'}'
        : _dateGroupTitle(transaction.createdAt, today);
    groups.putIfAbsent(title, () => []).add(transaction);
  }
  return groups;
}

String _dateGroupTitle(DateTime value, DateTime today) {
  final date = DateTime(value.year, value.month, value.day);
  final current = DateTime(today.year, today.month, today.day);
  final difference = current.difference(date).inDays;
  if (difference == 0) return 'Сегодня';
  if (difference == 1) return 'Вчера';
  const months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  return '${value.day} ${months[value.month - 1]}';
}

({IconData icon, Color foreground, Color background, String semanticLabel})
_visualFor(FinancialTransactionType type) => switch (type) {
  FinancialTransactionType.earning => (
    icon: Icons.add_circle_rounded,
    foreground: const Color(0xFF218A3B),
    background: const Color(0xFFE2F7E7),
    semanticLabel: 'получено',
  ),
  FinancialTransactionType.essentialExpense => (
    icon: Icons.shopping_basket_rounded,
    foreground: AppColors.primaryBlue,
    background: AppColors.primaryBlueLight,
    semanticLabel: 'потрачено на важное',
  ),
  FinancialTransactionType.wantExpense => (
    icon: Icons.sports_esports_rounded,
    foreground: AppColors.purple,
    background: const Color(0xFFEDE5FF),
    semanticLabel: 'потрачено на приятное',
  ),
  FinancialTransactionType.savingsDeposit => (
    icon: Icons.savings_rounded,
    foreground: const Color(0xFF218A3B),
    background: const Color(0xFFE2F7E7),
    semanticLabel: 'отложено в копилку',
  ),
  FinancialTransactionType.savingsWithdrawal => (
    icon: Icons.outbox_rounded,
    foreground: AppColors.orange,
    background: const Color(0xFFFFF3D8),
    semanticLabel: 'взято из копилки',
  ),
  FinancialTransactionType.goalPurchase => (
    icon: Icons.emoji_events_rounded,
    foreground: AppColors.purple,
    background: const Color(0xFFEDE5FF),
    semanticLabel: 'накопления использованы на мечту',
  ),
};

String _balanceChange(FinancialTransaction transaction) {
  if (transaction.balanceBefore != transaction.balanceAfter) {
    return 'Баланс: ${_coins(transaction.balanceBefore)} → ${_coins(transaction.balanceAfter)}';
  }
  return 'Копилка: ${_coins(transaction.savingsBefore)} → ${_coins(transaction.savingsAfter)}';
}

String _categoryLabel(FinancialTransaction transaction) =>
    switch (transaction.type) {
      FinancialTransactionType.earning => switch (transaction.source) {
        FinancialTransactionSource.mission => 'Задание',
        FinancialTransactionSource.miniGame => 'Мини-игра',
        FinancialTransactionSource.petCare => 'Забота о Рыжике',
        FinancialTransactionSource.savings => 'Накопления',
        FinancialTransactionSource.system => 'Награда',
      },
      FinancialTransactionType.essentialExpense => 'На важное',
      FinancialTransactionType.wantExpense => 'На приятное',
      FinancialTransactionType.savingsDeposit => 'В копилку',
      FinancialTransactionType.savingsWithdrawal => 'Из копилки',
      FinancialTransactionType.goalPurchase => 'Мечта достигнута',
    };

String _coins(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ' ',
);
