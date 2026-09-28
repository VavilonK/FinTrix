import 'package:flutter/material.dart';

import '../../home/presentation/pet_animation/pet_look_still.dart';

import '../../home/presentation/pet_animation/pet_look.dart';

import '../../pet_progression/domain/pet_appearance.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
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
                  width: 38,
                  height: 38,
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
                          _AppearanceCard(appState: appState),
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
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              // Ryzhik sits in his room, as in the reference art.
              image: DecorationImage(
                image: AssetImage(AppAssets.backgroundBedroomDay),
                fit: BoxFit.cover,
                alignment: Alignment(0, -0.2),
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadii.extraLarge),
              ),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x1AFFFFFF), Color(0xF2FFFFFF)],
                        stops: [0.55, 1],
                      ),
                    ),
                  ),
                ),
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
                SizedBox.square(
                  dimension: 270,
                  child: PetLookStill(
                    key: const ValueKey('profile_pet_look'),
                    stillAsset: PetVisualResolver.animationSetFor(
                      appState.petGrowthStage,
                    ).happyStill,
                    idleAsset: PetVisualResolver.animationSetFor(
                      appState.petGrowthStage,
                    ).happyIdle,
                    appearance: appState.petAppearance,
                    fallbackAsset: PetVisualResolver.assetFor(
                      stage: appState.petGrowthStage,
                      emotionalState: PetEmotionalState.happy,
                      context: PetVisualContext.profile,
                    ),
                  ),
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
                Text(
                  'Рыжик',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
                      fontWeight: FontWeight.w800,
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
                Text.rich(
                  TextSpan(
                    text: '${appState.petXp % 1000}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                    children: [
                      TextSpan(
                        text: ' / 1 000 XP',
                        style: AppTextStyles.bodySecondary,
                      ),
                    ],
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
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.12),
                    color.withValues(alpha: 0.24),
                  ],
                ),
                borderRadius: AppRadii.mediumBorder,
              ),
              child: Icon(icon, color: color, size: 34),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 2,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 13,
                      color: AppColors.navy,
                    ),
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
                    style: AppTextStyles.cardTitle.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
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
          // Shared table rows reserve the tallest title/status for every stage.
          // Connectors participate only in the icon row, so labels cannot move them.
          Table(
            key: const ValueKey('pet_growth_stages'),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(),
              1: FixedColumnWidth(24),
              2: FlexColumnWidth(),
              3: FixedColumnWidth(24),
              4: FlexColumnWidth(),
            },
            children: [
              TableRow(
                children: [
                  for (final item in PetGrowthStage.values) ...[
                    _GrowthIcon(
                      key: ValueKey('growth_icon_${item.name}'),
                      stage: item,
                      locked: item.index > stage.index,
                    ),
                    if (item != PetGrowthStage.grown)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.disabled,
                      ),
                  ],
                ],
              ),
              TableRow(
                children: [
                  for (final item in PetGrowthStage.values) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxs,
                      ),
                      child: Text(
                        item.shortTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    if (item != PetGrowthStage.grown) const SizedBox.shrink(),
                  ],
                ],
              ),
              TableRow(
                children: [
                  for (final item in PetGrowthStage.values) ...[
                    Center(
                      child: DefaultTextStyle(
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                        child: _StageStatus(stage: item, current: stage),
                      ),
                    ),
                    if (item != PetGrowthStage.grown) const SizedBox.shrink(),
                  ],
                ],
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

class _GrowthIcon extends StatelessWidget {
  const _GrowthIcon({required this.stage, required this.locked, super.key});

  final PetGrowthStage stage;

  /// Not reached yet: shown as a soft silhouette, as in the reference art.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      PetVisualResolver.assetFor(
        stage: stage,
        emotionalState: PetEmotionalState.happy,
        context: PetVisualContext.profile,
      ),
      width: 80,
      height: 80,
      fit: BoxFit.contain,
    );
    return Center(
      child: locked
          ? ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFFCBD2EE),
                BlendMode.srcIn,
              ),
              child: image,
            )
          : image,
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
          const SizedBox(height: AppSpacing.xs),
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

/// Hoodie colour and accessories; changes apply to Home and Profile at once.
class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({required this.appState});

  final AppController appState;

  static const _swatches = {
    HoodieColor.blue: Color(0xFF2F5BE0),
    HoodieColor.red: Color(0xFFD7263D),
    HoodieColor.green: Color(0xFF1E9E5A),
    HoodieColor.purple: Color(0xFF8A3FD1),
  };

  @override
  Widget build(BuildContext context) {
    final look = appState.petAppearance;
    return RoundedSurfaceCard(
      key: const ValueKey('pet_appearance_card'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Внешний вид Рыжика',
            style: AppTextStyles.cardTitle.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Худи', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final color in HoodieColor.values)
                _HoodieSwatch(
                  key: ValueKey('hoodie_${color.name}'),
                  color: _swatches[color]!,
                  label: color.title,
                  selected: look.hoodie == color,
                  onTap: () =>
                      appState.setPetAppearance(look.copyWith(hoodie: color)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Аксессуары', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final accessory in PetAccessory.values)
                _AccessoryChip(
                  key: ValueKey('accessory_${accessory.name}'),
                  asset: PetAccessorySpec.of(accessory).asset,
                  label: accessory.title,
                  selected: look.has(accessory),
                  onTap: () =>
                      appState.setPetAppearance(look.toggle(accessory)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HoodieSwatch extends StatelessWidget {
  const _HoodieSwatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Худи: $label',
      child: InkResponse(
        onTap: onTap,
        radius: 30,
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.navy : AppColors.surface,
                    width: selected ? 3 : 2,
                  ),
                  boxShadow: AppShadows.card,
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, color: AppColors.surface)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.navy,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessoryChip extends StatelessWidget {
  const _AccessoryChip({
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.primaryBlueLight : AppColors.surfaceSoft,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.card,
          side: BorderSide(
            color: selected ? AppColors.primaryBlue : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56, minWidth: 128),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    asset,
                    width: 44,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(label, style: AppTextStyles.label),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    color: selected
                        ? AppColors.primaryBlue
                        : AppColors.secondaryText,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
