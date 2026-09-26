import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../../core/widgets/speech_bubble.dart';
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
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    void start() {
      appState.startMission(widget.mission);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MissionTaskScreen(onReturnHome: widget.onReturnHome),
        ),
      );
    }

    final panel = _MissionIntroPanel(mission: widget.mission, onStart: start);
    final topBar = Padding(
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _StreakBadge(streak: appState.streak),
        ],
      ),
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          LocationSceneBackground(
            sceneAsset: location.sceneAsset,
            overlayOpacity: 0.12,
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Large text or short screens scroll as one column; otherwise
                // the scene fills the space above the anchored panel.
                if (textScale > 1.3 || constraints.maxHeight < 640) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        topBar,
                        SizedBox(
                          height: 260,
                          child: _SceneFox(mission: widget.mission),
                        ),
                        panel,
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    topBar,
                    Expanded(child: _SceneFox(mission: widget.mission)),
                    panel,
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

class _SceneFox extends StatelessWidget {
  const _SceneFox({required this.mission});

  final DailyMission mission;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final foxHeight = (constraints.maxHeight * 0.72).clamp(170.0, 300.0);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: -12,
              child: Center(
                child: Image.asset(
                  AppAssets.foxGameCheer,
                  height: foxHeight,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: constraints.maxHeight * 0.08,
              right: AppSpacing.md,
              width: (constraints.maxWidth * 0.46).clamp(160.0, 240.0),
              child: SpeechBubble(
                text:
                    '${mission.title}! Посмотрим, получится ли всё купить '
                    'и ещё немного отложить!',
                tail: SpeechBubbleTail.bottomLeft,
                tilt: -4,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MissionIntroPanel extends StatelessWidget {
  const _MissionIntroPanel({required this.mission, required this.onStart});

  final DailyMission mission;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final count = mission.tasks.length;
    final tiles = [
      _IntroTile(
        icon: Icons.task_alt_rounded,
        color: AppColors.purple,
        text: '$count ${_tasksWord(count)}',
      ),
      _IntroTile(
        icon: Icons.schedule_rounded,
        color: AppColors.primaryBlue,
        text: '~${mission.estimatedMinutes} минут',
      ),
      _IntroTile(
        icon: Icons.lightbulb_rounded,
        color: AppColors.orange,
        text: 'Тема: ${_themeLabel(mission.theme)}',
      ),
    ];
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.bottomSheet,
        boxShadow: AppShadows.elevatedCard,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Сегодня тебя ${count == 1 ? 'ждёт' : 'ждут'} '
                '$count ${_tasksWord(count)}',
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (stacked)
                for (final tile in tiles) ...[
                  _IntroTile(
                    icon: tile.icon,
                    color: tile.color,
                    text: tile.text,
                    horizontal: true,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ]
              else
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: tiles[0]),
                      const _TileChevron(),
                      Expanded(child: tiles[1]),
                      const _TileChevron(),
                      Expanded(child: tiles[2]),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              _RewardBar(maxReward: mission.maxReward),
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
        ),
      ),
    );
  }
}

String _tasksWord(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) return 'задание';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'задания';
  }
  return 'заданий';
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

class _IntroTile extends StatelessWidget {
  const _IntroTile({
    required this.icon,
    required this.color,
    required this.text,
    this.horizontal = false,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: AppRadii.card,
        border: Border.fromBorderSide(BorderSide(color: AppColors.borderLight)),
      ),
      child: Flex(
        direction: horizontal ? Axis.horizontal : Axis.vertical,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(36),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6, width: AppSpacing.sm),
          Expanded(
            child: Align(
              alignment: horizontal ? Alignment.centerLeft : Alignment.center,
              child: Text(
                text,
                textAlign: horizontal ? TextAlign.start : TextAlign.center,
                style: AppTextStyles.label.copyWith(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TileChevron extends StatelessWidget {
  const _TileChevron();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      child: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.disabled,
        size: 18,
      ),
    );
  }
}

class _RewardBar extends StatelessWidget {
  const _RewardBar({required this.maxReward});

  final int maxReward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF6DC),
        borderRadius: AppRadii.card,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 40,
            child: Stack(
              children: [
                for (final (index, offset) in const [
                  Offset(0, 12),
                  Offset(18, 4),
                  Offset(30, 14),
                ].indexed)
                  Positioned(
                    left: offset.dx,
                    top: offset.dy - 4,
                    child: Image.asset(
                      AppAssets.financeCoinSingle,
                      width: index == 1 ? 30 : 26,
                      height: index == 1 ? 30 : 26,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Награда: ',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondaryText,
                ),
                children: [
                  TextSpan(
                    text: 'до $maxReward монет',
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
