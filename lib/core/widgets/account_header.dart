import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'avatar_level_badge.dart';
import 'currency_balance_chip.dart';
import 'savings_summary_chip.dart';

class AccountHeader extends StatelessWidget {
  const AccountHeader({
    required this.avatar,
    required this.levelLabel,
    required this.balance,
    required this.savings,
    this.onAddBalance,
    this.onBalanceTap,
    this.onSavingsTap,
    this.balanceLeading,
    this.savingsLeading,
    this.showSavingsChevron = true,
    this.trailing,
    this.useSafeArea = true,
    super.key,
  });

  final Widget avatar;
  final String levelLabel;
  final String balance;
  final String savings;
  final VoidCallback? onAddBalance;
  final VoidCallback? onBalanceTap;
  final VoidCallback? onSavingsTap;
  final Widget? balanceLeading;
  final Widget? savingsLeading;
  final bool showSavingsChevron;
  final Widget? trailing;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final compact = width < 520;
        final extremelyNarrow = width < 400;
        final enlargedText = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
        final horizontalPadding = compact
            ? AppSpacing.xs
            : AppSpacing.screenHorizontal(width);
        final avatarSize = compact
            ? (width * 0.13).clamp(50, 56).toDouble()
            : (width * 0.15).clamp(52, 64).toDouble();
        final gap = compact ? 5.0 : AppSpacing.sm;

        final avatarBadge = AvatarLevelBadge(
          avatar: avatar,
          levelLabel: levelLabel,
          size: avatarSize,
          compact: compact,
        );
        final balanceChip = CurrencyBalanceChip(
          amount: balance,
          leading: balanceLeading,
          onAdd: onAddBalance,
          onTap: onBalanceTap,
          compact: compact,
        );
        final savingsChip = SavingsSummaryChip(
          amount: savings,
          leading: savingsLeading,
          onTap: onSavingsTap,
          compact: compact,
          showChevron: showSavingsChevron,
        );

        final headerContent = extremelyNarrow || enlargedText
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatarBadge,
                  SizedBox(width: gap),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(width: double.infinity, child: balanceChip),
                        const SizedBox(height: AppSpacing.xs),
                        SizedBox(width: double.infinity, child: savingsChip),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    SizedBox(width: gap),
                    _HeaderTrailing(child: trailing!),
                  ],
                ],
              )
            : Row(
                children: [
                  avatarBadge,
                  SizedBox(width: gap),
                  Expanded(flex: 7, child: balanceChip),
                  SizedBox(width: gap),
                  Expanded(flex: 7, child: savingsChip),
                  if (trailing != null) ...[
                    SizedBox(width: gap),
                    _HeaderTrailing(child: trailing!),
                  ],
                ],
              );

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: compact ? AppSpacing.xs : AppSpacing.sm,
          ),
          child: headerContent,
        );
      },
    );

    return useSafeArea ? SafeArea(bottom: false, child: content) : content;
  }
}

class _HeaderTrailing extends StatelessWidget {
  const _HeaderTrailing({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppSpacing.minimumTouchTarget,
        minHeight: AppSpacing.minimumTouchTarget,
      ),
      child: child,
    );
  }
}
