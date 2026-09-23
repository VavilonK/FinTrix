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

enum _RpsChoice { rock, scissors, paper }

class RockPaperScissorsScreen extends StatefulWidget {
  const RockPaperScissorsScreen({super.key});

  @override
  State<RockPaperScissorsScreen> createState() =>
      _RockPaperScissorsScreenState();
}

class _RockPaperScissorsScreenState extends State<RockPaperScissorsScreen> {
  final Random _random = Random();
  _RpsChoice? _childChoice;
  _RpsChoice? _foxChoice;
  MiniGameSessionResult? _result;
  String _message = 'Выбирай: камень, ножницы или бумага!';

  @override
  Widget build(BuildContext context) {
    return MiniGameScaffold(
      title: 'Камень-ножницы-бумага',
      message: _message,
      foxAsset: _result == null
          ? AppAssets.foxGameThinking
          : AppAssets.foxGameCheer,
      child: Column(
        children: [
          RoundedSurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Text('Сделай выбор', style: AppTextStyles.cardTitle),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    for (final choice in _RpsChoice.values) ...[
                      Expanded(
                        child: _ChoiceCard(
                          choice: choice,
                          selected: _childChoice == choice,
                          onTap: _result == null ? () => _play(choice) : null,
                        ),
                      ),
                      if (choice != _RpsChoice.values.last)
                        const SizedBox(width: AppSpacing.xs),
                    ],
                  ],
                ),
                if (_foxChoice != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3E8FF),
                      borderRadius: AppRadii.card,
                    ),
                    child: Text(
                      'Рыжик выбрал: ${_label(_foxChoice!)} ${_emoji(_foxChoice!)}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
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

  void _play(_RpsChoice childChoice) {
    final foxChoice =
        _RpsChoice.values[_random.nextInt(_RpsChoice.values.length)];
    final outcome = childChoice == foxChoice
        ? MiniGameResult.draw
        : _beats(childChoice, foxChoice)
        ? MiniGameResult.won
        : MiniGameResult.lost;
    final title = outcome == MiniGameResult.won
        ? 'Ты победил!'
        : outcome == MiniGameResult.draw
        ? 'Ничья!'
        : 'Рыжик победил';
    final message = outcome == MiniGameResult.won
        ? 'Отличный выбор! Ты разгадал мой ход.'
        : outcome == MiniGameResult.draw
        ? 'Мы выбрали одинаково. Вот это совпадение!'
        : 'Хорошая попытка — попробуй угадать следующий ход.';
    final reward = AppScope.of(context)
        .completeMiniGame(MiniGameType.rockPaperScissors, outcome);
    setState(() {
      _childChoice = childChoice;
      _foxChoice = foxChoice;
      _message = title;
      _result = MiniGameSessionResult(
        outcome: outcome,
        title: title,
        message: message,
        reward: reward,
      );
    });
  }

  bool _beats(_RpsChoice first, _RpsChoice second) {
    return (first == _RpsChoice.rock && second == _RpsChoice.scissors) ||
        (first == _RpsChoice.scissors && second == _RpsChoice.paper) ||
        (first == _RpsChoice.paper && second == _RpsChoice.rock);
  }

  void _reset() {
    setState(() {
      _childChoice = null;
      _foxChoice = null;
      _result = null;
      _message = 'Выбирай: камень, ножницы или бумага!';
    });
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _RpsChoice choice;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 126,
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryBlueLight : AppColors.surfaceSoft,
        borderRadius: AppRadii.heroCard,
        border: Border.all(
          color: selected ? AppColors.primaryBlue : AppColors.borderLight,
          width: selected ? 3 : 2,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadii.heroCard,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.heroCard,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_emoji(choice), style: const TextStyle(fontSize: 42)),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(child: Text(_label(choice), style: AppTextStyles.body)),
            ],
          ),
        ),
      ),
    );
  }
}

String _label(_RpsChoice choice) => switch (choice) {
  _RpsChoice.rock => 'Камень',
  _RpsChoice.scissors => 'Ножницы',
  _RpsChoice.paper => 'Бумага',
};

String _emoji(_RpsChoice choice) => switch (choice) {
  _RpsChoice.rock => '✊',
  _RpsChoice.scissors => '✌️',
  _RpsChoice.paper => '✋',
};
