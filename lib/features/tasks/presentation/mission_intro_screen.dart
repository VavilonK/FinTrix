import 'package:flutter/material.dart';

import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../missions/domain/mission_models.dart';
import '../../missions/presentation/mission_task_screen.dart';
import '../../missions/presentation/widgets/location_scene_widgets.dart';
import '../data/location_definitions.dart';

class MissionIntroScreen extends StatefulWidget {
  const MissionIntroScreen({
    required this.mission,
    required this.onReturnHome,
    super.key,
  });

  final DailyMission mission;
  final VoidCallback onReturnHome;

  @override
  State<MissionIntroScreen> createState() => _MissionIntroScreenState();
}

class _MissionIntroScreenState extends State<MissionIntroScreen> {
  bool _scenePrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scenePrecached) return;
    _scenePrecached = true;
    final location = LocationDefinitions.byId(widget.mission.locationId);
    if (location.sceneAsset.isNotEmpty) {
      precacheImage(AssetImage(location.sceneAsset), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final location = LocationDefinitions.byId(widget.mission.locationId);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          LocationSceneBackground(
            sceneAsset: location.sceneAsset,
            overlayOpacity: 0.74,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          _TopButton(
                            semanticLabel: 'Назад',
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: RoundedSurfaceCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              borderRadius: AppRadii.capsule,
                              child: Text(
                                location.title,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.cardTitle,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _StreakBadge(streak: appState.streak),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.sm,
                          AppSpacing.xs,
                          AppSpacing.sm,
                          AppSpacing.sm,
                        ),
                        child: Column(
                          children: [
                            LocationHeroCard(
                              location: location,
                              height: (constraints.maxHeight * 0.42).clamp(
                                250.0,
                                318.0,
                              ),
                              speech:
                                  '${widget.mission.title}!\nПотренируемся думать\nи принимать решения!',
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _MissionIntroCard(
                              mission: widget.mission,
                              onStart: () {
                                appState.startMission(widget.mission);
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => MissionTaskScreen(
                                      onReturnHome: widget.onReturnHome,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionIntroCard extends StatelessWidget {
  const _MissionIntroCard({required this.mission, required this.onStart});

  final DailyMission mission;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return RoundedSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadii.heroCard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Сегодня:', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.xs),
          _IntroFact(
            icon: Icons.task_alt_rounded,
            text: '${mission.tasks.length} коротких заданий',
          ),
          _IntroFact(
            icon: Icons.schedule_rounded,
            text: '~${mission.estimatedMinutes} минут',
          ),
          _IntroFact(
            icon: Icons.calculate_rounded,
            text: 'Тема: ${_themeLabel(mission.theme)}',
          ),
          _IntroFact(
            icon: Icons.monetization_on_rounded,
            text: 'Награда: до ${mission.maxReward} монет',
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Будут задания на счёт, выбор и немного логики.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryGradientButton(
            key: const ValueKey('mission_start'),
            label: 'Начать',
            onPressed: onStart,
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }
}

String _themeLabel(MissionTheme theme) {
  return switch (theme) {
    MissionTheme.math => 'Математика',
    MissionTheme.logic => 'Логика',
    MissionTheme.shopping => 'Покупки',
    MissionTheme.savings => 'Накопления',
    MissionTheme.entertainment => 'Развлечения',
    MissionTheme.mixed => 'Смешанная',
  };
}

class _IntroFact extends StatelessWidget {
  const _IntroFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  const _TopButton({
    required this.semanticLabel,
    required this.icon,
    required this.onTap,
  });

  final String semanticLabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 50,
      child: RoundedSurfaceCard(
        semanticLabel: semanticLabel,
        onTap: onTap,
        padding: EdgeInsets.zero,
        borderRadius: AppRadii.capsule,
        child: Icon(icon, color: AppColors.secondaryText),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceTranslucent,
        borderRadius: AppRadii.capsule,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.orange,
          ),
          const SizedBox(width: 3),
          Text('$streak дня', style: AppTextStyles.body.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}
