import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/widgets/rounded_surface_card.dart';
import '../../../missions/domain/mission_models.dart';
import '../../domain/location_definition.dart';

class MissionCard extends StatelessWidget {
  const MissionCard({
    required this.mission,
    required this.location,
    required this.onStartMission,
    super.key,
  });

  final DailyMission mission;
  final LocationDefinition location;
  final VoidCallback onStartMission;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return RoundedSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.xs),
      borderRadius: AppRadii.heroCard,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Geometry from abdfc6e: 78px image, 112px CTA, 94px top row.
          // Give readable metadata more room on narrower screens / larger text.
          final thumbnailSize = constraints.maxWidth >= 370 && textScale <= 1.3
              ? 78.0
              : constraints.maxWidth >= 345 && textScale <= 1.3
              ? 68.0
              : 54.0;
          final imageGap = constraints.maxWidth < 345 ? 4.0 : AppSpacing.xs;
          return SingleChildScrollView(
            child: Column(
              children: [
                IntrinsicHeight(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 94),
                    child: Row(
                      key: const ValueKey('mission_main'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: ClipRRect(
                            borderRadius: AppRadii.mediumBorder,
                            child: Container(
                              key: const ValueKey('mission_thumbnail'),
                              width: thumbnailSize,
                              height: thumbnailSize,
                              color: AppColors.primaryBlueLight,
                              child: location.sceneAsset.isNotEmpty
                                  ? Image.asset(
                                      location.sceneAsset,
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(
                                      _locationIcon(location.id),
                                      color: AppColors.primaryBlue,
                                      size: 42,
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(width: imageGap),
                        Expanded(
                          child: Column(
                            key: const ValueKey('mission_metadata'),
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location.title,
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const _MissionFact(
                                icon: Icons.calendar_today_rounded,
                                label: 'Сегодня',
                              ),
                              _MissionFact(
                                icon: Icons.check_circle_rounded,
                                label:
                                    '${mission.tasks.length} заданий • ~${mission.estimatedMinutes}\u00a0мин',
                                color: AppColors.green,
                              ),
                              _RewardFact(maxReward: mission.maxReward),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: constraints.maxWidth >= 370 ? 120 : 108,
                          child: Center(
                            child: _MissionStartButton(
                              onPressed: onStartMission,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    key: const ValueKey('mission_categories'),
                    children: [
                      Expanded(
                        child: _MissionStep(
                          icon: _themeIcon(mission.primaryTaskTheme),
                          label: _themeLabel(mission.primaryTaskTheme),
                          backgroundColor: const Color(0xFFFFE8F3),
                          iconColor: AppColors.orange,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _MissionStep(
                          icon: _themeIcon(mission.secondaryTaskTheme),
                          label: _themeLabel(mission.secondaryTaskTheme),
                          backgroundColor: const Color(0xFFE2F6FF),
                          iconColor: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _MissionStep(
                          icon: Icons.monetization_on_rounded,
                          label: 'до +${mission.maxReward}',
                          backgroundColor: const Color(0xFFE9F8EF),
                          iconColor: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _themeLabel(TaskTheme theme) => switch (theme) {
  TaskTheme.math => 'Математика',
  TaskTheme.logic => 'Логика',
  TaskTheme.finance => 'Финансы',
  TaskTheme.attention => 'Внимание',
  TaskTheme.memory => 'Память',
  TaskTheme.entertainment => 'Игра',
};

IconData _themeIcon(TaskTheme theme) => switch (theme) {
  TaskTheme.math => Icons.calculate_rounded,
  TaskTheme.logic => Icons.psychology_rounded,
  TaskTheme.finance => Icons.account_balance_wallet_rounded,
  TaskTheme.attention => Icons.visibility_rounded,
  TaskTheme.memory => Icons.extension_rounded,
  TaskTheme.entertainment => Icons.celebration_rounded,
};

IconData _locationIcon(String id) => switch (id) {
  'school' => Icons.school_rounded,
  'canteen' => Icons.restaurant_rounded,
  'stationery_store' => Icons.edit_note_rounded,
  'supermarket' => Icons.shopping_basket_rounded,
  'amusement_park' => Icons.attractions_rounded,
  'cinema' => Icons.movie_rounded,
  'museum' => Icons.museum_rounded,
  'library' => Icons.local_library_rounded,
  'transport_hub' => Icons.directions_subway_rounded,
  'sports_center' => Icons.sports_soccer_rounded,
  'science_center' => Icons.science_rounded,
  _ => Icons.sports_esports_rounded,
};

class _MissionFact extends StatelessWidget {
  const _MissionFact({
    required this.icon,
    required this.label,
    this.color = AppColors.secondaryText,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.navy,
                fontSize: 13,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardFact extends StatelessWidget {
  const _RewardFact({required this.maxReward});

  final int maxReward;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Image.asset(
            AppAssets.financeCoinSingle,
            width: 15,
            height: 15,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Награда: до $maxReward монет',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.navy,
                fontSize: 13,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionStep extends StatelessWidget {
  const _MissionStep({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadii.mediumBorder,
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withAlpha(50),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// The original tall right-hand control, with readable text instead of the old
// 12.5px label. The arrow follows the label vertically to retain its 112px width.
class _MissionStartButton extends StatelessWidget {
  const _MissionStartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('mission_start'),
      button: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppGradients.primaryCta,
          borderRadius: AppRadii.capsule,
          boxShadow: AppShadows.primaryControl,
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: AppRadii.capsule,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Отправиться',
                          maxLines: 1,
                          style: AppTextStyles.buttonCompact.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.surface,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
