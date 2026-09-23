import 'dart:math';

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
import '../../home/domain/pet_models.dart';
import '../domain/mini_game_models.dart';
import 'widgets/mini_game_widgets.dart';

class SequenceGameScreen extends StatefulWidget {
  const SequenceGameScreen({super.key});

  @override
  State<SequenceGameScreen> createState() => _SequenceGameScreenState();
}

class _SequenceGameScreenState extends State<SequenceGameScreen> {
  static const _tileIcons = <IconData>[
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.savings_rounded,
    Icons.sports_esports_rounded,
  ];
  static const _tileColors = <Color>[
    AppColors.yellow,
    AppColors.pink,
    AppColors.green,
    AppColors.purple,
  ];

  final Random _random = Random();
  List<int> _sequence = [];
  int _round = 0;
  int _inputIndex = 0;
  int? _activeTile;
  int _animationId = 0;
  bool _started = false;
  bool _acceptingInput = false;
  MiniGameSessionResult? _result;
  String _message = 'Запомни порядок, а потом повтори его!';

  @override
  Widget build(BuildContext context) {
    return MiniGameScaffold(
      title: 'Повтори последовательность',
      message: _message,
      foxAsset: _result != null
          ? AppAssets.foxGameCheer
          : AppAssets.foxGameThinking,
      score: MiniGameScoreCard(
        childLabel: 'Раунд',
        childScore: _round + 1,
        foxLabel: 'Всего',
        foxScore: 3,
      ),
      child: Column(
        children: [
          RoundedSurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Text(
                  _acceptingInput ? 'Теперь повтори' : 'Смотри внимательно',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: AppSpacing.md),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.35,
                  ),
                  itemBuilder: (context, index) => _SequenceTile(
                    index: index,
                    icon: _tileIcons[index],
                    color: _tileColors[index],
                    active: _activeTile == index,
                    enabled:
                        _acceptingInput &&
                        _result == null &&
                        _activeTile == null,
                    onTap: () => _tapTile(index),
                  ),
                ),
                if (!_started && _result == null) ...[
                  const SizedBox(height: AppSpacing.md),
                  PrimaryGradientButton(
                    key: const ValueKey('sequence_start'),
                    label: 'Начать',
                    onPressed: _start,
                    leading: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.surface,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: AppSpacing.md),
            MiniGameResultCard(
              result: _result!,
              onReplay: _reset,
              onChooseAnother: () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }

  void _start() {
    setState(() {
      _started = true;
      _sequence = _makeSequence();
    });
    _showSequence();
  }

  List<int> _makeSequence() {
    return List.generate(3 + _round, (_) => _random.nextInt(4));
  }

  Future<void> _showSequence() async {
    final animationId = ++_animationId;
    setState(() {
      _acceptingInput = false;
      _inputIndex = 0;
      _message = 'Смотри внимательно!';
    });
    await Future<void>.delayed(const Duration(milliseconds: 450));
    for (final tile in _sequence) {
      if (!mounted || animationId != _animationId) return;
      setState(() => _activeTile = tile);
      await Future<void>.delayed(const Duration(milliseconds: 480));
      if (!mounted || animationId != _animationId) return;
      setState(() => _activeTile = null);
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    if (!mounted || animationId != _animationId) return;
    setState(() {
      _acceptingInput = true;
      _message = 'Теперь повтори!';
    });
  }

  Future<void> _tapTile(int index) async {
    if (!_acceptingInput || _result != null) return;
    if (_sequence[_inputIndex] != index) {
      _finish(MiniGameResult.lost);
      return;
    }

    setState(() {
      _activeTile = index;
      _inputIndex += 1;
    });
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted || _result != null) return;
    setState(() => _activeTile = null);
    if (_inputIndex < _sequence.length) return;

    if (_round == 2) {
      _finish(MiniGameResult.won);
      return;
    }
    setState(() {
      _round += 1;
      _sequence = _makeSequence();
      _message = 'Отлично! Теперь будет на один шаг больше.';
    });
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted && _result == null) _showSequence();
  }

  void _finish(MiniGameResult outcome) {
    _animationId += 1;
    final won = outcome == MiniGameResult.won;
    final title = won ? 'Всё получилось!' : 'Почти получилось!';
    final resultMessage = won
        ? 'Ты повторил все три последовательности.'
        : 'Запоминай по одному цвету — так будет легче.';
    final reward = AppScope.of(context)
        .completeMiniGame(MiniGameType.repeatSequence, outcome);
    setState(() {
      _acceptingInput = false;
      _activeTile = null;
      _message = won ? 'У тебя отличная память!' : 'Попробуем ещё раз?';
      _result = MiniGameSessionResult(
        outcome: outcome,
        title: title,
        message: resultMessage,
        reward: reward,
      );
    });
  }

  void _reset() {
    _animationId += 1;
    setState(() {
      _sequence = [];
      _round = 0;
      _inputIndex = 0;
      _activeTile = null;
      _started = false;
      _acceptingInput = false;
      _result = null;
      _message = 'Запомни порядок, а потом повтори его!';
    });
  }
}

class _SequenceTile extends StatelessWidget {
  const _SequenceTile({
    required this.index,
    required this.icon,
    required this.color,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final int index;
  final IconData icon;
  final Color color;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: active ? 1.06 : 1,
      duration: const Duration(milliseconds: 140),
      child: AnimatedContainer(
        key: ValueKey('sequence_tile_$index'),
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: active ? color : Color.lerp(color, AppColors.surface, 0.58),
          borderRadius: AppRadii.heroCard,
          border: Border.all(color: color, width: active ? 4 : 2),
          boxShadow: active ? AppShadows.primaryControl : AppShadows.card,
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: AppRadii.heroCard,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: AppRadii.heroCard,
            child: Icon(
              icon,
              color: active ? AppColors.surface : color,
              size: 46,
            ),
          ),
        ),
      ),
    );
  }
}
