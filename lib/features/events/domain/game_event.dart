/// Planned random events (ТЗ 2: "специально спланированные кейсы"): a short
/// situation with a choice; every choice has a consequence and an
/// explanation. Texts are data, so a new event needs no new logic.
enum GameEventId {
  scamCall,
  vetVisit;

  /// Theme recorded for the parent's "Что уже тренировалось".
  String get themeId => switch (this) {
    scamCall => 'safety',
    vetVisit => 'unexpected',
  };
}

enum GameEventEffect {
  /// Money lost to a fraudster (capped by the balance).
  loseCoins,

  /// A small reward on the balance.
  rewardCoins,

  /// Nothing changes.
  none,

  /// An essential expense paid from the balance.
  payFromBalance,

  /// The same expense paid from the piggy bank.
  payFromSavings,

  /// The expense is postponed: care drops, the event returns tomorrow.
  postpone,
}

class GameEventOption {
  const GameEventOption({
    required this.id,
    required this.label,
    required this.effect,
    required this.explanation,
    this.amount = 0,
    this.careLoss = 0,
  });

  final String id;
  final String label;
  final GameEventEffect effect;
  final String explanation;
  final int amount;
  final int careLoss;
}

class GameEvent {
  const GameEvent({
    required this.id,
    required this.emoji,
    required this.title,
    required this.situation,
    required this.petLine,
    required this.options,
    required this.advice,
    required this.transactionTitle,
  });

  final GameEventId id;
  final String emoji;
  final String title;
  final String situation;
  final String petLine;
  final List<GameEventOption> options;
  final String advice;

  /// Title of the coin history entry the event creates.
  final String transactionTitle;

  GameEventOption option(String optionId) =>
      options.firstWhere((option) => option.id == optionId);
}

abstract final class GameEvents {
  static const int scamLoss = 30;
  static const int carefulReward = 5;
  static const int vetCost = 40;
  static const int postponeCareLoss = 15;

  /// Chance of an event at the start of a normal game day.
  static const double dailyChance = 0.25;

  /// Demo days with a fixed event, so experts always see both.
  static const Map<int, GameEventId> demoSchedule = {
    2: GameEventId.scamCall,
    4: GameEventId.vetVisit,
  };

  static const scamCall = GameEvent(
    id: GameEventId.scamCall,
    emoji: '📞',
    title: 'Неожиданный звонок',
    situation:
        'Звонит незнакомец: «Поздравляю! Ты выиграл 500 монет! Чтобы '
        'получить приз, скажи код из СМС, которое сейчас придёт на телефон '
        'мамы».',
    petLine: 'Хм… Что-то тут не так. Что будем делать?',
    advice: 'Запомни: настоящие призы не просят коды из СМС.',
    transactionTitle: 'Обман по телефону',
    options: [
      GameEventOption(
        id: 'tell_code',
        label: 'Скажу код, хочу приз!',
        effect: GameEventEffect.loseCoins,
        amount: scamLoss,
        explanation:
            'Ой! Это был мошенник — приза не было, а монеты пропали. Коды из '
            'СМС — это секрет. Их нельзя говорить никому, даже если обещают '
            'подарок.',
      ),
      GameEventOption(
        id: 'call_adult',
        label: 'Позову взрослого',
        effect: GameEventEffect.rewardCoins,
        amount: carefulReward,
        explanation:
            'Отличное решение! Взрослый сразу понял, что это обман. Если '
            'незнакомец просит код или деньги — зови взрослого.',
      ),
      GameEventOption(
        id: 'hang_up',
        label: 'Положу трубку',
        effect: GameEventEffect.none,
        explanation:
            'Правильно! Если звонит незнакомец и обещает приз — лучше '
            'закончить разговор и рассказать взрослым.',
      ),
    ],
  );

  static const vetVisit = GameEvent(
    id: GameEventId.vetVisit,
    emoji: '🩹',
    title: 'Рыжик поранил лапку',
    situation:
        'Рыжик бегал по комнате и занозил лапку. Ничего страшного, но нужно '
        'сходить к ветеринару. Приём стоит $vetCost монет.',
    petLine: 'Ай, лапка! Поможешь мне?',
    advice:
        'Хорошо иметь немного монет в копилке на всякий случай — для '
        'неожиданных расходов.',
    transactionTitle: 'Ветеринар (непредвиденный расход)',
    options: [
      GameEventOption(
        id: 'pay_balance',
        label: 'Заплачу из кошелька',
        effect: GameEventEffect.payFromBalance,
        amount: vetCost,
        explanation:
            'Лапка вылечена! Этого расхода не было в плане, поэтому на '
            'другие покупки монет стало меньше.',
      ),
      GameEventOption(
        id: 'pay_savings',
        label: 'Возьму из копилки',
        effect: GameEventEffect.payFromSavings,
        amount: vetCost,
        explanation:
            'Лапка вылечена! Вот зачем нужны накопления: они выручают, когда '
            'случается неожиданное. До цели стало немного дальше — это '
            'нормально.',
      ),
      GameEventOption(
        id: 'postpone',
        label: 'Подожду до завтра',
        effect: GameEventEffect.postpone,
        careLoss: postponeCareLoss,
        explanation:
            'Лапка пока болит, и Рыжику грустно. Лечение лучше не '
            'откладывать — это важный расход.',
      ),
    ],
  );

  static GameEvent of(GameEventId id) => switch (id) {
    GameEventId.scamCall => scamCall,
    GameEventId.vetVisit => vetVisit,
  };
}

/// What a resolved event changed, for the explanation screen.
class GameEventOutcome {
  const GameEventOutcome({
    required this.event,
    required this.option,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.savingsBefore,
    required this.savingsAfter,
    required this.careBefore,
    required this.careAfter,
  });

  final GameEvent event;
  final GameEventOption option;
  final int balanceBefore;
  final int balanceAfter;
  final int savingsBefore;
  final int savingsAfter;
  final int careBefore;
  final int careAfter;
}
