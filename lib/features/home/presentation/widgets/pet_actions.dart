import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class PetActions extends StatelessWidget {
  const PetActions({
    required this.onFeed,
    required this.onPlay,
    required this.onPet,
    super.key,
  });

  final VoidCallback onFeed;
  final VoidCallback onPlay;
  final VoidCallback onPet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: _PetActionButton(
              key: const ValueKey('home_feed_pet'),
              label: 'Покормить',
              color: AppColors.orange,
              assetPath: AppAssets.careFoodBowl,
              onTap: onFeed,
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _PetActionButton(
              key: const ValueKey('home_play_pet'),
              label: 'Поиграть',
              color: AppColors.purple,
              assetPath: AppAssets.itemGameController,
              onTap: onPlay,
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _PetActionButton(
              key: const ValueKey('home_pet_fox'),
              label: 'Погладить',
              color: AppColors.pink,
              assetPath: AppAssets.actionPetting,
              onTap: onPet,
            ),
          ),
        ],
      ),
    );
  }
}

class _PetActionButton extends StatelessWidget {
  const _PetActionButton({
    required this.label,
    required this.color,
    this.assetPath,
    this.icon,
    required this.onTap,
    super.key,
  }) : assert(assetPath != null || icon != null);

  final String label;
  final Color color;
  final String? assetPath;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = Color.lerp(color, AppColors.surface, 0.28)!;
    final shade = Color.lerp(color, Colors.black, 0.12)!;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    // The artwork sits above the button and overlaps its top edge; the
    // overhang is reserved so the Home layout keeps its previous height.
    final iconSize = textScale >= 1.8
        ? 56.0
        : textScale >= 1.3
        ? 64.0
        : 76.0;
    final overhang = iconSize * 0.42;
    final buttonHeight = 80.0 + (textScale - 1).clamp(0.0, 1.0) * 70;

    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: buttonHeight + overhang,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              top: overhang,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [highlight, color, shade],
                    stops: const [0, 0.55, 1],
                  ),
                  borderRadius: AppRadii.actionButton,
                  border: Border.all(color: AppColors.surface.withAlpha(90)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(90),
                      offset: const Offset(0, 8),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Material(
                  color: AppColors.transparent,
                  borderRadius: AppRadii.actionButton,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: AppRadii.actionButton,
                    // Light feedback: the default dark ink reads as a black
                    // flash over the saturated button and its label.
                    splashColor: AppColors.surface.withAlpha(70),
                    highlightColor: AppColors.surface.withAlpha(40),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.xxs,
                          iconSize - overhang,
                          AppSpacing.xxs,
                          AppSpacing.xs,
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.buttonCompact.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  // No blur: a blurred text shadow flashed a black box on repaint.
                                  Shadow(
                                    color: shade.withAlpha(150),
                                    offset: const Offset(0, 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: SizedBox.square(
                    dimension: iconSize,
                    child: assetPath != null
                        ? Image.asset(assetPath!, fit: BoxFit.contain)
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Icon(
                              icon,
                              color: AppColors.surface,
                              size: 52,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
