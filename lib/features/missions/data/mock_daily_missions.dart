import '../domain/mission_models.dart';
import 'mission_task_templates.dart';

abstract final class MockDailyMissions {
  static DailyMission get today => todayFor(DifficultyLevel.middle);

  static DailyMission todayFor(DifficultyLevel level) {
    final profile = switch (level) {
      DifficultyLevel.junior => const _MathProfile(
        countA: 5,
        remainingStartA: 20,
        remainingCostsA: [5],
        changePaidA: 30,
        changePriceA: 10,
        priceA: 20,
        priceB: 15,
        remainingStartB: 30,
        remainingCostsB: [10],
        budget: 100,
        changePaidB: 40,
        changePriceB: 15,
        countB: 6,
        sequence: '2  •  4  •  6',
        sequenceVariants: ['7', '8', '10'],
        sequenceAnswer: '8',
      ),
      DifficultyLevel.middle => const _MathProfile(
        countA: 6,
        remainingStartA: 100,
        remainingCostsA: [35],
        changePaidA: 150,
        changePriceA: 70,
        priceA: 170,
        priceB: 140,
        remainingStartB: 200,
        remainingCostsB: [50, 35],
        budget: 300,
        changePaidB: 300,
        changePriceB: 180,
        countB: 8,
        sequence: '10  •  20  •  30',
        sequenceVariants: ['35', '40', '50'],
        sequenceAnswer: '40',
      ),
      DifficultyLevel.senior => const _MathProfile(
        countA: 8,
        remainingStartA: 500,
        remainingCostsA: [280],
        changePaidA: 700,
        changePriceA: 365,
        priceA: 425,
        priceB: 390,
        remainingStartB: 900,
        remainingCostsB: [275, 185],
        budget: 600,
        changePaidB: 1000,
        changePriceB: 635,
        countB: 10,
        sequence: '75  •  150  •  225',
        sequenceVariants: ['250', '300', '325'],
        sequenceAnswer: '300',
      ),
    };

    MissionTask adaptive(MissionTask task) => task.forDifficulty(level);
    return DailyMission(
      id: 'math_game_center_2026_09_19_${level.name}',
      date: DateTime(2026, 9, 19),
      locationId: 'game_center',
      title: 'День математики',
      theme: MissionTheme.math,
      estimatedMinutes: level == DifficultyLevel.junior ? 18 : 25,
      maxReward: 250,
      tasks: [
        adaptive(
          MissionTaskTemplates.countObjects(
            id: 'math_01',
            count: profile.countA,
          ),
        ),
        adaptive(
          MissionTaskTemplates.calculateRemaining(
            id: 'math_02',
            startingCoins: profile.remainingStartA,
            costs: profile.remainingCostsA,
          ),
        ),
        adaptive(
          MissionTaskTemplates.calculateChange(
            id: 'math_03',
            paid: profile.changePaidA,
            price: profile.changePriceA,
          ),
        ),
        adaptive(
          MissionTaskTemplates.comparePrices(
            id: 'math_04',
            priceA: profile.priceA,
            priceB: profile.priceB,
          ),
        ),
        adaptive(
          MissionTaskTemplates.calculateRemaining(
            id: 'math_05',
            startingCoins: profile.remainingStartB,
            costs: profile.remainingCostsB,
          ),
        ),
        adaptive(
          MissionTaskTemplates.budgetSplit(
            id: 'math_06',
            total: profile.budget,
          ),
        ),
        adaptive(
          MissionTaskTemplates.calculateChange(
            id: 'math_07',
            paid: profile.changePaidB,
            price: profile.changePriceB,
          ),
        ),
        adaptive(
          MissionTaskTemplates.countObjects(
            id: 'math_08',
            count: profile.countB,
          ),
        ),
        adaptive(
          MissionTaskTemplates.logicSequence(
            id: 'math_09',
            sequence: profile.sequence,
            variants: profile.sequenceVariants,
            answer: profile.sequenceAnswer,
          ),
        ),
        adaptive(MissionTaskTemplates.spendingChoice(id: 'math_10')),
        adaptive(MissionTaskTemplates.savingChoice(id: 'math_11')),
        adaptive(MissionTaskTemplates.quickQuiz(id: 'math_12')),
      ],
    );
  }

  static final DailyMission mathDay = DailyMission(
    id: 'math_game_center_2026_09_19',
    date: DateTime(2026, 9, 19),
    locationId: 'game_center',
    title: 'День математики',
    theme: MissionTheme.math,
    estimatedMinutes: 25,
    maxReward: 250,
    tasks: [
      MissionTaskTemplates.countObjects(id: 'math_01', count: 6),
      MissionTaskTemplates.calculateRemaining(
        id: 'math_02',
        startingCoins: 500,
        costs: const [180, 120],
      ),
      MissionTaskTemplates.calculateChange(
        id: 'math_03',
        paid: 500,
        price: 230,
      ),
      MissionTaskTemplates.comparePrices(
        id: 'math_04',
        priceA: 170,
        priceB: 140,
      ),
      MissionTaskTemplates.calculateRemaining(
        id: 'math_05',
        startingCoins: 600,
        costs: const [150, 200],
      ),
      MissionTaskTemplates.budgetSplit(id: 'math_06', total: 600),
      MissionTaskTemplates.calculateChange(
        id: 'math_07',
        paid: 300,
        price: 180,
      ),
      MissionTaskTemplates.countObjects(id: 'math_08', count: 8),
      MissionTaskTemplates.logicSequence(
        id: 'math_09',
        sequence: '10  •  20  •  30',
        variants: const ['35', '40', '50'],
        answer: '40',
      ),
      MissionTaskTemplates.spendingChoice(id: 'math_10'),
      MissionTaskTemplates.savingChoice(id: 'math_11'),
      MissionTaskTemplates.quickQuiz(id: 'math_12'),
    ],
  );

  static final DailyMission logicDay = DailyMission(
    id: 'logic_game_center_2026_09_20',
    date: DateTime(2026, 9, 20),
    locationId: 'game_center',
    title: 'День логики',
    theme: MissionTheme.logic,
    estimatedMinutes: 22,
    maxReward: 240,
    tasks: [
      MissionTaskTemplates.logicSequence(
        id: 'logic_01',
        sequence: '⭐  •  🪙  •  ⭐  •  🪙',
        variants: const ['⭐', '🎁', '🧮'],
        answer: '⭐',
      ),
      MissionTaskTemplates.logicPair(id: 'logic_02'),
      MissionTaskTemplates.attentionMatch(id: 'logic_03'),
      MissionTaskTemplates.logicSequence(
        id: 'logic_04',
        sequence: '2  •  4  •  6',
        variants: const ['7', '8', '10'],
        answer: '8',
      ),
      MissionTaskTemplates.classifyPurchase(id: 'logic_05'),
      MissionTaskTemplates.logicPair(id: 'logic_06'),
      MissionTaskTemplates.countObjects(id: 'logic_07', count: 7),
      MissionTaskTemplates.logicSequence(
        id: 'logic_08',
        sequence: '🔵  •  🔵  •  🟡  •  🔵  •  🔵',
        variants: const ['🟡', '🔴', '🔵'],
        answer: '🟡',
      ),
      MissionTaskTemplates.comparePrices(
        id: 'logic_09',
        priceA: 95,
        priceB: 105,
      ),
      MissionTaskTemplates.findBestOffer(id: 'logic_10'),
      MissionTaskTemplates.choosePriority(id: 'logic_11'),
      MissionTaskTemplates.quickQuiz(id: 'logic_12'),
    ],
  );

  static final DailyMission shoppingDay = DailyMission(
    id: 'shopping_game_center_2026_09_21',
    date: DateTime(2026, 9, 21),
    locationId: 'game_center',
    title: 'День покупок',
    theme: MissionTheme.shopping,
    estimatedMinutes: 27,
    maxReward: 245,
    tasks: [
      MissionTaskTemplates.needOrWant(
        id: 'shopping_01',
        items: const {
          'Обед': 'НУЖНО',
          'Новая игрушка': 'ХОЧУ',
          'Тетрадь': 'НУЖНО',
          'Декоративная кепка': 'ХОЧУ',
        },
      ),
      MissionTaskTemplates.comparePrices(
        id: 'shopping_02',
        priceA: 170,
        priceB: 140,
      ),
      MissionTaskTemplates.spendingChoice(id: 'shopping_03'),
      MissionTaskTemplates.findBestOffer(id: 'shopping_04'),
      MissionTaskTemplates.calculateChange(
        id: 'shopping_05',
        paid: 500,
        price: 320,
      ),
      MissionTaskTemplates.classifyPurchase(id: 'shopping_06'),
      MissionTaskTemplates.choosePriority(id: 'shopping_07'),
      MissionTaskTemplates.attentionMatch(id: 'shopping_08'),
      MissionTaskTemplates.comparePrices(
        id: 'shopping_09',
        priceA: 220,
        priceB: 185,
      ),
      MissionTaskTemplates.calculateRemaining(
        id: 'shopping_10',
        startingCoins: 700,
        costs: const [250, 150],
      ),
      MissionTaskTemplates.savingChoice(id: 'shopping_11'),
      MissionTaskTemplates.quickQuiz(id: 'shopping_12'),
    ],
  );

  static final DailyMission mixedDay = DailyMission(
    id: 'mixed_game_center_2026_09_22',
    date: DateTime(2026, 9, 22),
    locationId: 'game_center',
    title: 'Смешанный день',
    theme: MissionTheme.mixed,
    estimatedMinutes: 24,
    maxReward: 250,
    tasks: [
      MissionTaskTemplates.calculateRemaining(
        id: 'mixed_01',
        startingCoins: 450,
        costs: const [120, 130],
      ),
      MissionTaskTemplates.logicSequence(
        id: 'mixed_02',
        sequence: '🪙  •  ⭐  •  🪙  •  ⭐',
        variants: const ['🪙', '🎁', '🧮'],
        answer: '🪙',
      ),
      MissionTaskTemplates.needOrWant(
        id: 'mixed_03',
        items: const {
          'Завтрак': 'НУЖНО',
          'Наклейки': 'ХОЧУ',
          'Ручка': 'НУЖНО',
          'Игровой скин': 'ХОЧУ',
        },
      ),
      MissionTaskTemplates.budgetSplit(id: 'mixed_04', total: 600),
      MissionTaskTemplates.attentionMatch(id: 'mixed_05'),
      MissionTaskTemplates.spendingChoice(id: 'mixed_06'),
      MissionTaskTemplates.logicPair(id: 'mixed_07'),
      MissionTaskTemplates.countObjects(id: 'mixed_08', count: 5),
      MissionTaskTemplates.choosePriority(id: 'mixed_09'),
      MissionTaskTemplates.findBestOffer(id: 'mixed_10'),
      MissionTaskTemplates.savingChoice(id: 'mixed_11'),
      MissionTaskTemplates.quickQuiz(id: 'mixed_12'),
    ],
  );

  static List<DailyMission> get all => [
    mathDay,
    logicDay,
    shoppingDay,
    mixedDay,
  ];
}

class _MathProfile {
  const _MathProfile({
    required this.countA,
    required this.remainingStartA,
    required this.remainingCostsA,
    required this.changePaidA,
    required this.changePriceA,
    required this.priceA,
    required this.priceB,
    required this.remainingStartB,
    required this.remainingCostsB,
    required this.budget,
    required this.changePaidB,
    required this.changePriceB,
    required this.countB,
    required this.sequence,
    required this.sequenceVariants,
    required this.sequenceAnswer,
  });

  final int countA;
  final int remainingStartA;
  final List<int> remainingCostsA;
  final int changePaidA;
  final int changePriceA;
  final int priceA;
  final int priceB;
  final int remainingStartB;
  final List<int> remainingCostsB;
  final int budget;
  final int changePaidB;
  final int changePriceB;
  final int countB;
  final String sequence;
  final List<String> sequenceVariants;
  final String sequenceAnswer;
}
