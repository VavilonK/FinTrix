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
import '../../../core/widgets/amount_stepper.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../../core/widgets/secondary_capsule_button.dart';
import '../../finance/presentation/financial_history_screen.dart';
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
                  width: 34,
                  height: 34,
                ),
                onSavingsTap: onOpenGoals,
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
                          _BudgetHeroBanner(age: appState.age),
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
                          const SizedBox(height: AppSpacing.xs),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SecondaryCapsuleButton(
                              key: const ValueKey('open_financial_history'),
                              label: 'История монет',
                              leading: const Icon(Icons.receipt_long_rounded),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const FinancialHistoryScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (appState.budgetPlanNeedsUpdate) ...[
                            _BudgetDifferenceCard(appState: appState),
                            const SizedBox(height: AppSpacing.sm),
                          ],
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
  const _BudgetHeroBanner({required this.age});

  final int age;

  @override
  Widget build(BuildContext context) {
    final hint = age <= 8
        ? 'Сначала отложим на важное,\nпотом выберем приятное!'
        : 'Распредели деньги так, чтобы хватило\nи на нужное, и на мечту.';
    return RoundedSurfaceCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        104,
        AppSpacing.sm,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  gradient: AppGradients.primaryCta,
                  borderRadius: AppRadii.mediumBorder,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.surface,
                  size: 42,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Мой бюджет', style: AppTextStyles.cardTitle),
                    Text(
                      'Распредели монеты с умом!',
                      style: AppTextStyles.bodySecondary.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: -98,
            bottom: -13,
            child: Image.asset(
              AppAssets.foxPeekingHappyLevel05,
              width: 108,
              height: 108,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: -100,
            top: -5,
            child: Container(
              width: 130,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceTranslucent,
                borderRadius: AppRadii.mediumBorder,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                hint,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: AppTextStyles.caption.copyWith(fontSize: 9.5),
              ),
            ),
          ),
        ],
      ),
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
        ],
      ),
    );
  }
}

class _BudgetDifferenceCard extends StatelessWidget {
  const _BudgetDifferenceCard({required this.appState});

  final AppController appState;

  @override
  Widget build(BuildContext context) {
    final difference = appState.budgetRemainingToAllocate;
    final balanceChanged = difference < 0;
    final usedToday =
        appState.budgetUsage.totalSpent + appState.budgetUsage.savingsDeposited;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: balanceChanged
            ? const Color(0xFFFFF3D8)
            : AppColors.primaryBlueLight,
        borderRadius: AppRadii.mediumBorder,
        border: Border.all(
          color: balanceChanged
              ? const Color(0xFFFFD785)
              : const Color(0xFFBADBFF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                balanceChanged
                    ? Icons.refresh_rounded
                    : Icons.tips_and_updates_rounded,
                color: balanceChanged
                    ? AppColors.orange
                    : AppColors.primaryBlue,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  balanceChanged
                      ? 'План сохранён. Сегодня уже использовано ${_formatCoins(usedToday)} монет.'
                      : 'Появилось ещё ${_formatCoins(difference)} монет. Куда их распределим?',
                  style: AppTextStyles.body.copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
          if (!balanceChanged) ...[
            const SizedBox(height: AppSpacing.xxs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('budget_reconcile'),
                onPressed: () => _showAllocateExtraSheet(context, appState),
                child: Text('Распределить ещё ${_formatCoins(difference)}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _showAllocateExtraSheet(
  BuildContext context,
  AppController appState,
) {
  final remainder = appState.budgetRemainingToAllocate;
  return showAppModalSheet<void>(
    context: context,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Куда распределим?', style: AppTextStyles.heading),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '${_formatCoins(remainder)} дополнительных монет',
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: AppSpacing.md),
        _AllocationChoice(
          key: const ValueKey('allocate_extra_essentials'),
          icon: Icons.shopping_basket_rounded,
          label: 'На важное',
          onTap: () {
            appState.allocateBudgetRemainder(BudgetCategory.essentials);
            Navigator.of(sheetContext).pop();
          },
        ),
        _AllocationChoice(
          key: const ValueKey('allocate_extra_wants'),
          icon: Icons.sports_esports_rounded,
          label: 'На приятное',
          onTap: () {
            appState.allocateBudgetRemainder(BudgetCategory.wants);
            Navigator.of(sheetContext).pop();
          },
        ),
        _AllocationChoice(
          key: const ValueKey('allocate_extra_savings'),
          icon: Icons.savings_rounded,
          label: 'На мечту',
          onTap: () {
            appState.allocateBudgetRemainder(BudgetCategory.savings);
            Navigator.of(sheetContext).pop();
          },
        ),
      ],
    ),
  );
}

class _AllocationChoice extends StatelessWidget {
  const _AllocationChoice({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: ListTile(
        minTileHeight: 58,
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryBlueLight,
          foregroundColor: AppColors.primaryBlue,
          child: Icon(icon),
        ),
        title: Text(label, style: AppTextStyles.body),
        trailing: const Icon(Icons.chevron_right_rounded),
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
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: compact ? 60 : 72,
                    height: compact ? 60 : 72,
                    padding: const EdgeInsets.all(AppSpacing.xs),
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
                            fontSize: compact ? 15 : 19,
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
                  const SizedBox(width: AppSpacing.xs),
                  AmountStepper(
                    value: amount,
                    keyPrefix: keyPrefix,
                    onDecrease: onDecrease,
                    onIncrease: onIncrease,
                  ),
                ],
              ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F8EA),
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Image.asset(
            AppAssets.foxPeekingHappyLevel05,
            width: 76,
            height: 76,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              confirmed
                  ? 'Бюджет готов! Все монеты на своих местах. ❤️'
                  : complete
                  ? 'Отлично! Все монеты нашли своё место! ❤️'
                  : 'Немного осталось — распредели все монеты.',
              style: AppTextStyles.body.copyWith(fontSize: 15),
            ),
          ),
        ],
      ),
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
