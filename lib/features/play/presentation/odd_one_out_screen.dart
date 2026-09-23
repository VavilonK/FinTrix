import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../home/domain/pet_models.dart';
import '../domain/mini_game_models.dart';
import 'widgets/mini_game_widgets.dart';

class OddOneOutScreen extends StatefulWidget {
  const OddOneOutScreen({super.key});

  @override
  State<OddOneOutScreen> createState() => _OddOneOutScreenState();
}

class _OddOneOutScreenState extends State<OddOneOutScreen> {
  static const _rounds = <_OddRound>[
    _OddRound(
      hint: 'Три предмета — игрушки. Что лишнее?',
      related: [
        AppAssets.memoryBall,
        AppAssets.memoryGameController,
        AppAssets.memoryBuildingSet,
      ],
      odd: AppAssets.memoryFoodBowl,
    ),
    _OddRound(
      hint: 'Три предмета могут быть мечтой для накоплений.',
      related: [
        AppAssets.memoryBicycle,
        AppAssets.memoryScooter,
        AppAssets.memoryBuildingSet,
      ],
      odd: AppAssets.memoryCoin,
    ),
    _OddRound(
      hint: 'Три вещи можно взять на прогулку.',
      related: [
        AppAssets.memoryBackpack,
        AppAssets.memoryBall,
        AppAssets.memoryScooter,
      ],
      odd: AppAssets.memoryPiggyBank,
    ),
  ];

  final Random _random = Random();
  late List<String> _items;
  int _roundIndex = 0;
  int _correctAnswers = 0;
  int? _selectedIndex;
  bool _locked = false;
  MiniGameSessionResult? _result;
  String _message = 'Найди картинку, которая не подходит к остальным.';

  @override
  void initState() {
    super.initState();
    _items = _makeItems(_rounds.first);
  }

  @override
  Widget build(BuildContext context) {
    final round = _rounds[_roundIndex];
    return MiniGameScaffold(
      title: 'Что лишнее?',
      message: _message,
      foxAsset: _result != null
          ? AppAssets.foxGameCheer
          : AppAssets.foxGameThinking,
      score: MiniGameScoreCard(
        childLabel: 'Верно',
        childScore: _correctAnswers,
        foxLabel: 'Раунд',
        foxScore: _roundIndex + 1,
      ),
      child: Column(
        children: [
          RoundedSurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Text(
                  round.hint,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: AppSpacing.md),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (context, index) {
                    final selected = _selectedIndex == index;
                    final isCorrect = _items[index] == round.odd;
                    return _PictureChoice(
                      key: ValueKey('odd_choice_${_roundIndex}_$index'),
                      assetPath: _items[index],
                      selected: selected,
                      correct: selected && isCorrect,
                      wrong: selected && !isCorrect,
                      enabled: !_locked && _result == null,
                      onTap: () => _choose(index),
                    );
                  },
                ),
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

  List<String> _makeItems(_OddRound round) {
    return [...round.related, round.odd]..shuffle(_random);
  }

  Future<void> _choose(int index) async {
    if (_locked || _result != null) return;
    final correct = _items[index] == _rounds[_roundIndex].odd;
    setState(() {
      _locked = true;
      _selectedIndex = index;
      if (correct) {
        _correctAnswers += 1;
        _message = 'Верно! Ты заметил отличие.';
      } else {
        _message = 'Почти! Посмотри, что объединяет три картинки.';
      }
    });
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    if (_roundIndex == _rounds.length - 1) {
      _finish();
      return;
    }
    setState(() {
      _roundIndex += 1;
      _items = _makeItems(_rounds[_roundIndex]);
      _selectedIndex = null;
      _locked = false;
      _message = 'А теперь найди лишнее здесь!';
    });
  }

  void _finish() {
    final outcome = _correctAnswers == 3
        ? MiniGameResult.won
        : _correctAnswers == 2
        ? MiniGameResult.draw
        : MiniGameResult.lost;
    final title = _correctAnswers == 3
        ? 'Все ответы верные!'
        : _correctAnswers == 2
        ? 'Очень хороший результат!'
        : 'Давай потренируемся ещё';
    final resultMessage =
        'Ты нашёл $_correctAnswers из ${_rounds.length} лишних картинок.';
    final reward = AppScope.of(context)
        .completeMiniGame(MiniGameType.oddOneOut, outcome);
    setState(() {
      _message = title;
      _result = MiniGameSessionResult(
        outcome: outcome,
        title: title,
        message: resultMessage,
        reward: reward,
      );
    });
  }

  void _reset() {
    setState(() {
      _roundIndex = 0;
      _correctAnswers = 0;
      _items = _makeItems(_rounds.first);
      _selectedIndex = null;
      _locked = false;
      _result = null;
      _message = 'Найди картинку, которая не подходит к остальным.';
    });
  }
}

class _OddRound {
  const _OddRound({
    required this.hint,
    required this.related,
    required this.odd,
  });

  final String hint;
  final List<String> related;
  final String odd;
}

class _PictureChoice extends StatelessWidget {
  const _PictureChoice({
    required this.assetPath,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String assetPath;
  final bool selected;
  final bool correct;
  final bool wrong;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = correct
        ? AppColors.green
        : wrong
        ? AppColors.orange
        : selected
        ? AppColors.primaryBlue
        : AppColors.borderLight;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: AppRadii.heroCard,
        border: Border.all(color: borderColor, width: selected ? 4 : 2),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadii.heroCard,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadii.heroCard,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Image.asset(assetPath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
