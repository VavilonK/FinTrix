import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../tasks/domain/location_definition.dart';

class LocationSceneBackground extends StatelessWidget {
  const LocationSceneBackground({
    required this.sceneAsset,
    this.overlayOpacity = 0.86,
    this.alignment = Alignment.center,
    super.key,
  });

  final String sceneAsset;
  final double overlayOpacity;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _SceneImage(sceneAsset: sceneAsset, alignment: alignment),
        LocationOverlay(opacity: overlayOpacity),
      ],
    );
  }
}

class LocationOverlay extends StatelessWidget {
  const LocationOverlay({this.opacity = 0.86, super.key});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF4F6FF).withValues(alpha: opacity - 0.08),
            const Color(0xFFF8F4FF).withValues(alpha: opacity),
          ],
        ),
      ),
    );
  }
}

class LocationHeroCard extends StatelessWidget {
  const LocationHeroCard({
    required this.location,
    required this.speech,
    this.height = 285,
    super.key,
  });

  final LocationDefinition location;
  final String speech;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            bottom: 22,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.heroCard,
                boxShadow: AppShadows.card,
                border: Border.all(color: AppColors.surface, width: 4),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _SceneImage(sceneAsset: location.sceneAsset),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.46, 1],
                        colors: [AppColors.transparent, Color(0x7A08154B)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xEFFFFFFF),
                        borderRadius: AppRadii.capsule,
                      ),
                      child: Text(
                        location.title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: -4,
            child: Image.asset(
              AppAssets.foxSittingHappyLevel05,
              width: 142,
              height: 166,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 86,
            top: 14,
            child: Container(
              width: 184,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xF2FFFFFF),
                borderRadius: AppRadii.card,
                border: Border.all(color: AppColors.surface, width: 2),
                boxShadow: AppShadows.card,
              ),
              child: Text(
                speech,
                textAlign: TextAlign.center,
                maxLines: 4,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.secondaryText,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneImage extends StatelessWidget {
  const _SceneImage({
    required this.sceneAsset,
    this.alignment = Alignment.center,
  });

  final String sceneAsset;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (sceneAsset.isEmpty) return _fallback();
    return Image.asset(
      sceneAsset,
      fit: BoxFit.cover,
      alignment: alignment,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() => Image.asset(
    AppAssets.backgroundBedroomDay,
    fit: BoxFit.cover,
    alignment: Alignment.center,
  );
}
