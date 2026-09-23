import '../../../features/budget/domain/budget_plan.dart';
import '../../../features/budget/domain/budget_usage.dart';
import '../../../features/home/domain/pet_models.dart';
import '../../../features/missions/domain/mission_models.dart';
import '../../../features/periods/domain/game_period.dart';
import '../../../features/pet_progression/domain/pet_progression.dart';

abstract final class AppStateSerializers {
  static Map<String, Object?> budgetPlanToJson(BudgetPlan value) => {
    'essentialsPlanned': value.essentialsPlanned,
    'wantsPlanned': value.wantsPlanned,
    'savingsPlanned': value.savingsPlanned,
  };

  static BudgetPlan budgetPlanFromJson(Map<String, Object?> json) => BudgetPlan(
    essentialsPlanned: _int(json, 'essentialsPlanned'),
    wantsPlanned: _int(json, 'wantsPlanned'),
    savingsPlanned: _int(json, 'savingsPlanned'),
  );

  static Map<String, Object?> budgetUsageToJson(BudgetUsage value) => {
    'essentialsSpent': value.essentialsSpent,
    'wantsSpent': value.wantsSpent,
    'savingsDeposited': value.savingsDeposited,
  };

  static BudgetUsage budgetUsageFromJson(Map<String, Object?> json) =>
      BudgetUsage(
        essentialsSpent: _int(json, 'essentialsSpent'),
        wantsSpent: _int(json, 'wantsSpent'),
        savingsDeposited: _int(json, 'savingsDeposited'),
      );

  static Map<String, Object?> petStateToJson(PetState value) => {
    'mood': value.mood,
    'satiety': value.satiety,
    'care': value.care,
    'lastFedAt': value.lastFedAt?.toIso8601String(),
    'lastPlayedAt': value.lastPlayedAt?.toIso8601String(),
    'lastPettedAt': value.lastPettedAt?.toIso8601String(),
  };

  static PetState petStateFromJson(Map<String, Object?> json) => PetState(
    mood: _int(json, 'mood'),
    satiety: _int(json, 'satiety'),
    care: _int(json, 'care'),
    lastFedAt: _nullableDate(json['lastFedAt']),
    lastPlayedAt: _nullableDate(json['lastPlayedAt']),
    lastPettedAt: _nullableDate(json['lastPettedAt']),
  );

  static Map<String, Object?> missionOptionToJson(MissionTaskOption value) => {
    'id': value.id,
    'label': value.label,
    'subtitle': value.subtitle,
    'amount': value.amount,
    'category': value.category,
    'rewardCoins': value.rewardCoins,
    'spendCoins': value.spendCoins,
    'spendFromSavings': value.spendFromSavings,
    'savingsReward': value.savingsReward,
    'xpReward': value.xpReward,
    'feedback': value.feedback,
    'expenseCategory': value.expenseCategory?.name,
  };

  static MissionTaskOption missionOptionFromJson(Map<String, Object?> json) =>
      MissionTaskOption(
        id: _string(json, 'id'),
        label: _string(json, 'label'),
        subtitle: json['subtitle'] as String?,
        amount: json['amount'] as int?,
        category: json['category'] as String?,
        rewardCoins: _int(json, 'rewardCoins'),
        spendCoins: _int(json, 'spendCoins'),
        spendFromSavings: _int(json, 'spendFromSavings'),
        savingsReward: _int(json, 'savingsReward'),
        xpReward: _int(json, 'xpReward'),
        feedback: json['feedback'] as String?,
        expenseCategory: _nullableEnumByName(
          ExpenseCategory.values,
          json['expenseCategory'],
        ),
      );

  static Map<String, Object?> missionTaskToJson(MissionTask value) => {
    'id': value.id,
    'templateId': value.templateId,
    'title': value.title,
    'description': value.description,
    'type': value.type.name,
    'theme': value.theme.name,
    'taskTheme': value.taskTheme.name,
    'economyType': value.economyType.name,
    'difficulty': value.difficulty.name,
    'estimatedSeconds': value.estimatedSeconds,
    'rewardCoins': value.rewardCoins,
    'realExpenseAmount': value.realExpenseAmount,
    'spendCoins': value.spendCoins,
    'spendFromSavings': value.spendFromSavings,
    'savingsReward': value.savingsReward,
    'xpReward': value.xpReward,
    'options': value.options.map(missionOptionToJson).toList(),
    'correctOptionId': value.correctOptionId,
    'explanation': value.explanation,
    'totalAmount': value.totalAmount,
    'stepAmount': value.stepAmount,
    'difficultyLevel': value.difficultyLevel.name,
    'expenseCategory': value.expenseCategory?.name,
    'scenarioKey': value.scenarioKey,
    'acceptAnyOption': value.acceptAnyOption,
  };

  static MissionTask missionTaskFromJson(Map<String, Object?> json) =>
      MissionTask(
        id: _string(json, 'id'),
        templateId: _string(json, 'templateId'),
        title: _string(json, 'title'),
        description: _string(json, 'description'),
        type: _enumByName(MissionTaskType.values, json, 'type'),
        theme: _enumByName(MissionTheme.values, json, 'theme'),
        taskTheme: _enumByName(TaskTheme.values, json, 'taskTheme'),
        economyType: _enumByName(TaskEconomyType.values, json, 'economyType'),
        difficulty: _enumByName(MissionDifficulty.values, json, 'difficulty'),
        estimatedSeconds: _int(json, 'estimatedSeconds'),
        rewardCoins: _int(json, 'rewardCoins'),
        realExpenseAmount: _int(json, 'realExpenseAmount'),
        spendCoins: _int(json, 'spendCoins'),
        spendFromSavings: _int(json, 'spendFromSavings'),
        savingsReward: _int(json, 'savingsReward'),
        xpReward: _int(json, 'xpReward'),
        options: _mapList(json, 'options').map(missionOptionFromJson).toList(),
        correctOptionId: json['correctOptionId'] as String?,
        explanation: _string(json, 'explanation'),
        totalAmount: json['totalAmount'] as int?,
        stepAmount: _int(json, 'stepAmount'),
        difficultyLevel: _enumByName(
          DifficultyLevel.values,
          json,
          'difficultyLevel',
        ),
        expenseCategory: _nullableEnumByName(
          ExpenseCategory.values,
          json['expenseCategory'],
        ),
        scenarioKey: json['scenarioKey'] as String?,
        acceptAnyOption: _bool(json, 'acceptAnyOption'),
      );

  static Map<String, Object?> dailyMissionToJson(DailyMission value) => {
    'id': value.id,
    'date': value.date.toIso8601String(),
    'locationId': value.locationId,
    'title': value.title,
    'theme': value.theme.name,
    'tasks': value.tasks.map(missionTaskToJson).toList(),
    'estimatedMinutes': value.estimatedMinutes,
    'maxReward': value.maxReward,
    'primaryTaskTheme': value.primaryTaskTheme.name,
    'secondaryTaskTheme': value.secondaryTaskTheme.name,
  };

  static DailyMission dailyMissionFromJson(Map<String, Object?> json) =>
      DailyMission(
        id: _string(json, 'id'),
        date: DateTime.parse(_string(json, 'date')),
        locationId: _string(json, 'locationId'),
        title: _string(json, 'title'),
        theme: _enumByName(MissionTheme.values, json, 'theme'),
        tasks: _mapList(json, 'tasks').map(missionTaskFromJson).toList(),
        estimatedMinutes: _int(json, 'estimatedMinutes'),
        maxReward: _int(json, 'maxReward'),
        primaryTaskTheme: _enumByName(
          TaskTheme.values,
          json,
          'primaryTaskTheme',
        ),
        secondaryTaskTheme: _enumByName(
          TaskTheme.values,
          json,
          'secondaryTaskTheme',
        ),
      );

  static Map<String, Object?> missionResultToJson(MissionResult value) => {
    'taskId': value.taskId,
    'isCorrect': value.isCorrect,
    'explanation': value.explanation,
    'balanceBefore': value.balanceBefore,
    'balanceAfter': value.balanceAfter,
    'savingsBefore': value.savingsBefore,
    'savingsAfter': value.savingsAfter,
    'rewardCoins': value.rewardCoins,
    'spentCoins': value.spentCoins,
    'spentFromSavings': value.spentFromSavings,
    'savedCoins': value.savedCoins,
    'xpEarned': value.xpEarned,
    'correctAnswer': value.correctAnswer,
  };

  static MissionResult missionResultFromJson(Map<String, Object?> json) =>
      MissionResult(
        taskId: _string(json, 'taskId'),
        isCorrect: _bool(json, 'isCorrect'),
        explanation: _string(json, 'explanation'),
        balanceBefore: _int(json, 'balanceBefore'),
        balanceAfter: _int(json, 'balanceAfter'),
        savingsBefore: _int(json, 'savingsBefore'),
        savingsAfter: _int(json, 'savingsAfter'),
        rewardCoins: _int(json, 'rewardCoins'),
        spentCoins: _int(json, 'spentCoins'),
        spentFromSavings: _int(json, 'spentFromSavings'),
        savedCoins: _int(json, 'savedCoins'),
        xpEarned: _int(json, 'xpEarned'),
        correctAnswer: _string(json, 'correctAnswer'),
      );

  static Map<String, Object?> petStateSnapshotToJson(PetStateSnapshot value) =>
      {'mood': value.mood, 'satiety': value.satiety, 'care': value.care};

  static PetStateSnapshot petStateSnapshotFromJson(Map<String, Object?> json) =>
      PetStateSnapshot(
        mood: _int(json, 'mood'),
        satiety: _int(json, 'satiety'),
        care: _int(json, 'care'),
      );

  static Map<String, Object?> periodGrowthEvaluationToJson(
    PeriodGrowthEvaluation value,
  ) => {
    'planningPoints': value.planningPoints,
    'budgetPoints': value.budgetPoints,
    'savingsPoints': value.savingsPoints,
    'goalPoints': value.goalPoints,
    'financialTaskPoints': value.financialTaskPoints,
    'completionPoints': value.completionPoints,
  };

  static PeriodGrowthEvaluation periodGrowthEvaluationFromJson(
    Map<String, Object?> json,
  ) => PeriodGrowthEvaluation(
    planningPoints: _int(json, 'planningPoints'),
    budgetPoints: _int(json, 'budgetPoints'),
    savingsPoints: _int(json, 'savingsPoints'),
    goalPoints: _int(json, 'goalPoints'),
    financialTaskPoints: _int(json, 'financialTaskPoints'),
    completionPoints: _int(json, 'completionPoints'),
  );

  static Map<String, Object?> gamePeriodToJson(GamePeriod value) => {
    'id': value.id,
    'sequenceNumber': value.sequenceNumber,
    'startedAt': value.startedAt.toIso8601String(),
    'completedAt': value.completedAt?.toIso8601String(),
    'status': value.status.name,
    'startingBalance': value.startingBalance,
    'startingSavings': value.startingSavings,
    'selectedGoalIdAtStart': value.selectedGoalIdAtStart,
    'goalProgressAtStart': value.goalProgressAtStart,
    'budgetPlanSnapshot': budgetPlanToJson(value.budgetPlanSnapshot),
    'budgetWasConfirmed': value.budgetWasConfirmed,
    'earnedCoins': value.earnedCoins,
    'essentialSpent': value.essentialSpent,
    'wantSpent': value.wantSpent,
    'depositedToSavings': value.depositedToSavings,
    'completedTaskCount': value.completedTaskCount,
    'correctTaskCount': value.correctTaskCount,
    'missionId': value.missionId,
    'locationId': value.locationId,
    'themeId': value.themeId,
    'endingBalance': value.endingBalance,
    'endingSavings': value.endingSavings,
    'goalProgressAtEnd': value.goalProgressAtEnd,
    'petStateAtStart': petStateSnapshotToJson(value.petStateAtStart),
    'petStateAtEnd': petStateSnapshotToJson(value.petStateAtEnd),
    'isDemoPeriod': value.isDemoPeriod,
    'missionTaskCount': value.missionTaskCount,
    'financialTaskCount': value.financialTaskCount,
    'correctFinancialTaskCount': value.correctFinancialTaskCount,
    'missionEssentialSpent': value.missionEssentialSpent,
    'missionWantSpent': value.missionWantSpent,
    'intentionalSavingsDeposited': value.intentionalSavingsDeposited,
    'growthPointsAwarded': value.growthPointsAwarded,
    'growthEvaluation': value.growthEvaluation == null
        ? null
        : periodGrowthEvaluationToJson(value.growthEvaluation!),
    'petGrowthPointsAtStart': value.petGrowthPointsAtStart,
    'petGrowthPointsAtEnd': value.petGrowthPointsAtEnd,
    'petStageAtStart': value.petStageAtStart.name,
    'petStageAtEnd': value.petStageAtEnd.name,
    'growthEvaluated': value.growthEvaluated,
    'trainedThemeIds': value.trainedThemeIds,
    'rewardedMiniGameIds': value.rewardedMiniGameIds,
  };

  static GamePeriod gamePeriodFromJson(Map<String, Object?> json) {
    final status = _enumByName(GamePeriodStatus.values, json, 'status');
    final startPoints = _optionalInt(json, 'petGrowthPointsAtStart');
    final endPoints = _optionalInt(
      json,
      'petGrowthPointsAtEnd',
      fallback: startPoints,
    );
    final evaluationJson = _optionalMap(json['growthEvaluation']);
    return GamePeriod(
      id: _string(json, 'id'),
      sequenceNumber: _int(json, 'sequenceNumber'),
      startedAt: DateTime.parse(_string(json, 'startedAt')),
      completedAt: _nullableDate(json['completedAt']),
      status: status,
      startingBalance: _int(json, 'startingBalance'),
      startingSavings: _int(json, 'startingSavings'),
      selectedGoalIdAtStart: json['selectedGoalIdAtStart'] as String?,
      goalProgressAtStart: _double(json, 'goalProgressAtStart'),
      budgetPlanSnapshot: budgetPlanFromJson(_map(json, 'budgetPlanSnapshot')),
      budgetWasConfirmed: _bool(json, 'budgetWasConfirmed'),
      earnedCoins: _int(json, 'earnedCoins'),
      essentialSpent: _int(json, 'essentialSpent'),
      wantSpent: _int(json, 'wantSpent'),
      depositedToSavings: _int(json, 'depositedToSavings'),
      completedTaskCount: _int(json, 'completedTaskCount'),
      correctTaskCount: _int(json, 'correctTaskCount'),
      missionId: _string(json, 'missionId'),
      locationId: _string(json, 'locationId'),
      themeId: _string(json, 'themeId'),
      endingBalance: _int(json, 'endingBalance'),
      endingSavings: _int(json, 'endingSavings'),
      goalProgressAtEnd: _double(json, 'goalProgressAtEnd'),
      petStateAtStart: petStateSnapshotFromJson(_map(json, 'petStateAtStart')),
      petStateAtEnd: petStateSnapshotFromJson(_map(json, 'petStateAtEnd')),
      isDemoPeriod: _bool(json, 'isDemoPeriod'),
      missionTaskCount: _optionalInt(json, 'missionTaskCount'),
      financialTaskCount: _optionalInt(json, 'financialTaskCount'),
      correctFinancialTaskCount: _optionalInt(
        json,
        'correctFinancialTaskCount',
      ),
      missionEssentialSpent: _optionalInt(json, 'missionEssentialSpent'),
      missionWantSpent: _optionalInt(json, 'missionWantSpent'),
      intentionalSavingsDeposited: _optionalInt(
        json,
        'intentionalSavingsDeposited',
      ),
      growthPointsAwarded: _optionalInt(json, 'growthPointsAwarded'),
      growthEvaluation: evaluationJson == null
          ? null
          : periodGrowthEvaluationFromJson(evaluationJson),
      petGrowthPointsAtStart: startPoints,
      petGrowthPointsAtEnd: endPoints,
      petStageAtStart: _optionalEnumByName(
        PetGrowthStage.values,
        json['petStageAtStart'],
        fallback: PetProgressionConfig.stageForPoints(startPoints),
      ),
      petStageAtEnd: _optionalEnumByName(
        PetGrowthStage.values,
        json['petStageAtEnd'],
        fallback: PetProgressionConfig.stageForPoints(endPoints),
      ),
      // Legacy completed periods cannot be evaluated reliably because they did
      // not retain financial-task details. Marking them evaluated prevents an
      // accidental award when their summary is reopened after migration.
      growthEvaluated: _optionalBool(
        json,
        'growthEvaluated',
        fallback: status == GamePeriodStatus.completed,
      ),
      trainedThemeIds: _optionalStringList(
        json,
        'trainedThemeIds',
        fallback: _legacyThemeIds(_string(json, 'themeId')),
      ),
      rewardedMiniGameIds: _optionalStringList(
        json,
        'rewardedMiniGameIds',
        fallback: const [],
      ),
    );
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    Map<String, Object?> json,
    String key,
  ) {
    return values.byName(_string(json, key));
  }

  static T? _nullableEnumByName<T extends Enum>(List<T> values, Object? raw) {
    if (raw == null) return null;
    if (raw is! String) throw FormatException('Expected enum name, got $raw');
    return values.byName(raw);
  }

  static T _optionalEnumByName<T extends Enum>(
    List<T> values,
    Object? raw, {
    required T fallback,
  }) {
    if (raw == null) return fallback;
    if (raw is! String) throw FormatException('Expected enum name, got $raw');
    return values.byName(raw);
  }

  static int _optionalInt(
    Map<String, Object?> json,
    String key, {
    int fallback = 0,
  }) {
    final value = json[key];
    if (value == null) return fallback;
    if (value is int) return value;
    throw FormatException('Expected int for $key, got $value');
  }

  static bool _optionalBool(
    Map<String, Object?> json,
    String key, {
    required bool fallback,
  }) {
    final value = json[key];
    if (value == null) return fallback;
    if (value is bool) return value;
    throw FormatException('Expected bool for $key, got $value');
  }

  static Map<String, Object?>? _optionalMap(Object? value) {
    if (value == null) return null;
    return _asMap(value);
  }

  static List<String> _optionalStringList(
    Map<String, Object?> json,
    String key, {
    required List<String> fallback,
  }) {
    final value = json[key];
    if (value == null) return fallback;
    if (value is! List) throw FormatException('Expected list for $key');
    return value
        .map((item) {
          if (item is! String) throw FormatException('Expected string in $key');
          return item;
        })
        .toList(growable: false);
  }

  static List<String> _legacyThemeIds(String missionTheme) =>
      switch (missionTheme) {
        'math' => const ['math'],
        'logic' => const ['logic'],
        'shopping' || 'savings' => const ['finance'],
        'entertainment' => const ['entertainment'],
        'mixed' => const ['math', 'finance', 'logic'],
        _ => const [],
      };

  static int _int(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) return value;
    throw FormatException('Expected int for $key, got $value');
  }

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('Expected String for $key, got $value');
  }

  static bool _bool(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    throw FormatException('Expected bool for $key, got $value');
  }

  static double _double(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is num) return value.toDouble();
    throw FormatException('Expected number for $key, got $value');
  }

  static Map<String, Object?> _map(Map<String, Object?> json, String key) =>
      _asMap(json[key]);

  static List<Map<String, Object?>> _mapList(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value is! List) throw FormatException('Expected List for $key');
    return value.map(_asMap).toList();
  }

  static Map<String, Object?> _asMap(Object? value) {
    if (value is! Map) {
      throw FormatException('Expected JSON object, got $value');
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static DateTime? _nullableDate(Object? value) {
    if (value == null) return null;
    if (value is! String) throw FormatException('Expected date string');
    return DateTime.parse(value);
  }
}
