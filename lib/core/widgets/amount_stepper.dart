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
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
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
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
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
    return Semantics(
      button: true,
      enabled: enabled,
      label: isPrimary ? 'Увеличить сумму' : 'Уменьшить сумму',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: !enabled
                    ? AppColors.track
                    : isPrimary
                    ? null
                    : const Color(0xFFE3E7F8),
                gradient: enabled && isPrimary ? AppGradients.addButton : null,
                shape: BoxShape.circle,
                boxShadow: enabled && isPrimary
                    ? AppShadows.primaryControl
                    : null,
              ),
              child: Icon(
                icon,
                color: !enabled
                    ? AppColors.disabled
                    : isPrimary
                    ? AppColors.surface
                    : AppColors.secondaryText,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
