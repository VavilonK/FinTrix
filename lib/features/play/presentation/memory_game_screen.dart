import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../home/domain/pet_models.dart';
import '../domain/mini_game_models.dart';
import 'widgets/mini_game_widgets.dart';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  static const _assetPool = <String>[
    AppAssets.memoryCoin,
    AppAssets.memoryPiggyBank,
    AppAssets.memoryBicycle,
    AppAssets.memoryScooter,
    AppAssets.memoryBuildingSet,
    AppAssets.memoryGameController,
    AppAssets.memoryFoodBowl,
    AppAssets.memoryGift,
    AppAssets.memoryBall,
    AppAssets.memoryBackpack,
  ];

  final Random _random = Random();
  final Set<int> _matched = {};
  final Set<int> _visible = {};
  final Map<int, String> _foxMemory = {};
  late List<String> _cards;
  int? _firstIndex;
  int _childScore = 0;
  int _foxScore = 0;
  bool _locked = false;
  bool _foxTurn = false;
  MiniGameSessionResult? _result;
  String _message = 'Открой две карточки и найди пару!';

  @override
  void initState() {
    super.initState();
    _cards = _createDeck();
  }

  @override
  Widget build(BuildContext context) {
    return MiniGameScaffold(
      title: 'Найди пару',
      message: _message,
      foxAsset: _result != null
          ? AppAssets.foxGameCheer
          : _foxTurn
          ? AppAssets.foxGameThinking
          : AppAssets.foxPlayfulExcited,
      score: MiniGameScoreCard(childScore: _childScore, foxScore: _foxScore),
      child: Column(
        children: [
          RoundedSurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: AppSpacing.xs,
                mainAxisSpacing: AppSpacing.xs,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final shown =
                    _visible.contains(index) || _matched.contains(index);
                return _MemoryCard(
                  key: ValueKey('memory_card_$index'),
                  assetPath: _cards[index],
                  shown: shown,
                  matched: _matched.contains(index),
                  enabled: !_locked && !_foxTurn && _result == null && !shown,
                  onTap: () => _flipChild(index),
                );
              },
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: AppSpacing.md),
            MiniGameResultCard(
              key: const ValueKey('memory_done'),
              result: _result!,
              onReplay: _resetGame,
              onChooseAnother: () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _createDeck() {
    final choices = [..._assetPool]..shuffle(_random);
    return [...choices.take(6), ...choices.take(6)]..shuffle(_random);
  }

  Future<void> _flipChild(int index) async {
    if (_locked ||
        _foxTurn ||
        _result != null ||
        _matched.contains(index) ||
        _visible.contains(index)) {
      return;
    }

    setState(() {
      _visible.add(index);
      _foxMemory[index] = _cards[index];
    });
    if (_firstIndex == null) {
      _firstIndex = index;
      setState(() => _message = 'Хорошо запомни эту карточку!');
      return;
    }

    final first = _firstIndex!;
    _locked = true;
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;

    if (_cards[first] == _cards[index]) {
      setState(() {
        _matched.addAll([first, index]);
        _childScore += 1;
        _firstIndex = null;
        _locked = false;
        _message = 'Отлично! Пара твоя — ходи ещё!';
      });
      _finishIfNeeded();
      return;
    }

    setState(() => _message = 'Не совпало. Теперь ход Рыжика!');
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _visible.removeAll([first, index]);
      _firstIndex = null;
      _foxTurn = true;
      _message = 'Сейчас мой ход!';
    });
    await _playFoxTurn();
  }

  Future<void> _playFoxTurn() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || _result != null) return;
    final choice = _chooseFoxCards();
    if (choice.length < 2) return;
    final first = choice[0];
    final second = choice[1];

    setState(() {
      _visible.addAll(choice);
      _foxMemory[first] = _cards[first];
      _foxMemory[second] = _cards[second];
    });
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final found = _cards[first] == _cards[second];
    setState(() {
      if (found) {
        _matched.addAll(choice);
        _foxScore += 1;
        _message = 'Я нашёл пару! Теперь снова твой ход.';
      } else {
        _visible.removeAll(choice);
        _message = 'Не совпало. Теперь твой ход!';
      }
      _foxTurn = false;
      _locked = false;
    });
    _finishIfNeeded();
  }

  List<int> _chooseFoxCards() {
    final available = [
      for (var i = 0; i < _cards.length; i++)
        if (!_matched.contains(i)) i,
    ];
    final groups = <String, List<int>>{};
    for (final entry in _foxMemory.entries) {
      if (!available.contains(entry.key)) continue;
      groups.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    final knownPairs = groups.values.where((indices) => indices.length >= 2);
    if (knownPairs.isNotEmpty && _random.nextDouble() < 0.65) {
      final pair = knownPairs.elementAt(_random.nextInt(knownPairs.length));
      return pair.take(2).toList();
    }
    available.shuffle(_random);
    return available.take(2).toList();
  }

  void _finishIfNeeded() {
    if (_matched.length != _cards.length || _result != null) return;
    final outcome = _childScore > _foxScore
        ? MiniGameResult.won
        : _childScore < _foxScore
        ? MiniGameResult.lost
        : MiniGameResult.draw;
    final title = outcome == MiniGameResult.won
        ? 'Ты победил!'
        : outcome == MiniGameResult.lost
        ? 'Рыжик победил'
        : 'Ничья!';
    final message = outcome == MiniGameResult.won
        ? 'У тебя отличная память!'
        : outcome == MiniGameResult.lost
        ? 'Ты запомнил много карточек. Сыграем ещё?'
        : 'Вы нашли одинаковое количество пар.';
    final reward = AppScope.of(context)
        .completeMiniGame(MiniGameType.matchingPairs, outcome);
    setState(() {
      _message = title;
      _result = MiniGameSessionResult(
        outcome: outcome,
        title: title,
        message: message,
        reward: reward,
      );
    });
  }

  void _resetGame() {
    setState(() {
      _cards = _createDeck();
      _matched.clear();
      _visible.clear();
      _foxMemory.clear();
      _firstIndex = null;
      _childScore = 0;
      _foxScore = 0;
      _locked = false;
      _foxTurn = false;
      _result = null;
      _message = 'Открой две карточки и найди пару!';
    });
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({
    required this.assetPath,
    required this.shown,
    required this.matched,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String assetPath;
  final bool shown;
  final bool matched;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: shown
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF66B7FF), AppColors.primaryBlueDark],
              ),
        color: shown ? AppColors.surface : null,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: matched ? AppColors.green : AppColors.surface,
          width: matched ? 3 : 2,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadii.card,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadii.card,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: shown
                  ? Image.asset(
                      assetPath,
                      key: ValueKey(assetPath),
                      fit: BoxFit.contain,
                    )
                  : const _MemoryCardBack(key: ValueKey('card_back')),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryCardBack extends StatelessWidget {
  const _MemoryCardBack({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(35),
        borderRadius: AppRadii.mediumBorder,
        border: Border.all(color: AppColors.surface.withAlpha(110)),
      ),
      child: const Center(
        child: Icon(Icons.pets_rounded, color: AppColors.surface, size: 34),
      ),
    );
  }
}
