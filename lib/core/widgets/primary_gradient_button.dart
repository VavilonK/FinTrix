import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class PrimaryGradientButton extends StatelessWidget {
  const PrimaryGradientButton({
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.isLoading = false,
    this.expand = true,
    this.height = 60,
    this.semanticLabel,
    this.contentPadding,
    this.textStyle,
    this.itemSpacing = AppSpacing.xs,
    this.maxLines = 1,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final bool isLoading;
  final bool expand;
  final double height;
  final String? semanticLabel;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? textStyle;
  final double itemSpacing;
  final int maxLines;

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final minHeight = height
        .clamp(AppSpacing.minimumTouchTarget, 72)
        .toDouble();

    final button = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _isEnabled ? null : AppColors.disabled,
          gradient: _isEnabled ? AppGradients.primaryCta : null,
          borderRadius: AppRadii.card,
          boxShadow: _isEnabled ? AppShadows.primaryControl : const [],
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: AppRadii.card,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _isEnabled ? onPressed : null,
            borderRadius: AppRadii.card,
            child: Padding(
              padding:
                  contentPadding ??
                  const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
              child: Center(
                child: isLoading
                    ? const SizedBox.square(
                        dimension: AppSpacing.lg,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.surface,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (leading != null) ...[
                            leading!,
                            SizedBox(width: itemSpacing),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              maxLines: maxLines,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle ?? AppTextStyles.button,
                            ),
                          ),
                          if (trailing != null) ...[
                            SizedBox(width: itemSpacing),
                            trailing!,
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: semanticLabel ?? label,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
