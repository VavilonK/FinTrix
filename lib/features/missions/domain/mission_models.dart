import '../../budget/domain/budget_usage.dart';

enum MissionTheme { math, logic, shopping, savings, entertainment, mixed }

enum TaskTheme { math, logic, finance, attention, memory, entertainment }

enum TaskEconomyType { simulation, earning, realExpense }

enum MissionTaskType {
  calculation,
  choice,
  logic,
  classification,
  matching,
  budgetSplit,
  attention,
  quiz,
}

enum MissionDifficulty { easy, medium }

enum DifficultyLevel { junior, middle, senior }

typedef AgeDifficulty = DifficultyLevel;

enum MissionNextStep { task, checkpoint, complete }

class MissionTaskOption {
  const MissionTaskOption({
    required this.id,
    required this.label,
    this.subtitle,
    this.amount,
    this.category,
    this.rewardCoins = 0,
    this.spendCoins = 0,
    this.spendFromSavings = 0,
    this.savingsReward = 0,
    this.xpReward = 0,
    this.feedback,
    this.expenseCategory,
  });

  final String id;
  final String label;
  final String? subtitle;
  final int? amount;
  final String? category;
  final int rewardCoins;
  final int spendCoins;
  final int spendFromSavings;
  final int savingsReward;
  final int xpReward;
  final String? feedback;
  final ExpenseCategory? expenseCategory;
}

class MissionTask {
  const MissionTask({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.theme,
    required this.difficulty,
    required this.estimatedSeconds,
    required this.rewardCoins,
    required this.xpReward,
    required this.options,
    required this.explanation,
    this.templateId = 'legacy',
    this.taskTheme = TaskTheme.finance,
    this.economyType = TaskEconomyType.simulation,
    this.realExpenseAmount = 0,
    this.scenarioKey,
    this.acceptAnyOption = false,
    this.correctOptionId,
    this.spendCoins = 0,
    this.spendFromSavings = 0,
    this.savingsReward = 0,
    this.totalAmount,
    this.stepAmount = 50,
    this.difficultyLevel = DifficultyLevel.middle,
    this.expenseCategory,
  });

  final String id;
  final String templateId;
  final String title;
  final String description;
  final MissionTaskType type;
  final MissionTheme theme;
  final TaskTheme taskTheme;
  final TaskEconomyType economyType;
  final MissionDifficulty difficulty;
  final int estimatedSeconds;
  final int rewardCoins;
  final int realExpenseAmount;
  final int spendCoins;
  final int spendFromSavings;
  final int savingsReward;
  final int xpReward;
  final List<MissionTaskOption> options;
  final String? correctOptionId;
  final String explanation;
  final int? totalAmount;
  final int stepAmount;
  final DifficultyLevel difficultyLevel;
  final ExpenseCategory? expenseCategory;
  final String? scenarioKey;
  final bool acceptAnyOption;

  MissionTask forDifficulty(DifficultyLevel level) {
    return MissionTask(
      id: id,
      templateId: templateId,
      title: title,
      description: description,
      type: type,
      theme: theme,
      taskTheme: taskTheme,
      economyType: economyType,
      difficulty: difficulty,
      estimatedSeconds: estimatedSeconds,
      rewardCoins: rewardCoins,
      realExpenseAmount: realExpenseAmount,
      xpReward: xpReward,
      options: options,
      explanation: explanation,
      correctOptionId: correctOptionId,
      spendCoins: spendCoins,
      spendFromSavings: spendFromSavings,
      savingsReward: savingsReward,
      totalAmount: totalAmount,
      stepAmount: stepAmount,
      difficultyLevel: level,
      expenseCategory: expenseCategory,
      scenarioKey: scenarioKey,
      acceptAnyOption: acceptAnyOption,
    );
  }
}

class DailyMission {
  const DailyMission({
    required this.id,
    required this.date,
    required this.locationId,
    required this.title,
    required this.theme,
    required this.tasks,
    required this.estimatedMinutes,
    required this.maxReward,
    this.primaryTaskTheme = TaskTheme.math,
    this.secondaryTaskTheme = TaskTheme.logic,
  });

  final String id;
  final DateTime date;
  final String locationId;
  final String title;
  final MissionTheme theme;
  final List<MissionTask> tasks;
  final int estimatedMinutes;
  final int maxReward;
  final TaskTheme primaryTaskTheme;
  final TaskTheme secondaryTaskTheme;
}

class MissionResult {
  const MissionResult({
    required this.taskId,
    required this.isCorrect,
    required this.explanation,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.savingsBefore,
    required this.savingsAfter,
    required this.rewardCoins,
    required this.spentCoins,
    required this.spentFromSavings,
    required this.savedCoins,
    required this.xpEarned,
    required this.correctAnswer,
  });

  final String taskId;
  final bool isCorrect;
  final String explanation;
  final int balanceBefore;
  final int balanceAfter;
  final int savingsBefore;
  final int savingsAfter;
  final int rewardCoins;
  final int spentCoins;
  final int spentFromSavings;
  final int savedCoins;
  final int xpEarned;
  final String correctAnswer;
}
