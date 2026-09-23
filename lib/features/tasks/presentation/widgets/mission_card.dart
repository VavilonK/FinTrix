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
    return RoundedSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.xs),
      borderRadius: AppRadii.heroCard,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: AppRadii.mediumBorder,
                  child: Container(
                    width: 78,
                    color: AppColors.primaryBlueLight,
                    child: location.sceneAsset.isNotEmpty
                        ? Image.asset(location.sceneAsset, fit: BoxFit.cover)
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 17),
                      ),
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
                const SizedBox(width: 6),
                SizedBox(
                  width: 112,
                  child: PrimaryGradientButton(
                    label: 'Отправиться',
                    onPressed: onStartMission,
                    height: 52,
                    itemSpacing: 2,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                    textStyle: AppTextStyles.body.copyWith(
                      color: AppColors.surface,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.surface,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
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
                  backgroundColor: Color(0xFFE9F8EF),
                  iconColor: AppColors.purple,
                ),
              ),
            ],
          ),
        ],
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.navy,
                fontSize: 11.5,
                height: 1.05,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.navy,
                fontSize: 11.5,
                height: 1.05,
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
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadii.mediumBorder,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 25),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 10.2,
                height: 1.02,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
