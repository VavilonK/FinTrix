import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../tasks/data/location_definitions.dart';
import '../domain/mission_models.dart';
import 'mission_checkpoint_screen.dart';
import 'mission_complete_screen.dart';
import 'mission_task_screen.dart';
import 'widgets/location_scene_widgets.dart';

class MissionResultScreen extends StatelessWidget {
  const MissionResultScreen({required this.onReturnHome, super.key});

  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final result = appState.lastResult;
    if (result == null) return const SizedBox.shrink();
    final mission = appState.activeMission;
    final location = mission == null
        ? LocationDefinitions.all.first
        : LocationDefinitions.byId(mission.locationId);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          LocationSceneBackground(
            sceneAsset: location.sceneAsset,
            overlayOpacity: result.isCorrect ? 0.82 : 0.87,
          ),
          Positioned(
            top: -60,
            right: -40,
            child: _GlowCircle(
              size: 190,
              color: result.isCorrect
                  ? const Color(0x2855C969)
                  : const Color(0x30FFC43D),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 186,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Positioned(
                              bottom: 0,
                              child: Container(
                                width: 220,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: result.isCorrect
                                      ? const Color(0x4055C969)
                                      : const Color(0x36FFC43D),
                                  borderRadius: AppRadii.capsule,
                                ),
                              ),
                            ),
                            Image.asset(
                              result.isCorrect
                                  ? AppAssets.foxSittingHappyLevel05
                                  : AppAssets.foxPeekingHappyLevel05,
                              width: result.isCorrect ? 190 : 176,
                              height: 190,
                              fit: BoxFit.contain,
                            ),
                            if (result.isCorrect)
                              const Positioned(
                                top: 16,
                                right: 54,
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  color: AppColors.yellow,
                                  size: 36,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: RoundedSurfaceCard(
                          borderRadius: AppRadii.heroCard,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: result.isCorrect
                                      ? const Color(0xFFE4F8E8)
                                      : const Color(0xFFFFF1C7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  result.isCorrect
                                      ? Icons.check_rounded
                                      : Icons.lightbulb_rounded,
                                  color: result.isCorrect
                                      ? AppColors.green
                                      : AppColors.orange,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                result.isCorrect
                                    ? 'Хороший выбор!'
                                    : 'Давай разберёмся',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.heading,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                result.explanation,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodySecondary,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              if (!result.isCorrect) ...[
                                _CorrectAnswerCard(
                                  answer: result.correctAnswer,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFF6D8),
                                    borderRadius: AppRadii.mediumBorder,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        color: AppColors.orange,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Flexible(
                                        child: Text(
                                          'В этот раз монеты не начислены',
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.body.copyWith(
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                _RewardsRow(
                                  coins: result.rewardCoins,
                                  xp: result.xpEarned,
                                ),
                              ],
                              if (result.balanceBefore != result.balanceAfter)
                                _ValueChange(
                                  icon: Icons.account_balance_wallet_rounded,
                                  label: 'Баланс',
                                  before: result.balanceBefore,
                                  after: result.balanceAfter,
                                ),
                              if (result.savingsBefore != result.savingsAfter)
                                _ValueChange(
                                  icon: Icons.savings_rounded,
                                  label: 'Копилка',
                                  before: result.savingsBefore,
                                  after: result.savingsAfter,
                                ),
                              const SizedBox(height: AppSpacing.lg),
                              PrimaryGradientButton(
                                key: const ValueKey('mission_next'),
                                label: 'Дальше',
                                onPressed: () => _advance(context),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.surface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _advance(BuildContext context) {
    final nextStep = AppScope.of(context).advanceAfterResult();
    final Widget nextScreen = switch (nextStep) {
      MissionNextStep.task => MissionTaskScreen(onReturnHome: onReturnHome),
      MissionNextStep.checkpoint => MissionCheckpointScreen(
        onReturnHome: onReturnHome,
      ),
      MissionNextStep.complete => MissionCompleteScreen(
        onReturnHome: onReturnHome,
      ),
    };
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => nextScreen));
  }
}

class _CorrectAnswerCard extends StatelessWidget {
  const _CorrectAnswerCard({required this.answer});

  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryBlueLight,
        borderRadius: AppRadii.mediumBorder,
        border: Border.all(color: const Color(0xFFB8DAFF)),
      ),
      child: Column(
        children: [
          Text('Правильный ответ', style: AppTextStyles.caption),
          const SizedBox(height: 3),
          Text(
            answer,
            textAlign: TextAlign.center,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _RewardsRow extends StatelessWidget {
  const _RewardsRow({required this.coins, required this.xp});

  final int coins;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: _RewardTile(
              color: const Color(0xFFFFF2C4),
              label: '+$coins монет',
              child: Image.asset(
                AppAssets.financeCoinSingle,
                width: 34,
                height: 34,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _RewardTile(
              color: const Color(0xFFE9DEFF),
              label: '+$xp XP',
              child: const Icon(
                Icons.bolt_rounded,
                color: AppColors.purple,
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.color,
    required this.label,
    required this.child,
  });

  final Color color;
  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadii.mediumBorder,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          child,
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueChange extends StatelessWidget {
  const _ValueChange({
    required this.icon,
    required this.label,
    required this.before,
    required this.after,
  });

  final IconData icon;
  final String label;
  final int before;
  final int after;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: AppRadii.mediumBorder,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.purple),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Text(
            '${_formatCoins(before)} → ${_formatCoins(after)}',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

String _formatCoins(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
}
