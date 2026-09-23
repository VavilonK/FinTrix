import '../../budget/domain/budget_plan.dart';
import '../../home/domain/pet_models.dart';
import '../../pet_progression/domain/pet_progression.dart';

enum AppRunMode { normal, demo }

enum GamePeriodStatus { active, completed }

class PetStateSnapshot {
  const PetStateSnapshot({
    required this.mood,
    required this.satiety,
    required this.care,
  });

  factory PetStateSnapshot.fromPetState(PetState state) {
    return PetStateSnapshot(
      mood: state.mood,
      satiety: state.satiety,
      care: state.care,
    );
  }

  final int mood;
  final int satiety;
  final int care;
}

class GamePeriod {
  const GamePeriod({
    required this.id,
    required this.sequenceNumber,
    required this.startedAt,
    required this.completedAt,
    required this.status,
    required this.startingBalance,
    required this.startingSavings,
    required this.selectedGoalIdAtStart,
    required this.goalProgressAtStart,
    required this.budgetPlanSnapshot,
    required this.budgetWasConfirmed,
    required this.earnedCoins,
    required this.essentialSpent,
    required this.wantSpent,
    required this.depositedToSavings,
    required this.completedTaskCount,
    required this.correctTaskCount,
    required this.missionId,
    required this.locationId,
    required this.themeId,
    required this.endingBalance,
    required this.endingSavings,
    required this.goalProgressAtEnd,
    required this.petStateAtStart,
    required this.petStateAtEnd,
    required this.isDemoPeriod,
    this.missionTaskCount = 0,
    this.financialTaskCount = 0,
    this.correctFinancialTaskCount = 0,
    this.missionEssentialSpent = 0,
    this.missionWantSpent = 0,
    this.intentionalSavingsDeposited = 0,
    this.growthPointsAwarded = 0,
    this.growthEvaluation,
    this.petGrowthPointsAtStart = 0,
    this.petGrowthPointsAtEnd = 0,
    this.petStageAtStart = PetGrowthStage.little,
    this.petStageAtEnd = PetGrowthStage.little,
    this.growthEvaluated = false,
    this.trainedThemeIds = const [],
    this.rewardedMiniGameIds = const [],
  });

  final String id;
  final int sequenceNumber;
  final DateTime startedAt;
  final DateTime? completedAt;
  final GamePeriodStatus status;
  final int startingBalance;
  final int startingSavings;
  final String? selectedGoalIdAtStart;
  final double goalProgressAtStart;
  final BudgetPlan budgetPlanSnapshot;
  final bool budgetWasConfirmed;
  final int earnedCoins;
  final int essentialSpent;
  final int wantSpent;
  final int depositedToSavings;
  final int completedTaskCount;
  final int correctTaskCount;
  final String missionId;
  final String locationId;
  final String themeId;
  final int endingBalance;
  final int endingSavings;
  final double goalProgressAtEnd;
  final PetStateSnapshot petStateAtStart;
  final PetStateSnapshot petStateAtEnd;
  final bool isDemoPeriod;
  final int missionTaskCount;
  final int financialTaskCount;
  final int correctFinancialTaskCount;
  final int missionEssentialSpent;
  final int missionWantSpent;
  final int intentionalSavingsDeposited;
  final int growthPointsAwarded;
  final PeriodGrowthEvaluation? growthEvaluation;
  final int petGrowthPointsAtStart;
  final int petGrowthPointsAtEnd;
  final PetGrowthStage petStageAtStart;
  final PetGrowthStage petStageAtEnd;
  final bool growthEvaluated;
  final List<String> trainedThemeIds;
  final List<String> rewardedMiniGameIds;

  GamePeriod copyWith({
    DateTime? completedAt,
    GamePeriodStatus? status,
    bool? budgetWasConfirmed,
    int? earnedCoins,
    int? essentialSpent,
    int? wantSpent,
    int? depositedToSavings,
    int? completedTaskCount,
    int? correctTaskCount,
    BudgetPlan? budgetPlanSnapshot,
    int? financialTaskCount,
    int? correctFinancialTaskCount,
    int? missionEssentialSpent,
    int? missionWantSpent,
    int? intentionalSavingsDeposited,
    int? endingBalance,
    int? endingSavings,
    double? goalProgressAtEnd,
    PetStateSnapshot? petStateAtEnd,
    int? growthPointsAwarded,
    PeriodGrowthEvaluation? growthEvaluation,
    int? petGrowthPointsAtEnd,
    PetGrowthStage? petStageAtEnd,
    bool? growthEvaluated,
    List<String>? rewardedMiniGameIds,
  }) {
    return GamePeriod(
      id: id,
      sequenceNumber: sequenceNumber,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      startingBalance: startingBalance,
      startingSavings: startingSavings,
      selectedGoalIdAtStart: selectedGoalIdAtStart,
      goalProgressAtStart: goalProgressAtStart,
      budgetPlanSnapshot: budgetPlanSnapshot ?? this.budgetPlanSnapshot,
      budgetWasConfirmed: budgetWasConfirmed ?? this.budgetWasConfirmed,
      earnedCoins: earnedCoins ?? this.earnedCoins,
      essentialSpent: essentialSpent ?? this.essentialSpent,
      wantSpent: wantSpent ?? this.wantSpent,
      depositedToSavings: depositedToSavings ?? this.depositedToSavings,
      completedTaskCount: completedTaskCount ?? this.completedTaskCount,
      correctTaskCount: correctTaskCount ?? this.correctTaskCount,
      missionId: missionId,
      locationId: locationId,
      themeId: themeId,
      endingBalance: endingBalance ?? this.endingBalance,
      endingSavings: endingSavings ?? this.endingSavings,
      goalProgressAtEnd: goalProgressAtEnd ?? this.goalProgressAtEnd,
      petStateAtStart: petStateAtStart,
      petStateAtEnd: petStateAtEnd ?? this.petStateAtEnd,
      isDemoPeriod: isDemoPeriod,
      missionTaskCount: missionTaskCount,
      financialTaskCount: financialTaskCount ?? this.financialTaskCount,
      correctFinancialTaskCount:
          correctFinancialTaskCount ?? this.correctFinancialTaskCount,
      missionEssentialSpent:
          missionEssentialSpent ?? this.missionEssentialSpent,
      missionWantSpent: missionWantSpent ?? this.missionWantSpent,
      intentionalSavingsDeposited:
          intentionalSavingsDeposited ?? this.intentionalSavingsDeposited,
      growthPointsAwarded: growthPointsAwarded ?? this.growthPointsAwarded,
      growthEvaluation: growthEvaluation ?? this.growthEvaluation,
      petGrowthPointsAtStart: petGrowthPointsAtStart,
      petGrowthPointsAtEnd: petGrowthPointsAtEnd ?? this.petGrowthPointsAtEnd,
      petStageAtStart: petStageAtStart,
      petStageAtEnd: petStageAtEnd ?? this.petStageAtEnd,
      growthEvaluated: growthEvaluated ?? this.growthEvaluated,
      trainedThemeIds: trainedThemeIds,
      rewardedMiniGameIds: rewardedMiniGameIds ?? this.rewardedMiniGameIds,
    );
  }
}
