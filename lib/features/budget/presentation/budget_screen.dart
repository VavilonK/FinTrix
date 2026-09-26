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
import '../../../core/widgets/app_settings_button.dart';
import '../../../core/widgets/amount_stepper.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../../core/widgets/speech_bubble.dart';
import '../../finance/presentation/financial_history_screen.dart';
import '../../home/presentation/widgets/home_sheets.dart';
import '../domain/budget_plan.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({required this.onOpenGoals, super.key});

  final VoidCallback onOpenGoals;

  static const int _step = 50;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final plan = appState.budgetPlan;

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
              colors: [Color(0xC8E8EEFF), Color(0xEDFFF4EB)],
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
                  width: 38,
                  height: 38,
                ),
                onSavingsTap: onOpenGoals,
                trailing: AppSettingsButton(
                  onPressed: () => showSettingsSheet(context),
                ),
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
                          const _BudgetHeroBanner(),
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: 'Доступно '),
                                  TextSpan(
                                    text: _formatCoins(appState.balance),
                                    style: AppTextStyles.heading.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const TextSpan(text: ' монет'),
                                ],
                              ),
                              style: AppTextStyles.sectionTitle,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _AllocationSummary(appState: appState),
                          const SizedBox(height: AppSpacing.sm),
                          RoundedSurfaceCard(
                            key: const ValueKey('open_financial_history'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const FinancialHistoryScreen(),
                              ),
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 38),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryBlueLight,
                                      borderRadius: AppRadii.mediumBorder,
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_rounded,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  const Expanded(
                                    child: Text(
                                      'История монет',
                                      style: AppTextStyles.body,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.primaryBlue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _BudgetCategoryCard(
                            title: 'На важное',
                            subtitle: 'То, без чего не обойтись',
                            amount: plan.essentialsPlanned,
                            usedAmount: appState.budgetUsage.essentialsSpent,
                            usedLabel: 'Потрачено',
                            backgroundColor: const Color(0xFFDDF1FF),
                            placeholderIcon: Icons.shopping_basket_rounded,
                            keyPrefix: 'budget_essentials',
                            confirmed: appState.budgetPlanConfirmed,
                            onDecrease: plan.essentialsPlanned >= _step
                                ? () => appState.updateBudgetCategory(
                                    BudgetCategory.essentials,
                                    -_step,
                                  )
                                : null,
                            onIncrease:
                                appState.budgetRemainingToAllocate >= _step
                                ? () => appState.updateBudgetCategory(
                                    BudgetCategory.essentials,
                                    _step,
                                  )
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _BudgetCategoryCard(
                            title: 'На приятное',
                            subtitle: 'То, что хочется',
                            amount: plan.wantsPlanned,
                            usedAmount: appState.budgetUsage.wantsSpent,
                            usedLabel: 'Потрачено',
                            backgroundColor: const Color(0xFFE9DEFF),
                            assetPath: AppAssets.itemGameController,
                            keyPrefix: 'budget_wants',
                            confirmed: appState.budgetPlanConfirmed,
                            onDecrease: plan.wantsPlanned >= _step
                                ? () => appState.updateBudgetCategory(
                                    BudgetCategory.wants,
                                    -_step,
                                  )
                                : null,
                            onIncrease:
                                appState.budgetRemainingToAllocate >= _step
                                ? () => appState.updateBudgetCategory(
                                    BudgetCategory.wants,
                                    _step,
                                  )
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _BudgetCategoryCard(
                            title: 'На мечту',
                            subtitle: 'Для большой мечты',
                            extraLabel: _goalPurposeLabel(
                              appState.selectedGoal.id,
                            ),
                            amount: plan.savingsPlanned,
                            usedAmount: appState.budgetUsage.savingsDeposited,
                            usedLabel: 'Отложено',
                            backgroundColor: const Color(0xFFE1F7E5),
                            assetPath: AppAssets.financePiggyBank,
                            keyPrefix: 'budget_savings',
                            confirmed: appState.budgetPlanConfirmed,
                            onDecrease: plan.savingsPlanned >= _step
                                ? () => appState.updateBudgetCategory(
                                    BudgetCategory.savings,
                                    -_step,
                                  )
                                : null,
                            onIncrease:
                                appState.budgetRemainingToAllocate >= _step
                                ? () => appState.updateBudgetCategory(
                                    BudgetCategory.savings,
                                    _step,
                                  )
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _FoxBudgetHint(
                            complete: appState.canConfirmBudget,
                            confirmed: appState.budgetPlanConfirmed,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          PrimaryGradientButton(
                            key: const ValueKey('budget_confirm'),
                            label: 'Подтвердить бюджет',
                            onPressed: appState.canConfirmBudget
                                ? () => _confirmBudget(context, appState)
                                : null,
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

  void _confirmBudget(BuildContext context, AppController appState) {
    if (!appState.confirmBudgetPlan()) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.mediumBorder,
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.surface),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Отлично! Теперь у каждой монетки есть план.',
                style: AppTextStyles.body.copyWith(color: AppColors.surface),
              ),
            ],
          ),
        ),
      );
  }
}

class _BudgetHeroBanner extends StatelessWidget {
  const _BudgetHeroBanner();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 360 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.2;
        final showBubble = !compact && constraints.maxWidth >= 360;
        return RoundedSurfaceCard(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            compact ? 85 : (showBubble ? 178 : 104),
            AppSpacing.sm,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      gradient: AppGradients.primaryCta,
                      borderRadius: AppRadii.mediumBorder,
                      boxShadow: AppShadows.primaryControl,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.surface,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Мой бюджет',
                          maxLines: 1,
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Распредели монеты с умом!',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                right: compact ? -82 : (showBubble ? -176 : -98),
                bottom: -13,
                child: Image.asset(
                  AppAssets.foxPeekingHappyLevel05,
                  width: compact ? 82 : (showBubble ? 96 : 108),
                  height: compact ? 82 : (showBubble ? 96 : 108),
                  fit: BoxFit.contain,
                ),
              ),
              if (showBubble)
                const Positioned(
                  right: -84,
                  top: -8,
                  width: 92,
                  child: SpeechBubble(
                    text: 'Планируй сегодня — достигай большего завтра!',
                    tail: SpeechBubbleTail.right,
                    tilt: -5,
                    padding: EdgeInsets.fromLTRB(7, 6, 5, 7),
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 10.5,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AllocationSummary extends StatelessWidget {
  const _AllocationSummary({required this.appState});

  final AppController appState;

  @override
  Widget build(BuildContext context) {
    return RoundedSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      'Распределено ${_formatCoins(appState.totalBudgetAllocated)}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: ' / ${_formatCoins(appState.balance)}',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppProgressBar(
            value: appState.budgetAllocationProgress,
            height: 14,
            foregroundColor: AppColors.green,
            semanticLabel: 'Распределение бюджета',
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            appState.budgetRemainingToAllocate > 0
                ? 'Осталось распределить ${_formatCoins(appState.budgetRemainingToAllocate)} монет'
                : appState.budgetRemainingToAllocate == 0
                ? 'Все монеты распределены ✓'
                : 'План сохранён. Сегодня уже использовано '
                      '${_formatCoins(appState.budgetUsage.totalSpent + appState.budgetUsage.savingsDeposited)} монет.',
            style: AppTextStyles.bodySmall.copyWith(
              color: appState.budgetRemainingToAllocate == 0
                  ? AppColors.green
                  : AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryCard extends StatelessWidget {
  const _BudgetCategoryCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.usedAmount,
    required this.usedLabel,
    required this.backgroundColor,
    required this.keyPrefix,
    required this.onDecrease,
    required this.onIncrease,
    required this.confirmed,
    this.assetPath,
    this.placeholderIcon,
    this.extraLabel,
  });

  final String title;
  final String subtitle;
  final String? extraLabel;
  final int amount;
  final int usedAmount;
  final String usedLabel;
  final Color backgroundColor;
  final String? assetPath;
  final IconData? placeholderIcon;
  final String keyPrefix;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    return RoundedSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 390;
          final stacked =
              constraints.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(1) >= 1.3;
          final stepper = AmountStepper(
            value: amount,
            keyPrefix: keyPrefix,
            onDecrease: onDecrease,
            onIncrease: onIncrease,
          );
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: compact ? 66 : 80,
                    height: compact ? 66 : 80,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: AppRadii.mediumBorder,
                    ),
                    child: assetPath != null
                        ? Image.asset(assetPath!, fit: BoxFit.contain)
                        : Icon(
                            placeholderIcon,
                            color: AppColors.primaryBlue,
                            size: 40,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: compact ? 16 : 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 2,
                          style: AppTextStyles.caption,
                        ),
                        if (extraLabel != null)
                          Text(
                            extraLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.green,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!stacked) ...[
                    const SizedBox(width: AppSpacing.xs),
                    stepper,
                  ],
                ],
              ),
              if (stacked) ...[
                const SizedBox(height: AppSpacing.xs),
                Align(alignment: Alignment.centerRight, child: stepper),
              ],
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      confirmed
                          ? 'План: ${_formatCoins(amount)}  •  $usedLabel: ${_formatCoins(usedAmount)}'
                          : '$usedLabel: ${_formatCoins(usedAmount)} из ${_formatCoins(amount)}',
                      style: AppTextStyles.caption.copyWith(
                        color: usedAmount > amount
                            ? AppColors.orange
                            : AppColors.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (usedAmount > amount)
                    Text(
                      'Сверх плана',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              AppProgressBar(
                value: amount <= 0
                    ? (usedAmount > 0 ? 1 : 0)
                    : (usedAmount / amount).clamp(0, 1).toDouble(),
                height: 6,
                foregroundColor: usedAmount > amount
                    ? AppColors.orange
                    : AppColors.primaryBlue,
                animationDuration: const Duration(milliseconds: 240),
                semanticLabel: '$usedLabel для категории $title',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FoxBudgetHint extends StatelessWidget {
  const _FoxBudgetHint({required this.complete, required this.confirmed});

  final bool complete;
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Image.asset(
          AppAssets.foxPeekingHappyLevel05,
          width: 104,
          height: 96,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: SpeechBubble(
              text: confirmed
                  ? 'Бюджет готов! Все монеты на своих местах!'
                  : complete
                  ? 'Отлично! Все монеты нашли своё место!'
                  : 'Немного осталось — распредели все монеты.',
              tail: SpeechBubbleTail.left,
              tilt: -3,
              showHeart: complete || confirmed,
              style: AppTextStyles.body.copyWith(fontSize: 15, height: 1.25),
            ),
          ),
        ),
      ],
    );
  }
}

String _formatCoins(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
}

String _goalPurposeLabel(String goalId) {
  return switch (goalId) {
    'bicycle' => 'На велосипед',
    'scooter' => 'На самокат',
    'building_set' => 'На конструктор',
    _ => 'На большую мечту',
  };
}
