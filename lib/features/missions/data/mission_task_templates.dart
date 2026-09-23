import '../../budget/domain/budget_usage.dart';
import '../domain/mission_models.dart';

abstract final class MissionTaskTemplates {
  static MissionTask calculateRemaining({
    required String id,
    required int startingCoins,
    required List<int> costs,
    int reward = 20,
  }) {
    final answer =
        startingCoins - costs.fold<int>(0, (sum, cost) => sum + cost);
    return MissionTask(
      id: id,
      title: 'Сколько останется?',
      description:
          'Было $startingCoins монет. Покупки стоят ${costs.join(' и ')}.',
      type: MissionTaskType.calculation,
      theme: MissionTheme.math,
      difficulty: MissionDifficulty.easy,
      estimatedSeconds: 60,
      rewardCoins: reward,
      xpReward: 12,
      options: _numberOptions(answer),
      correctOptionId: 'n_$answer',
      explanation: 'Вычитаем стоимость покупок из начальной суммы.',
    );
  }

  static MissionTask calculateChange({
    required String id,
    required int paid,
    required int price,
    int reward = 20,
  }) {
    final answer = paid - price;
    return MissionTask(
      id: id,
      title: 'Посчитай сдачу',
      description: 'Ты дал $paid монет, покупка стоит $price. Сколько сдачи?',
      type: MissionTaskType.calculation,
      theme: MissionTheme.math,
      difficulty: MissionDifficulty.easy,
      estimatedSeconds: 50,
      rewardCoins: reward,
      xpReward: 12,
      options: _numberOptions(answer),
      correctOptionId: 'n_$answer',
      explanation: '$paid − $price = $answer монет сдачи.',
    );
  }

  static MissionTask comparePrices({
    required String id,
    required int priceA,
    required int priceB,
    int reward = 15,
  }) {
    final correct = priceA <= priceB ? 'a' : 'b';
    return MissionTask(
      id: id,
      title: 'Где выгоднее?',
      description: 'Один и тот же товар продаётся по разной цене.',
      type: MissionTaskType.choice,
      theme: MissionTheme.shopping,
      difficulty: MissionDifficulty.easy,
      estimatedSeconds: 45,
      rewardCoins: reward,
      xpReward: 10,
      options: [
        MissionTaskOption(
          id: 'a',
          label: 'Магазин А',
          subtitle: '$priceA монет',
        ),
        MissionTaskOption(
          id: 'b',
          label: 'Магазин Б',
          subtitle: '$priceB монет',
        ),
      ],
      correctOptionId: correct,
      explanation: 'Выгоднее выбрать меньшую цену и сохранить разницу.',
    );
  }

  static MissionTask needOrWant({
    required String id,
    required Map<String, String> items,
    int reward = 20,
  }) {
    return MissionTask(
      id: id,
      title: 'Нужно или хочу?',
      description: 'Распредели покупки по двум группам.',
      type: MissionTaskType.classification,
      theme: MissionTheme.shopping,
      difficulty: MissionDifficulty.easy,
      estimatedSeconds: 90,
      rewardCoins: reward,
      xpReward: 16,
      options: [
        for (final entry in items.entries)
          MissionTaskOption(
            id: '${id}_${entry.key}',
            label: entry.key,
            category: entry.value,
          ),
      ],
      explanation:
          'Необходимые покупки важны сейчас, а желания можно запланировать.',
    );
  }

  static MissionTask budgetSplit({
    required String id,
    required int total,
    int reward = 25,
  }) {
    return MissionTask(
      id: id,
      title: 'Распредели бюджет',
      description: 'Разложи ровно $total монет по трём категориям.',
      type: MissionTaskType.budgetSplit,
      theme: MissionTheme.savings,
      difficulty: MissionDifficulty.medium,
      estimatedSeconds: 120,
      rewardCoins: reward,
      xpReward: 20,
      totalAmount: total,
      stepAmount: 50,
      options: const [
        MissionTaskOption(id: 'needs', label: 'Обязательное'),
        MissionTaskOption(id: 'fun', label: 'Развлечения'),
        MissionTaskOption(id: 'savings', label: 'Накопления'),
      ],
      explanation:
          'Весь бюджет распределён: у каждой монеты появилось своё место.',
    );
  }

  static MissionTask savingChoice({required String id, int reward = 15}) {
    return MissionTask(
      id: id,
      title: 'Что сделать с наградой?',
      description: 'Ты получил 100 монет. Выбери разумный вариант.',
      type: MissionTaskType.choice,
      theme: MissionTheme.savings,
      difficulty: MissionDifficulty.easy,
      estimatedSeconds: 55,
      rewardCoins: reward,
      xpReward: 12,
      options: const [
        MissionTaskOption(
          id: 'save_part',
          label: 'Отложить 50',
          subtitle: 'Остальное оставить на расходы',
          savingsReward: 50,
          feedback: 'Часть награды отправилась к большой цели.',
        ),
        MissionTaskOption(
          id: 'spend_all',
          label: 'Потратить всё',
          subtitle: 'На случайные мелочи',
          feedback: 'Иногда полезно сначала решить, что действительно нужно.',
        ),
      ],
      correctOptionId: 'save_part',
      explanation: 'Небольшая регулярная сумма помогает быстрее достичь цели.',
    );
  }

  static MissionTask spendingChoice({required String id, int reward = 15}) {
    return MissionTask(
      id: id,
      title: 'Выбери покупку',
      description: 'У тебя есть 300 монет. Как поступить?',
      type: MissionTaskType.choice,
      theme: MissionTheme.shopping,
      difficulty: MissionDifficulty.medium,
      estimatedSeconds: 75,
      rewardCoins: reward,
      xpReward: 14,
      options: const [
        MissionTaskOption(
          id: 'toy',
          label: 'Игрушка',
          subtitle: '280 монет',
          spendCoins: 280,
          expenseCategory: ExpenseCategory.want,
          feedback: 'Покупка возможна, но почти весь бюджет будет потрачен.',
        ),
        MissionTaskOption(
          id: 'lunch',
          label: 'Обед',
          subtitle: '150 монет',
          spendCoins: 150,
          expenseCategory: ExpenseCategory.essential,
          feedback: 'Обед — необходимая трата, и часть монет останется.',
        ),
        MissionTaskOption(
          id: 'lunch_save',
          label: 'Обед + копилка',
          subtitle: '150 потратить, 100 отложить',
          spendCoins: 150,
          expenseCategory: ExpenseCategory.essential,
          savingsReward: 100,
          feedback: 'Нужная покупка сделана, а часть денег отправилась к цели.',
        ),
      ],
      correctOptionId: 'lunch_save',
      explanation: 'Можно совместить необходимую покупку и накопление.',
    );
  }

  static MissionTask logicSequence({
    required String id,
    required String sequence,
    required List<String> variants,
    required String answer,
    int reward = 20,
  }) {
    return MissionTask(
      id: id,
      title: 'Продолжи ряд',
      description: '$sequence  ...',
      type: MissionTaskType.logic,
      theme: MissionTheme.logic,
      difficulty: MissionDifficulty.easy,
      estimatedSeconds: 60,
      rewardCoins: reward,
      xpReward: 14,
      options: [
        for (final value in variants)
          MissionTaskOption(id: '${id}_$value', label: value),
      ],
      correctOptionId: '${id}_$answer',
      explanation: 'Элементы повторяются по заметному правилу.',
    );
  }

  static MissionTask logicPair({required String id, int reward = 15}) {
    return MissionTask(
      id: id,
      title: 'Найди пару',
      description: 'Копилка относится к накоплениям. Кошелёк относится к…',
      type: MissionTaskType.matching,
      theme: MissionTheme.logic,
      difficulty: MissionDifficulty.easy,
      estimatedSeconds: 45,
      rewardCoins: reward,
      xpReward: 10,
      options: const [
        MissionTaskOption(id: 'spending', label: 'Текущим деньгам'),
        MissionTaskOption(id: 'weather', label: 'Погоде'),
        MissionTaskOption(id: 'sport', label: 'Спорту'),
      ],
      correctOptionId: 'spending',
      explanation: 'Кошелёк хранит деньги для текущих покупок.',
    );
  }

  static MissionTask findBestOffer({required String id, int reward = 20}) {
    return MissionTask(
      id: id,
      title: 'Лучшее предложение',
      description: 'Выбери одинаковый набор по самой низкой цене.',
      type: MissionTaskType.choice,
      theme: MissionTheme.shopping,
      difficulty: MissionDifficulty.medium,
      estimatedSeconds: 70,
      rewardCoins: reward,
      xpReward: 14,
      options: const [
        MissionTaskOption(id: 'one', label: 'Набор А', subtitle: '190 монет'),
        MissionTaskOption(id: 'two', label: 'Набор Б', subtitle: '160 монет'),
        MissionTaskOption(id: 'three', label: 'Набор В', subtitle: '210 монет'),
      ],
      correctOptionId: 'two',
      explanation: 'При одинаковом составе выгоднее набор за 160 монет.',
    );
  }

  static MissionTask attentionMatch({required String id, int reward = 15}) {
    return MissionTask(
      id: id,
      title: 'Будь внимателен',
      description: 'Какая покупка стоит ровно 80 монет?',
      type: MissionTaskType.attention,
      theme: MissionTheme.entertainment,
      difficulty: MissionDifficulty.easy,
      estimatedSeconds: 40,
      rewardCoins: reward,
      xpReward: 10,
      options: const [
        MissionTaskOption(id: 'juice', label: 'Сок', subtitle: '60 монет'),
        MissionTaskOption(
          id: 'notebook',
          label: 'Тетрадь',
          subtitle: '80 монет',
        ),
        MissionTaskOption(id: 'ball', label: 'Мяч', subtitle: '120 монет'),
      ],
      correctOptionId: 'notebook',
      explanation: 'Цена тетради совпадает с условием — 80 монет.',
    );
  }

  static MissionTask classifyPurchase({required String id, int reward = 20}) {
    return needOrWant(
      id: id,
      reward: reward,
      items: const {
        'Проездной': 'НУЖНО',
        'Блестящий брелок': 'ХОЧУ',
        'Учебная тетрадь': 'НУЖНО',
        'Вторая кепка': 'ХОЧУ',
      },
    );
  }

  static MissionTask countObjects({
    required String id,
    required int count,
    int reward = 15,
  }) {
    return MissionTask(
      id: id,
      title: 'Сосчитай монеты',
      description:
          '${List.filled(count, '🪙').join(' ')}\nСколько монет на экране?',
      type: MissionTaskType.attention,
      theme: MissionTheme.math,
      difficulty: MissionDifficulty.easy,
      estimatedSeconds: 35,
      rewardCoins: reward,
      xpReward: 8,
      options: _numberOptions(count, step: 1),
      correctOptionId: 'n_$count',
      explanation: 'Здесь $count монет.',
    );
  }

  static MissionTask choosePriority({required String id, int reward = 15}) {
    return MissionTask(
      id: id,
      title: 'Что важнее сейчас?',
      description: 'Перед школой порвался рюкзак. Что выбрать первым?',
      type: MissionTaskType.choice,
      theme: MissionTheme.shopping,
      difficulty: MissionDifficulty.easy,
      estimatedSeconds: 50,
      rewardCoins: reward,
      xpReward: 12,
      options: const [
        MissionTaskOption(
          id: 'backpack',
          label: 'Новый рюкзак',
          subtitle: '300 из копилки',
          spendFromSavings: 300,
          expenseCategory: ExpenseCategory.essential,
          feedback: 'На важную вещь ушла часть накоплений. До цели немного дальше, зато рюкзак куплен.',
        ),
        MissionTaskOption(
          id: 'decoration',
          label: 'Украшение для комнаты',
          subtitle: '300 из копилки',
          spendFromSavings: 300,
          expenseCategory: ExpenseCategory.want,
          feedback: 'Покупка возможна, но на большую цель теперь придётся копить дольше.',
        ),
      ],
      correctOptionId: 'backpack',
      explanation: 'Необходимую вещь разумно поставить выше необязательной.',
    );
  }

  static MissionTask quickQuiz({required String id, int reward = 15}) {
    return MissionTask(
      id: id,
      title: 'Быстрый вопрос',
      description: 'Что помогает не потратить все монеты сразу?',
      type: MissionTaskType.quiz,
      theme: MissionTheme.savings,
      difficulty: MissionDifficulty.easy,
      estimatedSeconds: 40,
      rewardCoins: reward,
      xpReward: 10,
      options: const [
        MissionTaskOption(id: 'plan', label: 'Простой план расходов'),
        MissionTaskOption(id: 'rush', label: 'Покупать первое, что увидел'),
        MissionTaskOption(id: 'ignore', label: 'Не смотреть на цену'),
      ],
      correctOptionId: 'plan',
      explanation: 'План помогает помнить о нужных расходах и накоплениях.',
    );
  }

  static List<MissionTaskOption> _numberOptions(int answer, {int step = 100}) {
    final values = <int>{answer, answer + step, answer - step};
    if (values.any((value) => value < 0)) {
      values
        ..removeWhere((value) => value < 0)
        ..add(answer + step * 2);
    }
    return [
      for (final value in values.toList()..sort())
        MissionTaskOption(id: 'n_$value', label: '$value монет'),
    ];
  }
}
