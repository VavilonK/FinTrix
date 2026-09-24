import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class SavingsSummaryChip extends StatelessWidget {
  const SavingsSummaryChip({
    required this.amount,
    this.label = 'Копилка',
    this.leading,
    this.onTap,
    this.compact = false,
    this.showChevron = false,
    super.key,
  });

  final String amount;
  final String label;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool compact;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$label: $amount',
      child: Container(
        constraints: BoxConstraints(
          minHeight: compact ? 50 : AppSpacing.minimumTouchTarget,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.capsule,
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: AppRadii.capsule,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.capsule,
            child: Padding(
              padding: EdgeInsets.only(
                left: compact ? 6 : AppSpacing.sm,
                right: compact ? 10 : 12,
                top: compact ? AppSpacing.xxs : AppSpacing.xs,
                bottom: compact ? AppSpacing.xxs : AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  leading ??
                      Icon(
                        Icons.savings_rounded,
                        color: AppColors.pink,
                        size: compact ? 30 : 32,
                      ),
                  SizedBox(width: compact ? AppSpacing.xxs : AppSpacing.xs),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            amount,
                            maxLines: 1,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: compact ? 18 : 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showChevron) ...[
                    SizedBox(width: compact ? AppSpacing.xxs : AppSpacing.xs),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.secondaryText,
                      size: compact ? 22 : 24,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
