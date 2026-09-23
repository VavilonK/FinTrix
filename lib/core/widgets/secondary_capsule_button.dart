import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class SecondaryCapsuleButton extends StatelessWidget {
  const SecondaryCapsuleButton({
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final foreground = onPressed == null
        ? AppColors.disabled
        : AppColors.primaryBlue;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppSpacing.minimumTouchTarget,
      ),
      child: Material(
        color: AppColors.primaryBlueLight,
        borderRadius: AppRadii.capsule,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadii.capsule,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  IconTheme(
                    data: IconThemeData(color: foreground),
                    child: leading!,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(color: foreground),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  IconTheme(
                    data: IconThemeData(color: foreground),
                    child: trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: expand
          ? SizedBox(width: double.infinity, child: content)
          : content,
    );
  }
}
