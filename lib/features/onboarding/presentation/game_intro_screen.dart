import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/widgets/rounded_surface_card.dart';
import '../../../core/widgets/speech_bubble.dart';

/// The child's short intro to the game's goal and its three kinds of money
/// decisions (ТЗ 2.5.1). Shown once after setup and at any time from
/// Settings → «Как играть».
class GameIntroScreen extends StatefulWidget {
  const GameIntroScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const GameIntroScreen(),
    ),
  );

  @override
  State<GameIntroScreen> createState() => _GameIntroScreenState();
}

class _IntroPage {
  const _IntroPage({
    required this.title,
    required this.text,
    required this.speech,
    required this.asset,
    required this.color,
    required this.icon,
  });

  final String title;
  final String text;
  final String speech;
  final String asset;
  final Color color;
  final IconData icon;
}

class _GameIntroScreenState extends State<GameIntroScreen> {
  final _controller = PageController();
  int _page = 0;

  List<_IntroPage> _pages(String petName) => [
    _IntroPage(
      title: 'Привет! Я $petName',
      text:
          'За задания ты получаешь игровые монеты. Реши, как ими '
          'распорядиться, и я буду расти вместе с тобой!',
      speech: 'Монеты можно потратить или отложить.',
      asset: AppAssets.financeCoinSingle,
      color: AppColors.orange,
      icon: Icons.monetization_on_rounded,
    ),
    const _IntroPage(
      title: 'Важное',
      text:
          'То, без чего не обойтись: еда и уход. Сначала '
          'позаботься о важном.',
      speech: 'Без еды я проголодаюсь!',
      asset: AppAssets.foodBasicBowl,
      color: AppColors.primaryBlue,
      icon: Icons.check_circle_rounded,
    ),
    const _IntroPage(
      title: 'Приятное',
      text:
          'То, чего хочется: вкусняшки и игрушки. Их можно купить, '
          'если хватает монет, или отложить на потом.',
      speech: 'Игрушки поднимают настроение.',
      asset: AppAssets.shopTeddy,
      color: AppColors.purple,
      icon: Icons.favorite_rounded,
    ),
    const _IntroPage(
      title: 'Отложить',
      text:
          'Часть монет можно положить в копилку. Понемногу — и '
          'накопишь на большую мечту!',
      speech: 'Маленькие шаги к большой цели!',
      asset: AppAssets.financePiggyBank,
      color: AppColors.green,
      icon: Icons.savings_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    AppScope.of(context).markTutorialSeen();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pages = _pages(state.petName);
    final last = _page == pages.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('intro_skip'),
                onPressed: _finish,
                child: const Text('Пропустить'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) =>
                    _IntroPageView(page: pages[index], index: index),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? AppColors.primaryBlue
                          : AppColors.track,
                      borderRadius: AppRadii.capsule,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: PrimaryGradientButton(
                key: const ValueKey('intro_next'),
                label: last ? 'Начать игру' : 'Дальше',
                onPressed: last
                    ? _finish
                    : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPageView extends StatelessWidget {
  const _IntroPageView({required this.page, required this.index});

  final _IntroPage page;
  final int index;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        color: page.color.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Image.asset(
                      index == 0
                          ? AppAssets.foxSittingHappyLevel05
                          : page.asset,
                      height: index == 0 ? 210 : 150,
                      fit: BoxFit.contain,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      width: 150,
                      child: SpeechBubble(text: page.speech, tilt: -5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (index > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: page.color.withAlpha(30),
                    borderRadius: AppRadii.capsule,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(page.icon, color: page.color, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Решение $index из 3',
                        style: AppTextStyles.label.copyWith(color: page.color),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.heading.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RoundedSurfaceCard(
                child: Text(
                  page.text,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(fontSize: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Short explanations of the words used in the game (ТЗ 2.5.11).
class GlossaryScreen extends StatelessWidget {
  const GlossaryScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const GlossaryScreen()));

  static const terms = [
    (
      'Бюджет',
      'План: сколько монет пойдёт на важное, на приятное и в копилку.',
      Icons.account_balance_wallet_rounded,
    ),
    (
      'Важное (обязательные расходы)',
      'То, без чего не обойтись: еда и уход за питомцем.',
      Icons.check_circle_rounded,
    ),
    (
      'Приятное (желаемые расходы)',
      'То, чего хочется: вкусняшки и игрушки. Можно отложить на потом.',
      Icons.favorite_rounded,
    ),
    (
      'Копилка (накопления)',
      'Монеты, которые ты отложил. Они не тратятся случайно.',
      Icons.savings_rounded,
    ),
    (
      'Цель',
      'То, на что ты копишь, например велосипед. У цели есть цена.',
      Icons.star_rounded,
    ),
    (
      'Баланс',
      'Сколько монет у тебя есть прямо сейчас.',
      Icons.monetization_on_rounded,
    ),
    (
      'План и факт',
      'План — сколько ты решил потратить. Факт — сколько потратил на самом деле.',
      Icons.compare_arrows_rounded,
    ),
    (
      'Игровой день',
      'Один круг игры: задание, покупки, копилка и итоги дня.',
      Icons.today_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6FB),
        title: Text('Словарик', style: AppTextStyles.cardTitle),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: terms.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) {
          final (term, meaning, icon) = terms[index];
          return RoundedSurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryBlueLight,
                  foregroundColor: AppColors.primaryBlue,
                  child: Icon(icon),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        term,
                        style: AppTextStyles.label.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(meaning, style: AppTextStyles.body),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
