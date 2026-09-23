import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/account_header.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../play/presentation/play_hub_screen.dart';
import '../../pet_progression/presentation/pet_visual_resolver.dart';
import 'widgets/home_goal_card.dart';
import 'widgets/home_sheets.dart';
import 'widgets/home_task_card.dart';
import 'widgets/pet_actions.dart';
import 'widgets/pet_stage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.onOpenTasks,
    required this.onOpenBudget,
    required this.onOpenGoals,
    super.key,
  });

  final VoidCallback onOpenTasks;
  final VoidCallback onOpenBudget;
  final VoidCallback onOpenGoals;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPetting = false;
  int _pettingSequence = 0;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final pet = appState.petState;
    final hungry = pet.satiety < 30;
    final foxAsset = PetVisualResolver.assetFor(
      stage: appState.petGrowthStage,
      emotionalState: _isPetting
          ? PetEmotionalState.loved
          : hungry
          ? PetEmotionalState.hungry
          : PetEmotionalState.happy,
      context: PetVisualContext.home,
    );
    final message = _isPetting
        ? (_pettingSequence.isEven
              ? 'Спасибо за заботу!'
              : 'Мне очень приятно!')
        : hungry
        ? (_pettingSequence.isEven
              ? 'Кажется, я проголодался...'
              : 'Может, перекусим?')
        : 'Финансовые приключения вместе!';

    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.translate(
          offset: const Offset(0, 20),
          child: Transform.scale(
            scale: 1.06,
            child: Image.asset(
              AppAssets.backgroundBedroomDay,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundHighlight,
                AppColors.backgroundHighlightSoft,
              ],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stageHeight = (constraints.maxHeight - 390)
                  .clamp(238.0, 320.0)
                  .toDouble();

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
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
                        onBalanceTap: () => showBalanceSummarySheet(
                          context: context,
                          onOpenBudget: widget.onOpenBudget,
                          onOpenTasks: widget.onOpenTasks,
                          onOpenGoals: widget.onOpenGoals,
                        ),
                        onAddBalance: () => showQuickActionsSheet(
                          context: context,
                          onOpenTasks: widget.onOpenTasks,
                          onOpenBudget: widget.onOpenBudget,
                          onOpenGoals: widget.onOpenGoals,
                        ),
                        onSavingsTap: widget.onOpenGoals,
                        trailing: _SettingsButton(
                          onTap: () => showSettingsSheet(context),
                        ),
                        useSafeArea: false,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            (constraints.maxWidth * 0.035)
                                .clamp(AppSpacing.sm, AppSpacing.md)
                                .toDouble(),
                            0,
                            (constraints.maxWidth * 0.035)
                                .clamp(AppSpacing.sm, AppSpacing.md)
                                .toDouble(),
                            AppSpacing.xs,
                          ),
                          child: Column(
                            children: [
                              HomeGoalCard(
                                savings: appState.savings,
                                goal: appState.selectedGoal,
                                completed: appState.isSelectedGoalCompleted,
                                onTap: widget.onOpenGoals,
                              ),
                              const Spacer(),
                              PetStage(
                                key: ValueKey(_pettingSequence),
                                height: stageHeight,
                                mood: pet.mood,
                                satiety: pet.satiety,
                                care: pet.care,
                                foxAsset: foxAsset,
                                message: message,
                                showHearts: _isPetting,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              PetActions(
                                onFeed: () => showFeedPetSheet(
                                  context: context,
                                  onOpenTasks: widget.onOpenTasks,
                                ),
                                onPlay: _openPlayHub,
                                onPet: _petFox,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              HomeTaskCard(onPressed: widget.onOpenTasks),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openPlayHub() {
    AppScope.of(context).refreshPetState();
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const PlayHubScreen()));
  }

  Future<void> _petFox() async {
    AppScope.of(context).petFox();
    setState(() {
      _isPetting = true;
      _pettingSequence += 1;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (mounted) setState(() => _isPetting = false);
  }
}

String _formatCoins(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 50,
      child: RoundedSurfaceCard(
        padding: EdgeInsets.zero,
        borderRadius: AppRadii.capsule,
        shadows: AppShadows.card,
        semanticLabel: 'Настройки',
        onTap: onTap,
        child: const Icon(
          Icons.settings_rounded,
          color: AppColors.secondaryText,
          size: 28,
        ),
      ),
    );
  }
}
