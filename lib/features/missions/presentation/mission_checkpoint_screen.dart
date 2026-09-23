import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../tasks/data/location_definitions.dart';
import 'mission_task_screen.dart';
import 'widgets/location_scene_widgets.dart';

class MissionCheckpointScreen extends StatelessWidget {
  const MissionCheckpointScreen({required this.onReturnHome, super.key});

  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final mission = appState.activeMission!;
    final location = LocationDefinitions.byId(mission.locationId);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          LocationSceneBackground(
            sceneAsset: location.sceneAsset,
            overlayOpacity: 0.82,
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: RoundedSurfaceCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          AppAssets.foxPeekingHappyLevel05,
                          width: 190,
                          height: 170,
                          fit: BoxFit.contain,
                        ),
                        Text('Отлично!', style: AppTextStyles.heading),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Уже ${appState.sessionCompletedTasks} из ${mission.tasks.length}',
                          style: AppTextStyles.cardTitle,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppProgressBar(
                          value: appState.missionProgress,
                          height: 14,
                          semanticLabel: 'Промежуточный прогресс миссии',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PrimaryGradientButton(
                          key: const ValueKey('checkpoint_continue'),
                          label: 'Продолжить',
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => MissionTaskScreen(
                                  onReturnHome: onReturnHome,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
