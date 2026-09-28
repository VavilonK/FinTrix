import '../../budget/domain/budget_usage.dart';
import '../domain/mission_models.dart';

abstract final class DailyTaskTemplates {
  static const List<String> allTemplateIds = [
    'count_coins',
    'calculate_remaining',
    'can_afford',
    'best_price',
    'need_or_want',
    'buy_first',
    'build_basket',
    'split_budget',
    'choose_entertainment',
    'lunch_time',
    'buy_stationery',
    'choose_transport',
    'odd_one_out',
    'continue_sequence',
    'match_pairs',
    'fix_fox_mistake',
    'choose_route',
    'find_coins',
    'remember_purchases',
    'repeat_after_fox',
    'quick_sort',
    'compare_prices',
    'cultural_outing',
    'fix_receipt',
    'split_reward',
    'goal_days',
  ];

  /// Savings scenarios; every generated mission contains one (ТЗ 2.5.8).
  static const List<String> savingsTemplateIds = ['split_reward', 'goal_days'];

  static const Set<String> realExpenseTemplateIds = {
    'choose_entertainment',
    'lunch_time',
    'buy_stationery',
    'choose_transport',
    'cultural_outing',
  };

  static TaskTheme themeFor(String templateId) => switch (templateId) {
    'count_coins' ||
    'calculate_remaining' ||
    'can_afford' ||
    'best_price' ||
    'build_basket' ||
    'fix_fox_mistake' ||
    'compare_prices' ||
    'fix_receipt' => TaskTheme.math,
    'need_or_want' ||
    'buy_first' ||
    'split_budget' ||
    'quick_sort' => TaskTheme.finance,
    'odd_one_out' ||
    'continue_sequence' ||
    'match_pairs' ||
    'choose_route' => TaskTheme.logic,
    'find_coins' => TaskTheme.attention,
    'remember_purchases' || 'repeat_after_fox' => TaskTheme.memory,
    'choose_entertainment' ||
    'lunch_time' ||
    'buy_stationery' ||
    'choose_transport' ||
    'cultural_outing' => TaskTheme.entertainment,
    _ => TaskTheme.finance,
  };

  static MissionTask build({
    required String templateId,
    required String id,
    required DifficultyLevel difficulty,
    required int variant,
    required int availableBalance,
  }) {
    return switch (templateId) {
      'count_coins' => _countCoins(id, difficulty, variant),
      'calculate_remaining' => _calculateRemaining(id, difficulty, variant),
      'can_afford' => _canAfford(id, difficulty, variant),
      'best_price' => _bestPrice(id, difficulty, variant),
      'need_or_want' => _needOrWant(id, difficulty, variant),
      'buy_first' => _buyFirst(id, difficulty, variant),
      'build_basket' => _buildBasket(id, difficulty, variant),
      'split_budget' => _splitBudget(id, difficulty, variant),
      'choose_entertainment' => _realChoice(
        id: id,
        templateId: templateId,
        title: 'Выбери развлечение',
        description: 'Выбери одно развлечение, которое тебе по карману.',
        difficulty: difficulty,
        variant: variant,
        availableBalance: availableBalance,
        category: ExpenseCategory.want,
        labels: const ['Игровой автомат', 'Автодром', 'Аттракцион'],
        prices: const [20, 35, 40],
      ),
      'lunch_time' => _realChoice(
        id: id,
        templateId: templateId,
        title: 'Время обеда',
        description: 'Выбери подходящий обед. Это настоящая трата.',
        difficulty: difficulty,
        variant: variant,
        availableBalance: availableBalance,
        category: ExpenseCategory.essential,
        labels: const ['Суп и хлеб', 'Каша и сок', 'Обед-комбо'],
        prices: const [25, 30, 45],
      ),
      'buy_stationery' => _realChoice(
        id: id,
        templateId: templateId,
        title: 'Купи канцелярию',
        description: 'Для занятия нужен расходуемый набор.',
        difficulty: difficulty,
        variant: variant,
        availableBalance: availableBalance,
        category: ExpenseCategory.essential,
        labels: const ['Тетрадь', 'Ручка и тетрадь', 'Учебный набор'],
        prices: const [15, 25, 40],
      ),
      'choose_transport' => _realChoice(
        id: id,
        templateId: templateId,
        title: 'Доберись до места',
        description: 'Выбери транспорт. Билет спишется с баланса.',
        difficulty: difficulty,
        variant: variant,
        availableBalance: availableBalance,
        category: ExpenseCategory.essential,
        labels: const ['Автобус', 'Метро', 'Автобус + метро'],
        prices: const [15, 20, 30],
      ),
      'odd_one_out' => _oddOneOut(id, difficulty, variant),
      'continue_sequence' => _continueSequence(id, difficulty, variant),
      'match_pairs' => _matchPairs(id, difficulty, variant),
      'fix_fox_mistake' => _fixFoxMistake(id, difficulty, variant),
      'choose_route' => _chooseRoute(id, difficulty, variant),
      'find_coins' => _findCoins(id, difficulty, variant),
      'remember_purchases' => _rememberPurchases(id, difficulty, variant),
      'repeat_after_fox' => _repeatAfterFox(id, difficulty, variant),
      'quick_sort' => _quickSort(id, difficulty, variant),
      'compare_prices' => _comparePrices(id, difficulty, variant),
      'cultural_outing' => _realChoice(
        id: id,
        templateId: templateId,
        title: 'Культурный выход',
        description: 'Выбери впечатление на сегодня.',
        difficulty: difficulty,
        variant: variant,
        availableBalance: availableBalance,
        category: ExpenseCategory.want,
        labels: const ['Музей', 'Интерактивная выставка', 'Кино'],
        prices: const [30, 40, 45],
      ),
      'fix_receipt' => _fixReceipt(id, difficulty, variant),
      'split_reward' => _splitReward(id, difficulty, variant),
      'goal_days' => _goalDays(id, difficulty, variant),
      _ => _canAfford(id, difficulty, variant),
    };
  }

  static MissionTask _countCoins(
    String id,
    DifficultyLevel level,
    int variant,
  ) {
    final (description, answer) = switch (level) {
      DifficultyLevel.junior => (
        '${List.filled(4 + variant % 7, '🪙').join(' ')}\nСколько монет?',
        4 + variant % 7,
      ),
      DifficultyLevel.middle => (
        'Монеты: 10 + 10 + 5 + ${5 + (variant % 2) * 5}. Сколько всего?',
        30 + (variant % 2) * 5,
      ),
      DifficultyLevel.senior => (
        '4 монеты по 20, 3 по 10 и ${5 + variant % 3} монет.',
        115 + variant % 3,
      ),
    };
    return _numberTask(
      id: id,
      templateId: 'count_coins',
      title: 'Сосчитай монеты',
      description: description,
      answer: answer,
      level: level,
      economyType: TaskEconomyType.earning,
      rewardCoins: 20,
      explanation: 'Складываем номиналы всех монет.',
      variant: variant,
    );
  }

  static MissionTask _calculateRemaining(
    String id,
    DifficultyLevel level,
    int variant,
  ) {
    final start = switch (level) {
      DifficultyLevel.junior => 20 + (variant % 2) * 10,
      DifficultyLevel.middle => 100 + (variant % 2) * 50,
      DifficultyLevel.senior => 500 + (variant % 2) * 200,
    };
    final costs = switch (level) {
      DifficultyLevel.junior => [5 + (variant % 2) * 5],
      DifficultyLevel.middle => [35 + (variant % 2) * 5],
      DifficultyLevel.senior => [180 + (variant % 3) * 50, 70],
    };
    final answer = start - costs.fold<int>(0, (sum, value) => sum + value);
    return _numberTask(
      id: id,
      templateId: 'calculate_remaining',
      title: 'Сколько останется?',
      description:
          'Представь: у Рыжика $start учебных монет. Он тратит ${costs.join(' и ')}.',
      answer: answer,
      level: level,
      economyType: TaskEconomyType.simulation,
      explanation:
          '$start − ${costs.join(' − ')} = $answer. Это были учебные монеты.',
      variant: variant,
    );
  }

  static MissionTask _canAfford(String id, DifficultyLevel level, int variant) {
    final available = switch (level) {
      DifficultyLevel.junior => 30,
      DifficultyLevel.middle => 90 + variant % 3 * 10,
      DifficultyLevel.senior => 350 + variant % 3 * 50,
    };
    final price = switch (level) {
      DifficultyLevel.junior => 25,
      DifficultyLevel.middle => available + 15,
      DifficultyLevel.senior => available - 85,
    };
    final correct = available >= price ? 'yes' : 'no';
    return _choiceTask(
      id: id,
      templateId: 'can_afford',
      title: 'Хватит ли денег?',
      description: 'Есть $available учебных монет, цена — $price.',
      taskTheme: TaskTheme.math,
      level: level,
      options: [
        const MissionTaskOption(id: 'yes', label: 'Да, хватит'),
        MissionTaskOption(
          id: 'no',
          label: 'Нет',
          subtitle: available < price
              ? 'Не хватает ${price - available}'
              : null,
        ),
      ],
      correctOptionId: correct,
      explanation: available >= price
          ? 'Денег хватает, и ещё останется ${available - price}.'
          : 'До цены не хватает ${price - available} монет.',
      variant: variant,
    );
  }

  static MissionTask _bestPrice(String id, DifficultyLevel level, int variant) {
    final delivery = level == DifficultyLevel.senior ? 20 : 0;
    final a = 45 + variant % 3 * 5;
    final b = 40 + variant % 2 * 5 + delivery;
    return _choiceTask(
      id: id,
      templateId: 'best_price',
      title: 'Где выгоднее?',
      description: level == DifficultyLevel.senior
          ? 'Учти цену и условную доставку.'
          : 'Один товар продают по двум ценам.',
      taskTheme: TaskTheme.math,
      level: level,
      options: [
        MissionTaskOption(id: 'a', label: 'Магазин А', subtitle: '$a монет'),
        MissionTaskOption(
          id: 'b',
          label: 'Магазин Б',
          subtitle: level == DifficultyLevel.senior
              ? '${b - delivery} + $delivery за доставку'
              : '$b монет',
        ),
      ],
      correctOptionId: a <= b ? 'a' : 'b',
      explanation: 'Сравниваем полную стоимость: $a и $b.',
      variant: variant,
    );
  }

  static MissionTask _needOrWant(
    String id,
    DifficultyLevel level,
    int variant,
  ) {
    final entries = switch (level) {
      DifficultyLevel.junior => const {
        'Вода': 'НУЖНО',
        'Игрушка': 'ХОЧУ',
        'Обед': 'НУЖНО',
      },
      DifficultyLevel.middle => const {
        'Тетрадь': 'НУЖНО',
        'Сувенир': 'ХОЧУ',
        'Проезд': 'НУЖНО',
        'Сладость': 'ХОЧУ',
      },
      DifficultyLevel.senior => const {
        'Теплая куртка зимой': 'НУЖНО',
        'Вторая кепка': 'ХОЧУ',
        'Билет в школу': 'НУЖНО',
        'Декор комнаты': 'ХОЧУ',
      },
    };
    return MissionTask(
      id: id,
      templateId: 'need_or_want',
      title: 'Нужно или хочу?',
      description: 'Разложи карточки по двум зонам.',
      type: MissionTaskType.classification,
      theme: MissionTheme.shopping,
      taskTheme: TaskTheme.finance,
      economyType: TaskEconomyType.simulation,
      difficulty: _visualDifficulty(level),
      difficultyLevel: level,
      estimatedSeconds: 80,
      rewardCoins: 0,
      xpReward: 16,
      options: [
        for (final entry in entries.entries)
          MissionTaskOption(
            id: '${id}_${entry.key}',
            label: entry.key,
            category: entry.value,
          ),
      ],
      explanation: 'Снача заботимся о нужном, а желания планируем.',
      scenarioKey: 'need_${level.name}_${variant % 3}',
    );
  }

  static MissionTask _buyFirst(String id, DifficultyLevel level, int variant) {
    return _choiceTask(
      id: id,
      templateId: 'buy_first',
      title: 'Что купить первым?',
      description: level == DifficultyLevel.senior
          ? 'Учебный бюджет 500. Какой расход важнее сейчас?'
          : 'Перед дорогой нужно решить, что важнее.',
      taskTheme: TaskTheme.finance,
      level: level,
      options: const [
        MissionTaskOption(id: 'water', label: 'Вода и обед'),
        MissionTaskOption(id: 'toy', label: 'Игрушка'),
        MissionTaskOption(id: 'souvenir', label: 'Сувенир'),
      ],
      correctOptionId: 'water',
      explanation: 'Еда и вода важнее необязательной покупки.',
      variant: variant,
    );
  }

  static MissionTask _buildBasket(
    String id,
    DifficultyLevel level,
    int variant,
  ) {
    final budget = switch (level) {
      DifficultyLevel.junior => 50,
      DifficultyLevel.middle => 100,
      DifficultyLevel.senior => 180,
    };
    return _choiceTask(
      id: id,
      templateId: 'build_basket',
      title: 'Собери корзину',
      description: 'Учебный бюджет — $budget. Какая корзина подходит?',
      taskTheme: TaskTheme.math,
      level: level,
      options: [
        MissionTaskOption(
          id: 'ok',
          label: 'Яблоко + вода',
          subtitle: '${budget - 10} монет',
        ),
        MissionTaskOption(
          id: 'over',
          label: 'Сок + десерт',
          subtitle: '${budget + 20} монет',
        ),
        MissionTaskOption(
          id: 'exact',
          label: 'Хлеб + сыр',
          subtitle: '$budget монет',
        ),
      ],
      correctOptionId: level == DifficultyLevel.senior ? 'ok' : 'exact',
      explanation: level == DifficultyLevel.senior
          ? 'Корзина стоит ${budget - 10}, и 10 монет остаются.'
          : 'Эта корзина точно укладывается в учебный бюджет.',
      variant: variant,
    );
  }

  static MissionTask _splitBudget(
    String id,
    DifficultyLevel level,
    int variant,
  ) {
    final total = switch (level) {
      DifficultyLevel.junior => 100,
      DifficultyLevel.middle => 300,
      DifficultyLevel.senior => 600,
    };
    return MissionTask(
      id: id,
      templateId: 'split_budget',
      title: 'Распредели бюджет',
      description:
          'Разложи $total учебных монет. Реальный баланс не изменится.',
      type: MissionTaskType.budgetSplit,
      theme: MissionTheme.savings,
      taskTheme: TaskTheme.finance,
      economyType: TaskEconomyType.simulation,
      difficulty: _visualDifficulty(level),
      difficultyLevel: level,
      estimatedSeconds: 110,
      rewardCoins: 0,
      xpReward: 18,
      totalAmount: total,
      stepAmount: level == DifficultyLevel.junior ? 20 : 10,
      options: const [
        MissionTaskOption(id: 'needs', label: 'На важное'),
        MissionTaskOption(id: 'fun', label: 'На приятное'),
        MissionTaskOption(id: 'dream', label: 'На мечту'),
      ],
      explanation: 'Это тренировка: у каждой монеты появилась цель.',
      scenarioKey: 'split_${level.name}_${variant % 3}',
    );
  }

  static MissionTask _oddOneOut(String id, DifficultyLevel level, int variant) {
    final options = level == DifficultyLevel.junior
        ? const ['Монета', 'Копилка', 'Кошелёк', 'Яблоко']
        : const ['Цена', 'Чек', 'Скидка', 'Прогноз погоды'];
    return _simpleLabelsTask(
      id: id,
      templateId: 'odd_one_out',
      title: 'Что лишнее?',
      description: 'Три карточки связаны. Найди лишнюю.',
      labels: options,
      correctIndex: 3,
      taskTheme: TaskTheme.logic,
      level: level,
      explanation: '${options[3]} не относится к покупкам и деньгам.',
      variant: variant,
    );
  }

  static MissionTask _continueSequence(
    String id,
    DifficultyLevel level,
    int variant,
  ) {
    final (sequence, answer, variants) = switch (level) {
      DifficultyLevel.junior => ('🔵 🟡 🔵 🟡', '🔵', ['🔵', '🟡', '🟢']),
      DifficultyLevel.middle => ('⭐ ⭐ 🪙 ⭐ ⭐', '🪙', ['⭐', '🪙', '🎁']),
      DifficultyLevel.senior => ('2, 4, 8, 16', '32', ['24', '30', '32', '34']),
    };
    return _simpleLabelsTask(
      id: id,
      templateId: 'continue_sequence',
      title: 'Продолжи последовательность',
      description: '$sequence, ...',
      labels: variants,
      correctIndex: variants.indexOf(answer),
      taskTheme: TaskTheme.logic,
      level: level,
      explanation: 'Последовательность продолжается по тому же правилу.',
      variant: variant,
      earning: true,
    );
  }

  static MissionTask _matchPairs(
    String id,
    DifficultyLevel level,
    int variant,
  ) {
    return _choiceTask(
      id: id,
      templateId: 'match_pairs',
      title: 'Соедини пары',
      description: level == DifficultyLevel.senior
          ? 'Цель относится к…'
          : 'Монета относится к…',
      taskTheme: TaskTheme.logic,
      level: level,
      options: const [
        MissionTaskOption(id: 'saving', label: 'Накоплениям'),
        MissionTaskOption(id: 'weather', label: 'Погоде'),
        MissionTaskOption(id: 'sport', label: 'Спорту'),
      ],
      correctOptionId: 'saving',
      explanation: 'Цель и монеты связаны с накоплениями.',
      variant: variant,
    );
  }

  static MissionTask _fixFoxMistake(
    String id,
    DifficultyLevel level,
    int variant,
  ) {
    final start = switch (level) {
      DifficultyLevel.junior => 30,
      DifficultyLevel.middle => 150,
      DifficultyLevel.senior => 700,
    };
    final spent = switch (level) {
      DifficultyLevel.junior => 10,
      DifficultyLevel.middle => 70,
      DifficultyLevel.senior => 365,
    };
    final answer = start - spent;
    return _numberTask(
      id: id,
      templateId: 'fix_fox_mistake',
      title: 'Исправь ошибку Рыжика',
      description:
          'Рыжик решил: $start − $spent = ${answer + 10}. Как правильно?',
      answer: answer,
      level: level,
      economyType: TaskEconomyType.earning,
      rewardCoins: 20,
      explanation: 'Точно! Я поспешил с подсчётом: ответ $answer.',
      variant: variant,
    );
  }

  static MissionTask _chooseRoute(
    String id,
    DifficultyLevel level,
    int variant,
  ) {
    return _choiceTask(
      id: id,
      templateId: 'choose_route',
      title: 'Какой путь выбрать?',
      description: level == DifficultyLevel.senior
          ? 'Сравни время и учебную стоимость маршрута.'
          : 'Выбери самый короткий путь.',
      taskTheme: TaskTheme.logic,
      level: level,
      options: const [
        MissionTaskOption(id: 'a', label: 'Путь А', subtitle: '8 минут'),
        MissionTaskOption(id: 'b', label: 'Путь Б', subtitle: '12 минут'),
        MissionTaskOption(id: 'c', label: 'Путь В', subtitle: '15 минут'),
      ],
      correctOptionId: 'a',
      explanation: 'Путь А занимает меньше всего времени.',
      variant: variant,
    );
  }

  static MissionTask _findCoins(String id, DifficultyLevel level, int variant) {
    final count =
        switch (level) {
          DifficultyLevel.junior => 4,
          DifficultyLevel.middle => 6,
          DifficultyLevel.senior => 8,
        } +
        variant % 2;
    return _numberTask(
      id: id,
      templateId: 'find_coins',
      title: 'Найди монеты',
      description:
          '${List.filled(count, '✨🪙').join('  ')}\nСколько монет спрятано?',
      answer: count,
      level: level,
      economyType: TaskEconomyType.earning,
      rewardCoins: 18,
      explanation: 'Ты нашёл $count монет!',
      variant: variant,
      taskTheme: TaskTheme.attention,
    );
  }

  static MissionTask _rememberPurchases(
    String id,
    DifficultyLevel level,
    int variant,
  ) {
    final shown = switch (level) {
      DifficultyLevel.junior => '🍎 📒 🥤',
      DifficultyLevel.middle => '🍎 📒 🥤 🍞 ✏️',
      DifficultyLevel.senior => '🍎 20, 📒 15, 🥤 10, 🍞 25',
    };
    return _choiceTask(
      id: id,
      templateId: 'remember_purchases',
      title: 'Запомни покупки',
      description: 'Запомни ряд: $shown. Что было в списке?',
      taskTheme: TaskTheme.memory,
      level: level,
      options: const [
        MissionTaskOption(id: 'notebook', label: 'Тетрадь'),
        MissionTaskOption(id: 'bicycle', label: 'Велосипед'),
        MissionTaskOption(id: 'sofa', label: 'Диван'),
      ],
      correctOptionId: 'notebook',
      explanation: 'Тетрадь была в показанном списке.',
      variant: variant,
    );
  }

  static MissionTask _repeatAfterFox(
    String id,
    DifficultyLevel level,
    int variant,
  ) {
    final sequence = switch (level) {
      DifficultyLevel.junior => '🔵 🟡 🟢',
      DifficultyLevel.middle => '🔵 🟡 🟢 🔴 🔵',
      DifficultyLevel.senior => '🔵 🟡 🟢 🔴 🔵 🟢',
    };
    return _simpleLabelsTask(
      id: id,
      templateId: 'repeat_after_fox',
      title: 'Повтори за Рыжиком',
      description: 'Запомни: $sequence',
      labels: [sequence, '🟡 🔵 🟢', '🔴 🟢 🟡'],
      correctIndex: 0,
      taskTheme: TaskTheme.memory,
      level: level,
      explanation: 'Ты точно повторил последовательность.',
      variant: variant,
      earning: true,
    );
  }

  static MissionTask _quickSort(String id, DifficultyLevel level, int variant) {
    return MissionTask(
      id: id,
      templateId: 'quick_sort',
      title: 'Быстрая сортировка',
      description: 'Распредели покупки: На важное / На приятное.',
      type: MissionTaskType.classification,
      theme: MissionTheme.shopping,
      taskTheme: TaskTheme.finance,
      economyType: TaskEconomyType.simulation,
      difficulty: _visualDifficulty(level),
      difficultyLevel: level,
      estimatedSeconds: level == DifficultyLevel.junior ? 70 : 55,
      rewardCoins: 0,
      xpReward: 16,
      options: const [
        MissionTaskOption(id: 'lunch', label: 'Обед', category: 'НУЖНО'),
        MissionTaskOption(id: 'ticket', label: 'Проезд', category: 'НУЖНО'),
        MissionTaskOption(id: 'sticker', label: 'Наклейки', category: 'ХОЧУ'),
        MissionTaskOption(id: 'dessert', label: 'Десерт', category: 'ХОЧУ'),
      ],
      explanation: 'Важное планируем первым, а приятное — после.',
      scenarioKey: 'sort_${level.name}_${variant % 3}',
    );
  }

  static MissionTask _comparePrices(
    String id,
    DifficultyLevel level,
    int variant,
  ) {
    final prices = switch (level) {
      DifficultyLevel.junior => [20, 35],
      DifficultyLevel.middle => [65, 90, 75],
      DifficultyLevel.senior => [120, 95, 145, 110],
    };
    final min = prices.reduce((a, b) => a < b ? a : b);
    return _simpleLabelsTask(
      id: id,
      templateId: 'compare_prices',
      title: 'Сравни цены',
      description: 'Выбери самую низкую игровую цену.',
      labels: prices.map((price) => '$price монет').toList(),
      correctIndex: prices.indexOf(min),
      taskTheme: TaskTheme.math,
      level: level,
      explanation: 'Самая низкая цена — $min монет.',
      variant: variant,
    );
  }

  static MissionTask _fixReceipt(
    String id,
    DifficultyLevel level,
    int variant,
  ) {
    final prices = switch (level) {
      DifficultyLevel.junior => [10, 15],
      DifficultyLevel.middle => [25, 30, 15],
      DifficultyLevel.senior => [120, 75, 40, 35],
    };
    final sum = prices.fold<int>(0, (total, value) => total + value);
    return _numberTask(
      id: id,
      templateId: 'fix_receipt',
      title: 'Исправь чек',
      description:
          'В чеке цены ${prices.join(' + ')}, а итог написан ${sum + 10}. Какой итог верный?',
      answer: sum,
      level: level,
      economyType: TaskEconomyType.simulation,
      explanation: 'Складываем все позиции: итог $sum.',
      variant: variant,
      taskTheme: TaskTheme.attention,
    );
  }

  /// A real choice with a consequence: the reward lands on the balance, in
  /// the piggy bank, or split. Every answer is accepted; the feedback explains
  /// what each choice means for spending now and for the goal.
  static MissionTask _splitReward(
    String id,
    DifficultyLevel level,
    int variant,
  ) {
    final total = switch (level) {
      DifficultyLevel.junior => 30,
      DifficultyLevel.middle => 40,
      DifficultyLevel.senior => 60,
    };
    final half = total ~/ 2;
    return MissionTask(
      id: id,
      templateId: 'split_reward',
      title: 'Куда положим награду?',
      description:
          'За помощь тебе дали $total монет. Потратить сейчас или отложить '
          'часть в копилку на цель?',
      type: MissionTaskType.choice,
      theme: MissionTheme.savings,
      taskTheme: TaskTheme.finance,
      economyType: TaskEconomyType.earning,
      difficulty: _visualDifficulty(level),
      difficultyLevel: level,
      estimatedSeconds: 50,
      rewardCoins: 0,
      xpReward: 14,
      acceptAnyOption: true,
      options: [
        MissionTaskOption(
          id: '${id}_balance',
          label: 'Всё в кошелёк',
          subtitle: '+$total на баланс',
          rewardCoins: total,
          feedback:
              'Все $total монет можно тратить. Но до цели мы сегодня не '
              'приблизились — в следующий раз попробуй отложить часть.',
        ),
        MissionTaskOption(
          id: '${id}_split',
          label: 'Пополам',
          subtitle: '+$half на баланс, +$half в копилку',
          rewardCoins: half,
          savingsReward: total - half,
          feedback:
              'Отличный баланс: $half монет на траты и ${total - half} в '
              'копилку. Цель стала ближе!',
        ),
        MissionTaskOption(
          id: '${id}_savings',
          label: 'Всё в копилку',
          subtitle: '+$total в копилку',
          savingsReward: total,
          feedback:
              'Все $total монет в копилке — цель заметно ближе. Только '
              'помни: на важные покупки тоже нужны монеты.',
        ),
      ],
      explanation:
          'Регулярно откладывая часть монет, ты быстрее дойдёшь до цели.',
      scenarioKey: 'split_reward_${level.name}_${variant % 3}',
    );
  }

  /// How many days of regular saving a goal needs.
  static MissionTask _goalDays(String id, DifficultyLevel level, int variant) {
    final (goal, perDay) = switch (level) {
      DifficultyLevel.junior => ([60, 80, 100][variant % 3], 20),
      DifficultyLevel.middle => ([150, 200, 240][variant % 3], 50),
      DifficultyLevel.senior => ([360, 420, 480][variant % 3], 60),
    };
    final days = (goal / perDay).ceil();
    final values = <int>{days, days + 1, (days - 1).clamp(1, days)}.toList()
      ..sort();
    return MissionTask(
      id: id,
      templateId: 'goal_days',
      title: 'Сколько дней копить?',
      description:
          'Мяч стоит $goal монет. Каждый день ты откладываешь $perDay монет. '
          'За сколько дней накопишь?',
      type: MissionTaskType.calculation,
      theme: MissionTheme.savings,
      taskTheme: TaskTheme.finance,
      economyType: TaskEconomyType.earning,
      difficulty: _visualDifficulty(level),
      difficultyLevel: level,
      estimatedSeconds: level == DifficultyLevel.junior ? 45 : 70,
      rewardCoins: 15,
      xpReward: 12,
      options: [
        for (final value in values)
          MissionTaskOption(id: 'd_$value', label: '$value дн.'),
      ],
      correctOptionId: 'd_$days',
      explanation:
          '$goal : $perDay = $days. Если откладывать понемногу каждый день, '
          'цель достигается за $days дн.',
      scenarioKey: 'goal_days_${level.name}_${variant % 3}',
    );
  }

  static MissionTask _realChoice({
    required String id,
    required String templateId,
    required String title,
    required String description,
    required DifficultyLevel difficulty,
    required int variant,
    required int availableBalance,
    required ExpenseCategory category,
    required List<String> labels,
    required List<int> prices,
  }) {
    // Every option is shown with its price; the task screen marks the ones
    // the child cannot afford with how much is missing (ТЗ 2.5.6). A want
    // can always be postponed, and so can an essential nobody can afford.
    final canAffordAny = prices.any((price) => price <= availableBalance);
    final canPostpone = category == ExpenseCategory.want || !canAffordAny;
    return MissionTask(
      id: id,
      templateId: templateId,
      title: title,
      description: description,
      type: MissionTaskType.choice,
      theme: MissionTheme.entertainment,
      taskTheme: TaskTheme.entertainment,
      economyType: TaskEconomyType.realExpense,
      difficulty: _visualDifficulty(difficulty),
      difficultyLevel: difficulty,
      estimatedSeconds: 65,
      rewardCoins: 0,
      realExpenseAmount: canAffordAny
          ? prices.reduce((a, b) => a < b ? a : b)
          : 0,
      xpReward: 16,
      acceptAnyOption: true,
      options: [
        for (var index = 0; index < labels.length; index++)
          MissionTaskOption(
            id: '${templateId}_$index',
            label: labels[index],
            subtitle: '${prices[index]} монет',
            spendCoins: prices[index],
            expenseCategory: category,
            feedback: category == ExpenseCategory.essential
                ? 'Покупка сделана. Это важный расход — он учтён в бюджете.'
                : 'Покупка сделана. Это приятный расход — он учтён в бюджете.',
          ),
        if (canPostpone)
          MissionTaskOption(
            id: '${templateId}_later',
            label: 'Не покупать сейчас',
            subtitle: 'Отложить на потом',
            expenseCategory: category,
            feedback: category == ExpenseCategory.want
                ? 'Хорошее решение: приятную покупку можно отложить, а '
                      'монеты сохранятся.'
                : 'Сейчас монет не хватает. Выполни задания — и вернёмся к '
                      'этой покупке.',
          ),
      ],
      explanation: 'Ты выбрал доступный вариант.',
      expenseCategory: category,
      scenarioKey: '${templateId}_${difficulty.name}_${variant % 3}',
    );
  }

  static MissionTask _numberTask({
    required String id,
    required String templateId,
    required String title,
    required String description,
    required int answer,
    required DifficultyLevel level,
    required TaskEconomyType economyType,
    required String explanation,
    required int variant,
    int rewardCoins = 0,
    TaskTheme taskTheme = TaskTheme.math,
  }) {
    final step = level == DifficultyLevel.junior ? 1 : (answer < 50 ? 5 : 10);
    final values = <int>{
      answer,
      answer + step,
      (answer - step).clamp(0, answer),
    };
    return MissionTask(
      id: id,
      templateId: templateId,
      title: title,
      description: description,
      type: MissionTaskType.calculation,
      theme: MissionTheme.math,
      taskTheme: taskTheme,
      economyType: economyType,
      difficulty: _visualDifficulty(level),
      difficultyLevel: level,
      estimatedSeconds: level == DifficultyLevel.junior ? 45 : 70,
      rewardCoins: rewardCoins,
      xpReward: 12,
      options: [
        for (final value in values.toList()..sort())
          MissionTaskOption(id: 'n_$value', label: '$value монет'),
      ],
      correctOptionId: 'n_$answer',
      explanation: explanation,
      scenarioKey: '${templateId}_${level.name}_${variant % 5}',
    );
  }

  static MissionTask _simpleLabelsTask({
    required String id,
    required String templateId,
    required String title,
    required String description,
    required List<String> labels,
    required int correctIndex,
    required TaskTheme taskTheme,
    required DifficultyLevel level,
    required String explanation,
    required int variant,
    bool earning = false,
  }) {
    return _choiceTask(
      id: id,
      templateId: templateId,
      title: title,
      description: description,
      taskTheme: taskTheme,
      level: level,
      options: [
        for (var index = 0; index < labels.length; index++)
          MissionTaskOption(id: 'option_$index', label: labels[index]),
      ],
      correctOptionId: 'option_$correctIndex',
      explanation: explanation,
      variant: variant,
      economyType: earning
          ? TaskEconomyType.earning
          : TaskEconomyType.simulation,
      rewardCoins: earning ? 18 : 0,
    );
  }

  static MissionTask _choiceTask({
    required String id,
    required String templateId,
    required String title,
    required String description,
    required TaskTheme taskTheme,
    required DifficultyLevel level,
    required List<MissionTaskOption> options,
    required String correctOptionId,
    required String explanation,
    required int variant,
    TaskEconomyType economyType = TaskEconomyType.simulation,
    int rewardCoins = 0,
  }) {
    return MissionTask(
      id: id,
      templateId: templateId,
      title: title,
      description: description,
      type: MissionTaskType.choice,
      theme: _missionTheme(taskTheme),
      taskTheme: taskTheme,
      economyType: economyType,
      difficulty: _visualDifficulty(level),
      difficultyLevel: level,
      estimatedSeconds: level == DifficultyLevel.junior ? 50 : 70,
      rewardCoins: rewardCoins,
      xpReward: 12,
      options: options,
      correctOptionId: correctOptionId,
      explanation: explanation,
      scenarioKey: '${templateId}_${level.name}_${variant % 5}',
    );
  }

  static MissionDifficulty _visualDifficulty(DifficultyLevel level) =>
      level == DifficultyLevel.junior
      ? MissionDifficulty.easy
      : MissionDifficulty.medium;

  static MissionTheme _missionTheme(TaskTheme theme) => switch (theme) {
    TaskTheme.math => MissionTheme.math,
    TaskTheme.logic ||
    TaskTheme.attention ||
    TaskTheme.memory => MissionTheme.logic,
    TaskTheme.finance => MissionTheme.shopping,
    TaskTheme.entertainment => MissionTheme.entertainment,
  };
}
