enum PetGrowthStage { little, growing, grown }

extension PetGrowthStageUi on PetGrowthStage {
  String get title => switch (this) {
    PetGrowthStage.little => 'Маленький Рыжик',
    PetGrowthStage.growing => 'Рыжик подрос',
    PetGrowthStage.grown => 'Старший Рыжик',
  };

  String get shortTitle => switch (this) {
    PetGrowthStage.little => 'Стадия 1',
    PetGrowthStage.growing => 'Стадия 2',
    PetGrowthStage.grown => 'Стадия 3',
  };
}

abstract final class PetProgressionConfig {
  static const int growingThreshold = 40;
  static const int grownThreshold = 90;

  static const int planningMax = 4;
  static const int budgetMax = 5;
  static const int savingsMax = 7;
  static const int goalMax = 4;
  static const int financialTasksMax = 6;
  static const int completionMax = 4;
  static const int maxPointsPerPeriod =
      planningMax +
      budgetMax +
      savingsMax +
      goalMax +
      financialTasksMax +
      completionMax;

  static PetGrowthStage stageForPoints(int points) {
    final safePoints = points < 0 ? 0 : points;
    if (safePoints >= grownThreshold) return PetGrowthStage.grown;
    if (safePoints >= growingThreshold) return PetGrowthStage.growing;
    return PetGrowthStage.little;
  }

  static int nextStageThreshold(int points) {
    return switch (stageForPoints(points)) {
      PetGrowthStage.little => growingThreshold,
      PetGrowthStage.growing => grownThreshold,
      PetGrowthStage.grown => grownThreshold,
    };
  }

  static double progressToNextStage(int points) {
    final safePoints = points < 0 ? 0 : points;
    return switch (stageForPoints(safePoints)) {
      PetGrowthStage.little =>
        (safePoints / growingThreshold).clamp(0, 1).toDouble(),
      PetGrowthStage.growing =>
        ((safePoints - growingThreshold) / (grownThreshold - growingThreshold))
            .clamp(0, 1)
            .toDouble(),
      PetGrowthStage.grown => 1,
    };
  }
}

class PeriodGrowthEvaluation {
  const PeriodGrowthEvaluation({
    required this.planningPoints,
    required this.budgetPoints,
    required this.savingsPoints,
    required this.goalPoints,
    required this.financialTaskPoints,
    required this.completionPoints,
  }) : assert(planningPoints >= 0),
       assert(planningPoints <= PetProgressionConfig.planningMax),
       assert(budgetPoints >= 0),
       assert(budgetPoints <= PetProgressionConfig.budgetMax),
       assert(savingsPoints >= 0),
       assert(savingsPoints <= PetProgressionConfig.savingsMax),
       assert(goalPoints >= 0),
       assert(goalPoints <= PetProgressionConfig.goalMax),
       assert(financialTaskPoints >= 0),
       assert(financialTaskPoints <= PetProgressionConfig.financialTasksMax),
       assert(completionPoints >= 0),
       assert(completionPoints <= PetProgressionConfig.completionMax);

  static const zero = PeriodGrowthEvaluation(
    planningPoints: 0,
    budgetPoints: 0,
    savingsPoints: 0,
    goalPoints: 0,
    financialTaskPoints: 0,
    completionPoints: 0,
  );

  final int planningPoints;
  final int budgetPoints;
  final int savingsPoints;
  final int goalPoints;
  final int financialTaskPoints;
  final int completionPoints;

  int get totalPoints =>
      planningPoints +
      budgetPoints +
      savingsPoints +
      goalPoints +
      financialTaskPoints +
      completionPoints;
}
