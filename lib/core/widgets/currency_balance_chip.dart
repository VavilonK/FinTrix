import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class CurrencyBalanceChip extends StatelessWidget {
  const CurrencyBalanceChip({
    required this.amount,
    this.leading,
    this.onAdd,
    this.onTap,
    this.semanticLabel,
    this.compact = false,
    super.key,
  });

  final String amount;
  final Widget? leading;
  final VoidCallback? onAdd;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel ?? 'Баланс: $amount',
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadii.capsule,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.capsule,
          child: Container(
            constraints: BoxConstraints(
              minHeight: compact ? 50 : AppSpacing.minimumTouchTarget,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 4 : AppSpacing.sm,
              vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.capsule,
              boxShadow: AppShadows.card,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: compact ? 28 : 36,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child:
                        leading ??
                        const Icon(
                          Icons.monetization_on_rounded,
                          color: AppColors.yellow,
                          size: 32,
                        ),
                  ),
                ),
                SizedBox(width: compact ? 2 : AppSpacing.xs),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      amount,
                      maxLines: 1,
                      style: AppTextStyles.balance.copyWith(
                        fontSize: compact ? 19 : 24,
                      ),
                    ),
                  ),
                ),
                if (onAdd != null) ...[
                  SizedBox(width: compact ? 0 : AppSpacing.xs),
                  _AddButton(onPressed: onAdd!, compact: compact),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed, required this.compact});

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Пополнить баланс',
      child: InkResponse(
        onTap: onPressed,
        radius: AppSpacing.lg,
        child: SizedBox.square(
          dimension: AppSpacing.minimumTouchTarget,
          child: Center(
            child: SizedBox.square(
              dimension: compact ? 26 : 30,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.addButton,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.primaryControl,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.surface,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
