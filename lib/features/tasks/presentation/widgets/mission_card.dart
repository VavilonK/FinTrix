import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
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
          final thumbnailSize = (constraints.maxWidth * 0.21 / textScale).clamp(
            textScale > 1.3 ? 48.0 : 68.0,
            76.0,
          );
          final actionWidth = (constraints.maxWidth * 0.42).clamp(136.0, 144.0);
          return SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
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
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        key: const ValueKey('mission_metadata'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(location.title, style: AppTextStyles.label),
                          const SizedBox(height: 3),
                          const _MissionFact(
                            icon: Icons.calendar_today_rounded,
                            label: 'Сегодня',
                          ),
                          _MissionFact(
                            icon: Icons.check_circle_rounded,
                            label:
                                '${mission.tasks.length} заданий • ~${mission.estimatedMinutes} мин',
                            color: AppColors.green,
                          ),
                          _RewardFact(maxReward: mission.maxReward),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SizedBox(
                      width: actionWidth,
                      child: PrimaryGradientButton(
                        key: const ValueKey('mission_start'),
                        label: 'Отправиться',
                        onPressed: onStartMission,
                        height: 52,
                        maxLines: null,
                        textOverflow: TextOverflow.clip,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxs,
                          vertical: 8,
                        ),
                        itemSpacing: 2,
                        textStyle: AppTextStyles.buttonCompact,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.surface,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
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
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: _MissionStep(
                          icon: _themeIcon(mission.secondaryTaskTheme),
                          label: _themeLabel(mission.secondaryTaskTheme),
                          backgroundColor: const Color(0xFFE2F6FF),
                          iconColor: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
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
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy),
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
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy),
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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Container(
      constraints: BoxConstraints(minHeight: textScale >= 1.5 ? 118 : 72),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadii.mediumBorder,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 23),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.navy),
          ),
        ],
      ),
    );
  }
}
