import 'dart:math' as math;

import '../../missions/data/daily_task_templates.dart';
import '../../missions/domain/mission_models.dart';
import '../../periods/domain/game_period.dart';
import 'pet_progression.dart';

abstract final class PetProgressionPolicy {
  static const Set<String> financialTemplateIds = {
    'count_coins',
    'calculate_remaining',
    'can_afford',
    'best_price',
    'need_or_want',
    'buy_first',
    'build_basket',
    'split_budget',
    'match_pairs',
    'fix_fox_mistake',
    'quick_sort',
    'compare_prices',
    'fix_receipt',
    ...DailyTaskTemplates.realExpenseTemplateIds,
  };

  static bool isFinancialTask(MissionTask task) {
    return task.taskTheme == TaskTheme.finance ||
        financialTemplateIds.contains(task.templateId);
  }

  static PeriodGrowthEvaluation evaluate(GamePeriod period) {
    final planning = period.budgetWasConfirmed
        ? PetProgressionConfig.planningMax
        : 0;
    final budget = _budgetPoints(period);
    final savings = _savingsPoints(period);
    final goal = _goalPoints(period);
    final financialTasks = _financialTaskPoints(period);
    final completedMission =
        period.missionTaskCount > 0 &&
        period.completedTaskCount >= period.missionTaskCount;

    final result = PeriodGrowthEvaluation(
      planningPoints: planning,
      budgetPoints: budget,
      savingsPoints: savings,
      goalPoints: goal,
      financialTaskPoints: financialTasks,
      completionPoints: completedMission
          ? PetProgressionConfig.completionMax
          : 0,
    );
    assert(result.totalPoints <= PetProgressionConfig.maxPointsPerPeriod);
    return result;
  }

  static int _budgetPoints(GamePeriod period) {
    final totalSpent = period.essentialSpent + period.wantSpent;
    if (totalSpent <= 0 || !period.budgetWasConfirmed) return 0;

    final assessableEssential = math.max(
      0,
      period.essentialSpent - period.missionEssentialSpent,
    );
    final assessableWant = math.max(
      0,
      period.wantSpent - period.missionWantSpent,
    );
    final essentialOverrun = _overrunRatio(
      assessableEssential,
      period.budgetPlanSnapshot.essentialsPlanned,
    );
    final wantOverrun = _overrunRatio(
      assessableWant,
      period.budgetPlanSnapshot.wantsPlanned,
    );
    final worstOverrun = math.max(essentialOverrun, wantOverrun);
    if (worstOverrun <= 0) return 5;
    if (worstOverrun <= 0.35) return 4;
    if (worstOverrun <= 0.75) return 3;
    if (worstOverrun <= 1.25) return 2;
    return 1;
  }

  static double _overrunRatio(int actual, int planned) {
    final tolerance = math.max(20, (planned * 0.2).round());
    final allowed = planned + tolerance;
    if (actual <= allowed) return 0;
    return (actual - allowed) / math.max(allowed, 1);
  }

  static int _savingsPoints(GamePeriod period) {
    final deposited = period.intentionalSavingsDeposited;
    if (deposited <= 0) return 0;
    final target = _personalSavingsTarget(period);
    final ratio = deposited / target;
    if (ratio >= 1) return 7;
    if (ratio >= 0.6) return 6;
    if (ratio >= 0.3) return 5;
    return 4;
  }

  static int _goalPoints(GamePeriod period) {
    if (period.goalProgressAtEnd <= period.goalProgressAtStart) return 0;
    final progressContribution = period.depositedToSavings;
    final target = _personalSavingsTarget(period);
    final ratio = progressContribution / target;
    if (ratio >= 1) return 4;
    if (ratio >= 0.6) return 3;
    if (ratio >= 0.3) return 2;
    return 1;
  }

  static int _personalSavingsTarget(GamePeriod period) {
    final available = math.max(1, period.startingBalance + period.earnedCoins);
    final planned = period.budgetPlanSnapshot.savingsPlanned;
    if (planned > 0) return math.max(1, math.min(planned, available));
    return math.max(1, (available * 0.1).round());
  }

  static int _financialTaskPoints(GamePeriod period) {
    if (period.financialTaskCount <= 0) return 0;
    final accuracy =
        period.correctFinancialTaskCount / period.financialTaskCount;
    if (accuracy >= 0.8) return 6;
    if (accuracy >= 0.6) return 4;
    if (accuracy >= 0.4) return 2;
    if (period.correctFinancialTaskCount > 0) return 1;
    return 0;
  }
}
