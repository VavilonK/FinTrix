import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/account_header.dart';
import '../../missions/presentation/mission_complete_screen.dart';
import '../../missions/presentation/mission_result_screen.dart';
import '../../missions/presentation/mission_task_screen.dart';
import '../../periods/data/demo_period_definitions.dart';
import 'mission_intro_screen.dart';
import 'widgets/moscow_map_stage.dart';
import 'widgets/tasks_hero_banner.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({
    required this.onReturnHome,
    required this.onOpenGoals,
    super.key,
  });

  final VoidCallback onReturnHome;
  final VoidCallback onOpenGoals;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final mission = appState.missionForToday();

    return LayoutBuilder(
      builder: (context, constraints) {
        final topOverlayHeight =
            MediaQuery.paddingOf(context).top +
            (appState.isDemoMode ? 202 : 172);
        return Stack(
          fit: StackFit.expand,
          children: [
            MoscowMapStage(
              mission: mission,
              topOverlayHeight: topOverlayHeight,
              visitedLocationIds: appState.lastLocationIds.toSet(),
              onStartMission: () {
                if (appState.isCurrentPeriodCompleted) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          MissionCompleteScreen(onReturnHome: onReturnHome),
                    ),
                  );
                  return;
                }
                final activeMission = appState.activeMission;
                if (activeMission != null) {
                  final Widget destination;
                  if (appState.awaitingMissionAdvance &&
                      appState.lastResult != null) {
                    destination = MissionResultScreen(
                      onReturnHome: onReturnHome,
                    );
                  } else if (appState.currentTask == null) {
                    destination = MissionCompleteScreen(
                      onReturnHome: onReturnHome,
                    );
                  } else {
                    destination = MissionTaskScreen(onReturnHome: onReturnHome);
                  }
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => destination));
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MissionIntroScreen(
                      mission: mission,
                      onReturnHome: onReturnHome,
                    ),
                  ),
                );
              },
            ),
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AccountHeader(
                        avatar: Image.asset(
                          AppAssets.avatarChildDefault,
                          fit: BoxFit.cover,
                        ),
                        levelLabel: 'Ур. ${appState.petLevel}',
                        balance: _formatCoins(appState.balance),
                        savings: _formatCoins(appState.savings),
                        balanceLeading: Image.asset(
                          AppAssets.financeCoinSingle,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                        savingsLeading: Image.asset(
                          AppAssets.financePiggyBank,
                          width: 34,
                          height: 34,
                          fit: BoxFit.contain,
                        ),
                        onAddBalance: () {},
                        onSavingsTap: onOpenGoals,
                        trailing: _StreakChip(streak: appState.streak),
                        useSafeArea: false,
                      ),
                      if (appState.isDemoMode)
                        Container(
                          key: const ValueKey('tasks_demo_badge'),
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.purple,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Демо • День ${appState.demoPeriodIndex} из '
                            '${DemoPeriodDefinitions.count}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: TasksHeroBanner(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surfaceTranslucent,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            offset: Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.orange,
            size: 22,
          ),
          Text(
            '$streak дня',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 10.5,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCoins(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
}
