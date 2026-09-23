import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import 'memory_game_screen.dart';
import 'odd_one_out_screen.dart';
import 'rock_paper_scissors_screen.dart';
import 'sequence_game_screen.dart';
import 'tic_tac_toe_screen.dart';

class PlayHubScreen extends StatelessWidget {
  const PlayHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final hungry = state.petState.satiety < 30;

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
          const ColoredBox(color: Color(0xBFFFFFFF)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _BackButton(onTap: () => Navigator.of(context).pop()),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Давай поиграем!',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.heading,
                            ),
                          ),
                          const SizedBox(width: 52),
                        ],
                      ),
                      SizedBox(
                        height: 280,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Image.asset(
                              AppAssets.foxPlayfulExcited,
                              height: 250,
                              fit: BoxFit.contain,
                            ),
                            Positioned(
                              top: AppSpacing.md,
                              right: 0,
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 180,
                                ),
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: const BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: AppRadii.card,
                                ),
                                child: Text(
                                  hungry
                                      ? 'Я немного проголодался, но можем сыграть!'
                                      : 'Во что сыграем?',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _GameCard(
                        key: const ValueKey('open_tic_tac_toe'),
                        title: 'Крестики-нолики',
                        subtitle: 'Сыграй против Рыжика',
                        assetPath: AppAssets.minigameTicTacToe,
                        color: AppColors.primaryBlueLight,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const TicTacToeScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _GameCard(
                        key: const ValueKey('open_memory_game'),
                        title: 'Найди пары',
                        subtitle: 'Запомни и собери 6 пар',
                        assetPath: AppAssets.minigameMemoryPairs,
                        color: const Color(0xFFF3E8FF),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const MemoryGameScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _GameCard(
                        key: const ValueKey('open_rock_paper_scissors'),
                        title: 'Камень-ножницы-бумага',
                        subtitle: 'Быстрый раунд против Рыжика',
                        icon: Icons.back_hand_rounded,
                        color: const Color(0xFFFFE7D7),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RockPaperScissorsScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _GameCard(
                        key: const ValueKey('open_sequence_game'),
                        title: 'Повтори последовательность',
                        subtitle: 'Запомни цвета и повтори порядок',
                        icon: Icons.auto_awesome_motion_rounded,
                        color: const Color(0xFFE6F7E8),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SequenceGameScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _GameCard(
                        key: const ValueKey('open_odd_one_out'),
                        title: 'Что лишнее?',
                        subtitle: 'Найди картинку, которая отличается',
                        icon: Icons.category_rounded,
                        color: const Color(0xFFFFF1C9),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const OddOneOutScreen(),
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
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.assetPath,
    this.icon,
    super.key,
  }) : assert(assetPath != null || icon != null);

  final String title;
  final String subtitle;
  final String? assetPath;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RoundedSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 112,
            height: 104,
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadii.mediumBorder,
            ),
            child: assetPath != null
                ? Image.asset(assetPath!, fit: BoxFit.contain)
                : Icon(icon, color: AppColors.primaryBlue, size: 54),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primaryBlue,
            size: 34,
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox.square(
          dimension: 52,
          child: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
    );
  }
}
