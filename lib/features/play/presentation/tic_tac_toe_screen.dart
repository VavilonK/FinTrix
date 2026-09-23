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

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  final List<String> _board = List.filled(9, '');
  final Random _random = Random();
  bool _foxThinking = false;
  MiniGameSessionResult? _result;
  String _message = 'Теперь твой ход!';

  @override
  Widget build(BuildContext context) {
    final foxAsset = _result != null
        ? AppAssets.foxGameCheer
        : _foxThinking
        ? AppAssets.foxGameThinking
        : AppAssets.foxPlayfulExcited;

    return MiniGameScaffold(
      title: 'Крестики-нолики',
      message: _message,
      foxAsset: foxAsset,
      child: Column(
        children: [
          RoundedSurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Text(
                  'Ты играешь крестиками',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.sm),
                AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 9,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: AppSpacing.xs,
                          mainAxisSpacing: AppSpacing.xs,
                        ),
                    itemBuilder: (context, index) {
                      final value = _board[index];
                      return _TicCell(
                        key: ValueKey('tic_cell_$index'),
                        value: value,
                        enabled:
                            _result == null && !_foxThinking && value.isEmpty,
                        onTap: () => _playChild(index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: AppSpacing.md),
            MiniGameResultCard(
              key: const ValueKey('tic_done'),
              result: _result!,
              onReplay: _resetGame,
              onChooseAnother: () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _playChild(int index) async {
    if (_result != null || _foxThinking || _board[index].isNotEmpty) return;
    setState(() {
      _board[index] = 'X';
      _message = _random.nextBool()
          ? 'Отличный ход!'
          : 'Ой, почти поймал меня!';
    });
    if (_finishIfNeeded()) return;

    setState(() {
      _foxThinking = true;
      _message = 'Сейчас мой ход!';
    });
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted || _result != null) return;

    final move = _bestFoxMove();
    setState(() {
      if (move != null) _board[move] = 'O';
      _foxThinking = false;
      _message = 'Теперь твой ход!';
    });
    _finishIfNeeded();
  }

  int? _bestFoxMove() {
    final open = [
      for (var i = 0; i < 9; i++)
        if (_board[i].isEmpty) i,
    ];
    if (open.isEmpty) return null;
    for (final mark in ['O', 'X']) {
      for (final index in open) {
        _board[index] = mark;
        final wins = _winner() == mark;
        _board[index] = '';
        if (wins) return index;
      }
    }
    return open[_random.nextInt(open.length)];
  }

  bool _finishIfNeeded() {
    final winner = _winner();
    final draw = winner == null && _board.every((cell) => cell.isNotEmpty);
    if (winner == null && !draw) return false;

    final outcome = winner == 'X'
        ? MiniGameResult.won
        : winner == 'O'
        ? MiniGameResult.lost
        : MiniGameResult.draw;
    final title = winner == 'X'
        ? 'Ура, ты победил!'
        : winner == 'O'
        ? 'Попробуем ещё раз?'
        : 'Ничья! Отличная игра!';
    final message = winner == 'X'
        ? 'Ты собрал линию раньше Рыжика.'
        : winner == 'O'
        ? 'В следующий раз внимательно следи за двумя линиями.'
        : 'Вы оба играли очень внимательно.';

    final reward = AppScope.of(context)
        .completeMiniGame(MiniGameType.ticTacToe, outcome);
    setState(() {
      _foxThinking = false;
      _message = title;
      _result = MiniGameSessionResult(
        outcome: outcome,
        title: title,
        message: message,
        reward: reward,
      );
    });
    return true;
  }

  String? _winner() {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    for (final line in lines) {
      final mark = _board[line[0]];
      if (mark.isNotEmpty &&
          mark == _board[line[1]] &&
          mark == _board[line[2]]) {
        return mark;
      }
    }
    return null;
  }

  void _resetGame() {
    setState(() {
      _board.fillRange(0, _board.length, '');
      _foxThinking = false;
      _result = null;
      _message = 'Теперь твой ход!';
    });
  }
}

class _TicCell extends StatelessWidget {
  const _TicCell({
    required this.value,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isChild = value == 'X';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isChild
            ? AppColors.primaryBlueLight
            : value == 'O'
            ? const Color(0xFFF1E5FF)
            : AppColors.surfaceSoft,
        borderRadius: AppRadii.heroCard,
        border: Border.all(
          color: value.isEmpty
              ? AppColors.borderLight
              : isChild
              ? AppColors.primaryBlue
              : AppColors.purple,
          width: value.isEmpty ? 2 : 3,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadii.heroCard,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadii.heroCard,
          child: Center(
            child: Text(
              value,
              style: AppTextStyles.display.copyWith(
                fontSize: 52,
                color: isChild ? AppColors.primaryBlue : AppColors.purple,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
