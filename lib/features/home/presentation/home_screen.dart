import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/account_header.dart';
import '../../../core/widgets/app_settings_button.dart';
import '../../play/presentation/play_hub_screen.dart';
import '../../pet_progression/presentation/pet_visual_resolver.dart';
import 'pet_animation/pet_animation_coordinator.dart';
import 'pet_animation/pet_animation_models.dart';
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
    this.isActive = true,
    super.key,
  });

  final VoidCallback onOpenTasks;
  final VoidCallback onOpenBudget;
  final VoidCallback onOpenGoals;
  final bool isActive;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isPetting = false;
  int _pettingSequence = 0;
  PetAnimationCoordinator? _animation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs whenever AppScope notifies: satiety decay, feeding, restore,
    // period end or a reset all flow into the visual base state from here.
    final base = PetBaseState.of(AppScope.of(context).petState);
    final animationsEnabled = !MediaQuery.disableAnimationsOf(context);
    final animation = _animation ??= PetAnimationCoordinator(
      baseState: base,
      animationsEnabled: animationsEnabled,
    );
    animation.syncBaseState(base);
    animation.setAnimationsEnabled(animationsEnabled);
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive) _animation?.interrupt();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _animation?.interrupt();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final pet = appState.petState;
    final hungry = pet.isHungry;
    final foxAsset = PetVisualResolver.assetFor(
      stage: appState.petGrowthStage,
      emotionalState: hungry
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
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final needsScroll =
                  constraints.maxWidth < 400 ||
                  constraints.maxHeight < 740 ||
                  textScale > 1.2;
              final stageHeight = (constraints.maxHeight - 390)
                  .clamp(238.0, 320.0)
                  .toDouble();

              final header = AccountHeader(
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
                trailing: AppSettingsButton(
                  onPressed: () => showSettingsSheet(context),
                ),
                useSafeArea: false,
              );
              final content = Padding(
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
                    if (needsScroll)
                      const SizedBox(height: AppSpacing.sm)
                    else
                      const Spacer(),
                    PetStage(
                      height: stageHeight,
                      isActive: widget.isActive,
                      animation: _animation!,
                      mood: pet.mood,
                      satiety: pet.satiety,
                      care: pet.care,
                      foxAsset: foxAsset,
                      message: message,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    PetActions(
                      onFeed: _feedFox,
                      onPlay: _openPlayHub,
                      onPet: _petFox,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    HomeTaskCard(onPressed: widget.onOpenTasks),
                  ],
                ),
              );

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: needsScroll
                      ? SingleChildScrollView(
                          child: Column(children: [header, content]),
                        )
                      : Column(
                          children: [
                            header,
                            Expanded(child: content),
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

  Future<void> _feedFox() async {
    // One pet action at a time: a tap during a clip is ignored, not queued.
    if (_animation!.isActionPlaying) return;
    final food = await showFeedPetSheet(
      context: context,
      onOpenTasks: widget.onOpenTasks,
    );
    if (food == null || !mounted) return;
    // Coins and satiety already changed inside AppController.feedPet; the
    // clip only presents that result, starting from the pose on screen.
    _animation!.playFeed(
      food,
      after: PetBaseState.of(AppScope.of(context).petState),
    );
  }

  Future<void> _petFox() async {
    if (_animation!.isActionPlaying) return;
    AppScope.of(context).petFox();
    _animation!.playPet();
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
