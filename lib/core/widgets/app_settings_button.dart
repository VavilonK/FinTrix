import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import 'rounded_surface_card.dart';

class AppSettingsButton extends StatelessWidget {
  const AppSettingsButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 50,
      child: RoundedSurfaceCard(
        padding: EdgeInsets.zero,
        borderRadius: AppRadii.capsule,
        shadows: AppShadows.card,
        semanticLabel: 'Настройки',
        onTap: onPressed,
        child: const Icon(
          Icons.settings_rounded,
          color: AppColors.secondaryText,
          size: 28,
        ),
      ),
    );
  }
}
