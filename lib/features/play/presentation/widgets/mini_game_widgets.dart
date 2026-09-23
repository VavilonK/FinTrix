import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../../../../core/widgets/rounded_surface_card.dart';
import '../../../../core/widgets/secondary_capsule_button.dart';
import '../../../home/domain/pet_models.dart';
import '../../domain/mini_game_models.dart';

class MiniGameScaffold extends StatelessWidget {
  const MiniGameScaffold({
    required this.title,
    required this.message,
    required this.foxAsset,
    required this.child,
    this.score,
    super.key,
  });

  final String title;
  final String message;
  final String foxAsset;
  final Widget child;
  final Widget? score;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLavender,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.backgroundBedroomDay,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          const ColoredBox(color: Color(0xD9F7F8FF)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      MiniGameHeader(
                        title: title,
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 136,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 132,
                              child: Image.asset(
                                foxAsset,
                                fit: BoxFit.contain,
                                alignment: Alignment.bottomCenter,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(child: FoxSpeechBubble(message: message)),
                          ],
                        ),
                      ),
                      if (score != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        score!,
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      child,
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
}

class MiniGameHeader extends StatelessWidget {
  const MiniGameHeader({required this.title, required this.onBack, super.key});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.surface,
          shape: const CircleBorder(),
          elevation: 3,
          child: InkWell(
            onTap: onBack,
            customBorder: const CircleBorder(),
            child: const SizedBox.square(
              dimension: 52,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.navy,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.capsule,
              boxShadow: AppShadows.card,
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(title, style: AppTextStyles.sectionTitle),
            ),
          ),
        ),
        const SizedBox(width: 60),
      ],
    );
  }
}

class FoxSpeechBubble extends StatelessWidget {
  const FoxSpeechBubble({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -7,
          bottom: 25,
          child: Transform.rotate(
            angle: 0.78,
            child: const SizedBox.square(
              dimension: 18,
              child: ColoredBox(color: AppColors.surface),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.heroCard,
            boxShadow: AppShadows.card,
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
          ),
        ),
      ],
    );
  }
}

class MiniGameScoreCard extends StatelessWidget {
  const MiniGameScoreCard({
    required this.childScore,
    required this.foxScore,
    this.childLabel = 'Ты',
    this.foxLabel = 'Рыжик',
    super.key,
  });

  final int childScore;
  final int foxScore;
  final String childLabel;
  final String foxLabel;

  @override
  Widget build(BuildContext context) {
    return RoundedSurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ScoreValue(
              label: childLabel,
              value: childScore,
              color: AppColors.primaryBlue,
            ),
          ),
          Container(width: 1, height: 42, color: AppColors.borderLight),
          Expanded(
            child: _ScoreValue(
              label: foxLabel,
              value: foxScore,
              color: AppColors.purple,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreValue extends StatelessWidget {
  const _ScoreValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: AppTextStyles.bodySecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$value',
          style: AppTextStyles.cardTitle.copyWith(color: color, fontSize: 26),
        ),
      ],
    );
  }
}

class MiniGameResultCard extends StatelessWidget {
  const MiniGameResultCard({
    required this.result,
    required this.onReplay,
    required this.onChooseAnother,
    super.key,
  });

  final MiniGameSessionResult result;
  final VoidCallback onReplay;
  final VoidCallback onChooseAnother;

  @override
  Widget build(BuildContext context) {
    final (resultIcon, resultColor) = switch (result.outcome) {
      MiniGameResult.won ||
      MiniGameResult.completed => (Icons.celebration_rounded, AppColors.yellow),
      MiniGameResult.draw => (Icons.handshake_rounded, AppColors.purple),
      MiniGameResult.lost => (Icons.lightbulb_rounded, AppColors.orange),
    };

    return RoundedSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(resultIcon, color: resultColor, size: 42),
          const SizedBox(height: AppSpacing.xs),
          Text(
            result.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            result.message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (result.reward.wasAwarded) ...[
            const Text(
              'Рыжику понравилось играть!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSpacing.xs),
            _RewardChip(
              icon: Icons.auto_awesome_rounded,
              label: '+${result.reward.xp} XP',
            ),
          ] else
            const Text(
              'Мне нравится играть с тобой!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
          const SizedBox(height: AppSpacing.md),
          MiniGameActionButtons(
            onReplay: onReplay,
            onChooseAnother: onChooseAnother,
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLavender,
        borderRadius: AppRadii.capsule,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.purple, size: 24),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class MiniGameActionButtons extends StatelessWidget {
  const MiniGameActionButtons({
    required this.onReplay,
    required this.onChooseAnother,
    super.key,
  });

  final VoidCallback onReplay;
  final VoidCallback onChooseAnother;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PrimaryGradientButton(
          key: const ValueKey('mini_game_replay'),
          label: 'Играть ещё',
          onPressed: onReplay,
          leading: const Icon(Icons.replay_rounded, color: AppColors.surface),
        ),
        const SizedBox(height: AppSpacing.xs),
        SecondaryCapsuleButton(
          key: const ValueKey('mini_game_choose_another'),
          label: 'Выбрать другую игру',
          onPressed: onChooseAnother,
          expand: true,
          leading: const Icon(Icons.grid_view_rounded),
        ),
      ],
    );
  }
}
