import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';

class AmountStepper extends StatelessWidget {
  const AmountStepper({
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
    this.keyPrefix = 'amount',
    super.key,
  });

  final int value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.capsule,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            key: ValueKey('${keyPrefix}_minus'),
            icon: Icons.remove_rounded,
            onTap: onDecrease,
            isPrimary: false,
          ),
          SizedBox(
            width: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  key: ValueKey('${keyPrefix}_value'),
                  maxLines: 1,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 22),
                ),
                Text(
                  'монет',
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          _StepperButton(
            key: ValueKey('${keyPrefix}_plus'),
            icon: Icons.add_rounded,
            onTap: onIncrease,
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.isPrimary,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox.square(
      dimension: 44,
      child: Material(
        color: !enabled
            ? AppColors.track
            : isPrimary
            ? AppColors.primaryBlue
            : AppColors.backgroundLavender,
        borderRadius: AppRadii.capsule,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.capsule,
          child: Icon(
            icon,
            color: !enabled
                ? AppColors.disabled
                : isPrimary
                ? AppColors.surface
                : AppColors.primaryBlue,
            size: 26,
          ),
        ),
      ),
    );
  }
}
