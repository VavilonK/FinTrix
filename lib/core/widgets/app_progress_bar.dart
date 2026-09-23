import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    this.height = 14,
    this.foregroundColor = AppColors.green,
    this.trackColor = AppColors.track,
    this.gradient,
    this.animationDuration = const Duration(milliseconds: 350),
    this.semanticLabel,
    super.key,
  });

  final double value;
  final double height;
  final Color foregroundColor;
  final Color trackColor;
  final Gradient? gradient;
  final Duration animationDuration;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = value.clamp(0.0, 1.0).toDouble();

    return Semantics(
      label: semanticLabel,
      value: '${(normalizedValue * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: normalizedValue),
        duration: animationDuration,
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, _) {
          return Container(
            height: height.clamp(6, 24).toDouble(),
            decoration: const BoxDecoration(borderRadius: AppRadii.capsule)
                .copyWith(color: trackColor),
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.antiAlias,
            child: FractionallySizedBox(
              widthFactor: animatedValue,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: gradient == null ? foregroundColor : null,
                  gradient: gradient,
                  borderRadius: AppRadii.capsule,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
