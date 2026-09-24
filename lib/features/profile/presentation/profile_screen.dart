import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/account_header.dart';
import '../../../core/widgets/app_settings_button.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../home/presentation/widgets/home_sheets.dart';
import '../../pet_progression/domain/pet_progression.dart';
import '../../pet_progression/presentation/pet_visual_resolver.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.onOpenGoals, super.key});

  final VoidCallback onOpenGoals;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppAssets.backgroundBedroomDay,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xB8E8EEFF), Color(0xD9F4F6FF)],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              AccountHeader(
                avatar: Image.asset(
                  AppAssets.avatarChildDefault,
                  fit: BoxFit.cover,
                ),
                levelLabel: 'Ур. ${appState.petLevel}',
                balance: _formatNumber(appState.balance),
                savings: _formatNumber(appState.savings),
                balanceLeading: Image.asset(
                  AppAssets.financeCoinSingle,
                  width: 28,
                  height: 28,
                ),
                savingsLeading: Image.asset(
                  AppAssets.financePiggyBank,
                  width: 34,
                  height: 34,
                ),
                onSavingsTap: onOpenGoals,
                trailing: AppSettingsButton(
                  onPressed: () => showSettingsSheet(context),
                ),
                useSafeArea: false,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.sm,
                    AppSpacing.md,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FoxProfileHero(appState: appState),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Наши успехи',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _AchievementsGrid(appState: appState),
                          const SizedBox(height: AppSpacing.md),
                          _GrowthCard(appState: appState),
                          const SizedBox(height: AppSpacing.md),
                          _ChildProfileCard(appState: appState),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FoxProfileHero extends StatelessWidget {
  const _FoxProfileHero({required this.appState});

  final AppController appState;

  @override
  Widget build(BuildContext context) {
    final progress = (appState.petXp % 1000) / 1000;
    return RoundedSurfaceCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadii.heroCard,
      child: Column(
        children: [
          Container(
            height: 230,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFDBEDFF), Color(0xFFF1E7FF)],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadii.extraLarge),
              ),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                const Positioned(
                  left: 24,
                  top: 28,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.yellow,
                    size: 34,
                  ),
                ),
                const Positioned(
                  right: 28,
                  top: 58,
                  child: Icon(
                    Icons.star_rounded,
                    color: Color(0x668649F4),
                    size: 42,
                  ),
                ),
                Image.asset(
                  PetVisualResolver.assetFor(
                    stage: appState.petGrowthStage,
                    emotionalState: PetEmotionalState.happy,
                    context: PetVisualContext.profile,
                  ),
                  width: 235,
                  height: 225,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                Text('Рыжик', style: AppTextStyles.heading),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 5,
                  ),
                  decoration: const BoxDecoration(
                    gradient: AppGradients.levelBadge,
                    borderRadius: AppRadii.capsule,
                  ),
                  child: Text(
                    'Уровень ${appState.petLevel}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.surface,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppProgressBar(
                  value: progress,
                  gradient: AppGradients.primaryCta,
                  semanticLabel: 'Опыт Рыжика',
                ),
                const SizedBox(height: 5),
                Text(
                  '${appState.petXp % 1000} / 1 000 XP',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  const _AchievementsGrid({required this.appState});

  final AppController appState;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.xs) / 2;
        return Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _AchievementTile(
              width: width,
              icon: Icons.calendar_month_rounded,
              color: AppColors.primaryBlue,
              value: '${appState.daysTogether}',
              label: 'дней вместе',
            ),
            _AchievementTile(
              width: width,
              icon: Icons.task_alt_rounded,
              color: AppColors.green,
              value: '${appState.completedTasks}',
              label: 'заданий',
            ),
            _AchievementTile(
              width: width,
              icon: Icons.track_changes_rounded,
              color: AppColors.pink,
              value: '${appState.achievedGoals}',
              label: 'цели достигнуто',
            ),
            _AchievementTile(
              width: width,
              icon: Icons.local_fire_department_rounded,
              color: AppColors.orange,
              value: '${appState.streak}',
              label: 'дня подряд',
            ),
          ],
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.width,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final double width;
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: RoundedSurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: AppRadii.mediumBorder,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: AppTextStyles.cardTitle),
                  Text(
                    label,
                    maxLines: 2,
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({required this.appState});

  final AppController appState;

  @override
  Widget build(BuildContext context) {
    final stage = appState.petGrowthStage;
    final enlargedText = MediaQuery.textScalerOf(context).scale(1) >= 1.8;
    final threshold = PetProgressionConfig.nextStageThreshold(
      appState.petGrowthPoints,
    );
    final isGrown = stage == PetGrowthStage.grown;
    return RoundedSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (enlargedText)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Как растёт Рыжик', style: AppTextStyles.cardTitle),
                Text(
                  stage.title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Как растёт Рыжик',
                    style: AppTextStyles.cardTitle,
                  ),
                ),
                Text(
                  stage.title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          AppProgressBar(
            value: PetProgressionConfig.progressToNextStage(
              appState.petGrowthPoints,
            ),
            gradient: AppGradients.primaryCta,
            semanticLabel: 'Прогресс развития Рыжика',
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              isGrown
                  ? 'Максимальная стадия'
                  : '${appState.petGrowthPoints} / $threshold очков развития',
              style: AppTextStyles.caption,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _GrowthStep(
                  icon: Icons.pets_rounded,
                  color: AppColors.green,
                  label: PetGrowthStage.little.shortTitle,
                  trailing: _StageStatus(
                    stage: PetGrowthStage.little,
                    current: stage,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.disabled,
              ),
              Expanded(
                child: _GrowthStep(
                  icon: Icons.pets_rounded,
                  color: AppColors.primaryBlue,
                  label: PetGrowthStage.growing.shortTitle,
                  trailing: _StageStatus(
                    stage: PetGrowthStage.growing,
                    current: stage,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.disabled,
              ),
              Expanded(
                child: _GrowthStep(
                  icon: Icons.pets_rounded,
                  color: AppColors.purple,
                  label: PetGrowthStage.grown.shortTitle,
                  trailing: _StageStatus(
                    stage: PetGrowthStage.grown,
                    current: stage,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageStatus extends StatelessWidget {
  const _StageStatus({required this.stage, required this.current});

  final PetGrowthStage stage;
  final PetGrowthStage current;

  @override
  Widget build(BuildContext context) {
    if (stage == current) {
      return Text(
        'Сейчас',
        style: AppTextStyles.caption.copyWith(color: AppColors.primaryBlue),
      );
    }
    if (stage.index < current.index) {
      return const Icon(Icons.check_circle_rounded, color: AppColors.green);
    }
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(Icons.lock_rounded, size: 15), Text('Позже')],
    );
  }
}

class _GrowthStep extends StatelessWidget {
  const _GrowthStep({
    this.icon,
    required this.color,
    required this.label,
    required this.trailing,
  });

  final IconData? icon;
  final Color color;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 36),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: AppTextStyles.caption.copyWith(color: AppColors.navy),
        ),
        const SizedBox(height: 3),
        DefaultTextStyle(style: AppTextStyles.caption, child: trailing),
      ],
    );
  }
}

class _ChildProfileCard extends StatelessWidget {
  const _ChildProfileCard({required this.appState});

  final AppController appState;

  @override
  Widget build(BuildContext context) {
    return RoundedSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Мой профиль', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          _ProfileRow(
            icon: Icons.person_rounded,
            label: 'Имя ребёнка',
            value: appState.childName,
          ),
          const Divider(color: AppColors.borderLight),
          _ProfileRow(
            key: const ValueKey('child_age_read_only'),
            icon: Icons.cake_rounded,
            label: 'Возраст',
            value: '${appState.age} лет',
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.primaryBlueLight,
              borderRadius: AppRadii.mediumBorder,
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.family_restroom_rounded,
                  color: AppColors.primaryBlue,
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Данные профиля можно изменить в разделе для родителей.\n'
                    'Родитель может посмотреть твой игровой прогресс.',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.primaryBlueLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(value, style: AppTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatNumber(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
}
