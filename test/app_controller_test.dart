import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/features/budget/domain/budget_plan.dart';
import 'package:finance_pet/features/budget/domain/budget_usage.dart';
import 'package:finance_pet/features/home/domain/pet_models.dart';
import 'package:finance_pet/features/missions/data/mock_daily_missions.dart';
import 'package:finance_pet/features/missions/data/daily_mission_generator.dart';
import 'package:finance_pet/features/missions/data/daily_task_templates.dart';
import 'package:finance_pet/features/missions/domain/mission_models.dart';
import 'package:finance_pet/features/play/domain/mini_game_models.dart';
import 'package:finance_pet/features/tasks/data/location_definitions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all mock daily missions contain 10 to 15 tasks', () {
    expect(MockDailyMissions.all, hasLength(4));
    for (final mission in MockDailyMissions.all) {
      expect(mission.tasks.length, inInclusiveRange(10, 15));
    }
  });

  test('daily catalog exposes all 26 reusable task templates', () {
    expect(DailyTaskTemplates.allTemplateIds, hasLength(26));
    expect(DailyTaskTemplates.allTemplateIds.toSet(), hasLength(26));

    for (final difficulty in DifficultyLevel.values) {
      for (final templateId in DailyTaskTemplates.allTemplateIds) {
        final task = DailyTaskTemplates.build(
          templateId: templateId,
          id: '${difficulty.name}_$templateId',
          difficulty: difficulty,
          variant: 3,
          availableBalance: 1250,
        );
        expect(task.templateId, templateId);
        expect(task.difficultyLevel, difficulty);
        expect(task.options, isNotEmpty);
        expect(task.estimatedSeconds, greaterThan(0));
      }
    }
  });

  test('daily generator is deterministic and keeps economy positive', () {
    const generator = DailyMissionGenerator();
    final first = generator.generate(
      date: DateTime(2026, 9, 21),
      childName: 'Миша',
      age: 8,
      difficulty: DifficultyLevel.junior,
      balance: 1250,
    );
    final second = generator.generate(
      date: DateTime(2026, 9, 21),
      childName: 'Миша',
      age: 8,
      difficulty: DifficultyLevel.junior,
      balance: 1250,
    );

    expect(first.id, second.id);
    expect(
      first.tasks.map((task) => task.templateId),
      orderedEquals(second.tasks.map((task) => task.templateId)),
    );
    expect(
      first.tasks.map((task) => task.scenarioKey),
      orderedEquals(second.tasks.map((task) => task.scenarioKey)),
    );
    expect(first.tasks, hasLength(12));
    final realExpenses = first.tasks
        .where((task) => task.economyType == TaskEconomyType.realExpense)
        .toList();
    expect(realExpenses.length, inInclusiveRange(1, 3));
    for (var index = 1; index < first.tasks.length; index++) {
      expect(
        first.tasks[index - 1].economyType == TaskEconomyType.realExpense &&
            first.tasks[index].economyType == TaskEconomyType.realExpense,
        isFalse,
      );
    }
    final maximumSpend = realExpenses.fold<int>(
      0,
      (sum, task) =>
          sum +
          task.options.fold<int>(
            0,
            (largest, option) =>
                option.spendCoins > largest ? option.spendCoins : largest,
          ),
    );
    expect(first.maxReward, greaterThan(maximumSpend));
  });

  test('controller keeps one generated mission for the same day', () {
    final controller = AppController();
    final first = controller.missionForToday(now: DateTime(2026, 9, 21));
    controller.balance = 0;
    final second = controller.missionForToday(now: DateTime(2026, 9, 21, 22));

    expect(identical(first, second), isTrue);
    controller.updateChildProfile(age: 9);
    final adapted = controller.missionForToday(now: DateTime(2026, 9, 21));
    expect(identical(first, adapted), isTrue);
    expect(controller.difficultyLevel, DifficultyLevel.middle);

    controller.completeCurrentPeriod(now: DateTime(2026, 9, 21, 23));
    controller.finishMission();
    final next = controller.missionForToday(now: DateTime(2026, 9, 22));

    expect(identical(first, next), isFalse);
    expect(
      next.tasks.every(
        (task) => task.difficultyLevel == DifficultyLevel.middle,
      ),
      isTrue,
    );
  });

  test('location rotation skips the seven most recent locations', () {
    const generator = DailyMissionGenerator();
    final recent = LocationDefinitions.all
        .take(7)
        .map((item) => item.id)
        .toList();
    final mission = generator.generate(
      date: DateTime(2026, 9, 22),
      childName: 'Миша',
      age: 9,
      difficulty: DifficultyLevel.middle,
      balance: 1250,
      recentLocationIds: recent,
    );

    expect(LocationDefinitions.all, hasLength(12));
    expect(recent, isNot(contains(mission.locationId)));
    final eightDays = <String>{
      for (var day = 0; day < 8; day++)
        generator
            .generate(
              date: DateTime(2026, 10, 1 + day),
              childName: 'Миша',
              age: 9,
              difficulty: DifficultyLevel.middle,
              balance: 1250,
            )
            .locationId,
    };
    expect(eightDays, hasLength(8));
    for (final location in LocationDefinitions.all) {
      expect(location.normalizedPosition.dx, inInclusiveRange(0, 1));
      expect(location.normalizedPosition.dy, inInclusiveRange(0, 1));
    }
  });

  test('simulation keeps balance while real expense updates budget usage', () {
    final controller = AppController();
    final simulation = DailyTaskTemplates.build(
      templateId: 'calculate_remaining',
      id: 'simulation',
      difficulty: DifficultyLevel.junior,
      variant: 0,
      availableBalance: controller.balance,
    );
    controller.startMission(
      DailyMission(
        id: 'simulation_mission',
        date: DateTime(2026, 9, 21),
        locationId: 'school',
        title: 'Simulation',
        theme: MissionTheme.math,
        tasks: [simulation],
        estimatedMinutes: 1,
        maxReward: simulation.rewardCoins,
      ),
    );
    final balanceBeforeSimulation = controller.balance;
    controller.submitCurrentTask(selectedOptionId: simulation.correctOptionId);
    expect(controller.balance, balanceBeforeSimulation);

    final expense = DailyTaskTemplates.build(
      templateId: 'choose_entertainment',
      id: 'expense',
      difficulty: DifficultyLevel.junior,
      variant: 0,
      availableBalance: controller.balance,
    );
    controller.startMission(
      DailyMission(
        id: 'expense_mission',
        date: DateTime(2026, 9, 21),
        locationId: 'game_center',
        title: 'Expense',
        theme: MissionTheme.entertainment,
        tasks: [expense],
        estimatedMinutes: 1,
        maxReward: 0,
      ),
    );
    final selected = expense.options.first;
    final balanceBeforeExpense = controller.balance;
    controller.submitCurrentTask(selectedOptionId: selected.id);
    expect(controller.balance, balanceBeforeExpense - selected.spendCoins);
    expect(controller.budgetUsage.wantsSpent, selected.spendCoins);
  });

  test('a full 12-task mission updates state and never goes negative', () {
    final controller = AppController();
    final mission = MockDailyMissions.today;
    controller.startMission(mission);

    var checkpoints = 0;
    for (var index = 0; index < mission.tasks.length; index++) {
      final task = controller.currentTask!;
      final needsOverride =
          task.type == MissionTaskType.budgetSplit ||
          task.type == MissionTaskType.classification;
      controller.submitCurrentTask(
        selectedOptionId: task.correctOptionId,
        isCorrectOverride: needsOverride ? true : null,
      );

      expect(controller.balance, greaterThanOrEqualTo(0));
      expect(controller.savings, greaterThanOrEqualTo(0));

      final next = controller.advanceAfterResult();
      if (next == MissionNextStep.checkpoint) checkpoints += 1;
      if (index == mission.tasks.length - 1) {
        expect(next, MissionNextStep.complete);
      }
    }

    expect(controller.sessionCompletedTasks, 12);
    expect(controller.completedMissions, 1);
    expect(checkpoints, 2);
    expect(controller.sessionEarnedCoins, greaterThan(0));
    expect(controller.petXp, greaterThan(680));
  });

  test('an unaffordable purchase cannot make the balance negative', () {
    final controller = AppController();
    final mission = DailyMission(
      id: 'safety',
      date: DateTime(2026, 9, 19),
      locationId: 'game_center',
      title: 'Safety',
      theme: MissionTheme.shopping,
      estimatedMinutes: 1,
      maxReward: 5,
      tasks: const [
        MissionTask(
          id: 'too_expensive',
          title: 'Покупка',
          description: 'Проверка баланса',
          type: MissionTaskType.choice,
          theme: MissionTheme.shopping,
          difficulty: MissionDifficulty.easy,
          estimatedSeconds: 30,
          rewardCoins: 5,
          xpReward: 2,
          correctOptionId: 'buy',
          explanation: 'Проверка',
          options: [
            MissionTaskOption(id: 'buy', label: 'Купить', spendCoins: 5000),
          ],
        ),
      ],
    );

    controller.startMission(mission);
    final result = controller.submitCurrentTask(selectedOptionId: 'buy');

    expect(result.spentCoins, 0);
    expect(controller.balance, greaterThanOrEqualTo(0));
    expect(result.isCorrect, isFalse);
  });

  test('a wrong answer gives no coins, XP, or monetary penalty', () {
    final controller = AppController();
    final mission = MockDailyMissions.todayFor(DifficultyLevel.junior);
    controller.startMission(mission);
    final task = controller.currentTask!;
    final wrongOption = task.options.firstWhere(
      (option) => option.id != task.correctOptionId,
    );
    final balanceBefore = controller.balance;
    final savingsBefore = controller.savings;
    final xpBefore = controller.petXp;

    final result = controller.submitCurrentTask(
      selectedOptionId: wrongOption.id,
    );

    expect(result.isCorrect, isFalse);
    expect(result.rewardCoins, 0);
    expect(result.xpEarned, 0);
    expect(controller.balance, balanceBefore);
    expect(controller.savings, savingsBefore);
    expect(controller.petXp, xpBefore);
    expect(result.correctAnswer, isNotEmpty);
  });

  test('age selects compatible task parameters for the next mission', () {
    final controller = AppController();

    controller.updateChildProfile(age: 7);
    final junior = MockDailyMissions.todayFor(controller.difficultyLevel);
    expect(controller.difficultyLevel, DifficultyLevel.junior);
    expect(
      junior.tasks.every(
        (task) => task.difficultyLevel == DifficultyLevel.junior,
      ),
      isTrue,
    );
    expect(junior.tasks[1].description, contains('20 монет'));

    controller.updateChildProfile(age: 9);
    final middle = MockDailyMissions.todayFor(controller.difficultyLevel);
    expect(controller.difficultyLevel, DifficultyLevel.middle);
    expect(middle.tasks[1].description, contains('100 монет'));

    controller.updateChildProfile(age: 11);
    final senior = MockDailyMissions.todayFor(controller.difficultyLevel);
    expect(controller.difficultyLevel, DifficultyLevel.senior);
    expect(senior.tasks[1].description, contains('500 монет'));
    expect(senior.tasks[4].description, contains('275 и 185'));
  });

  test('saving 300 coins moves money from balance to savings', () {
    final controller = AppController();

    final didSave = controller.addToSavings(300);

    expect(didSave, SavingsDepositResult.success);
    expect(controller.balance, 950);
    expect(controller.savings, 2700);
    expect(controller.budgetUsage.savingsDeposited, 300);
    expect(controller.goalProgress, closeTo(0.54, 0.001));
  });

  test('saving cannot exceed balance or the remaining goal amount', () {
    final controller = AppController()
      ..balance = 100
      ..savings = 4900;

    expect(
      controller.addToSavings(101),
      SavingsDepositResult.insufficientFunds,
    );
    expect(
      controller.addToSavings(150),
      SavingsDepositResult.insufficientFunds,
    );
    expect(controller.balance, 100);
    expect(controller.savings, 4900);

    expect(controller.addToSavings(100), SavingsDepositResult.success);
    expect(controller.balance, 0);
    expect(controller.savings, 5000);
    expect(controller.goalProgress, 1);
    expect(controller.isGoalReached, isTrue);
  });

  test('changing the selected goal keeps all savings', () {
    final controller = AppController();
    final savingsBefore = controller.savings;

    expect(controller.selectGoal('scooter'), isTrue);
    expect(controller.selectedGoalId, 'scooter');
    expect(controller.goalPrice, 3200);
    expect(controller.savings, savingsBefore);
    expect(controller.goalProgress, closeTo(0.75, 0.001));
  });

  test('saving above the dream plan requires confirmation', () {
    final controller = AppController();

    expect(
      controller.addToSavings(500),
      SavingsDepositResult.requiresConfirmation,
    );
    expect(controller.balance, 1250);
    expect(controller.savings, 2400);

    expect(
      controller.addToSavings(500, confirmPlanOverrun: true),
      SavingsDepositResult.success,
    );
    expect(controller.balance, 750);
    expect(controller.savings, 2900);
    expect(controller.budgetUsage.savingsDeposited, 500);
  });

  test('budget categories total correctly and respect all limits', () {
    final controller = AppController();

    expect(controller.totalBudgetAllocated, 1250);
    expect(controller.canConfirmBudget, isTrue);
    expect(
      controller.updateBudgetCategory(BudgetCategory.essentials, 50),
      isFalse,
    );

    expect(
      controller.updateBudgetCategory(BudgetCategory.essentials, -50),
      isTrue,
    );
    expect(controller.totalBudgetAllocated, 1200);
    expect(controller.budgetRemainingToAllocate, 50);
    expect(controller.canConfirmBudget, isFalse);
    expect(
      controller.updateBudgetCategory(BudgetCategory.essentials, -500),
      isFalse,
    );
    expect(controller.budgetPlan.essentialsPlanned, 450);

    expect(controller.updateBudgetCategory(BudgetCategory.savings, 50), isTrue);
    expect(controller.totalBudgetAllocated, controller.balance);
  });

  test('confirming a budget plan never moves real money', () {
    final controller = AppController();
    final balanceBefore = controller.balance;
    final savingsBefore = controller.savings;

    expect(controller.confirmBudgetPlan(), isTrue);

    expect(controller.budgetPlanConfirmed, isTrue);
    expect(controller.balance, balanceBefore);
    expect(controller.savings, savingsBefore);
  });

  test('a lower balance keeps the existing plan unchanged', () {
    final controller = AppController();
    final oldPlan = controller.budgetPlan;
    controller.balance = 950;

    expect(controller.budgetPlan, same(oldPlan));
    expect(controller.budgetPlanNeedsUpdate, isTrue);
    expect(controller.budgetRemainingToAllocate, -300);
    expect(controller.budgetPlan.savingsPlanned, 400);
    expect(controller.totalBudgetAllocated, 1250);
    expect(controller.canConfirmBudget, isFalse);
  });

  test('feeding spends coins, records budget usage, and updates pet', () {
    final now = DateTime(2026, 9, 20, 12);
    final controller = AppController(now: now);

    final result = controller.feedPet(FoodType.basic, now: now);

    expect(result, FeedPetResult.success);
    expect(controller.balance, 1230);
    expect(controller.budgetUsage.essentialsSpent, 20);
    expect(controller.budgetUsage.wantsSpent, 0);
    expect(controller.petState.satiety, 95);
    expect(controller.petState.mood, 79);
    expect(controller.petState.lastFedAt, now);
  });

  test('a treat is recorded as a want expense', () {
    final controller = AppController();

    expect(controller.feedPet(FoodType.treat), FeedPetResult.success);

    expect(controller.balance, 1200);
    expect(controller.budgetUsage.wantsSpent, 50);
    expect(controller.budgetUsage.essentialsSpent, 0);
  });

  test('exceeding a category asks for confirmation but remains possible', () {
    final controller = AppController();

    expect(
      controller.spendCoins(350, ExpenseCategory.want),
      SpendCoinsResult.success,
    );
    expect(
      controller.spendCoins(50, ExpenseCategory.want),
      SpendCoinsResult.requiresConfirmation,
    );
    expect(controller.balance, 900);
    expect(controller.budgetUsage.wantsSpent, 350);

    expect(
      controller.spendCoins(50, ExpenseCategory.want, confirmPlanOverrun: true),
      SpendCoinsResult.success,
    );
    expect(controller.balance, 850);
    expect(controller.budgetUsage.wantsSpent, 400);
  });

  test('mission purchases update their real expense category', () {
    final controller = AppController();
    final mission = DailyMission(
      id: 'expense',
      date: DateTime(2026, 9, 20),
      locationId: 'school',
      title: 'Покупка для школы',
      theme: MissionTheme.shopping,
      estimatedMinutes: 1,
      maxReward: 0,
      tasks: const [
        MissionTask(
          id: 'notebook',
          title: 'Тетрадь',
          description: 'Купить нужную тетрадь',
          type: MissionTaskType.choice,
          theme: MissionTheme.shopping,
          difficulty: MissionDifficulty.easy,
          estimatedSeconds: 20,
          rewardCoins: 0,
          xpReward: 1,
          correctOptionId: 'buy',
          explanation: 'Тетрадь нужна для школы.',
          options: [
            MissionTaskOption(
              id: 'buy',
              label: 'Купить',
              spendCoins: 100,
              expenseCategory: ExpenseCategory.essential,
            ),
          ],
        ),
      ],
    );

    controller.startMission(mission);
    controller.submitCurrentTask(selectedOptionId: 'buy');

    expect(controller.balance, 1150);
    expect(controller.budgetUsage.essentialsSpent, 100);
  });

  test('new mission income creates money left to allocate', () {
    final controller = AppController();
    final mission = MockDailyMissions.todayFor(DifficultyLevel.junior);
    controller.startMission(mission);
    final task = controller.currentTask!;

    controller.submitCurrentTask(selectedOptionId: task.correctOptionId);

    expect(controller.balance, greaterThan(1250));
    expect(
      controller.budgetRemainingToAllocate,
      controller.balance - controller.totalBudgetAllocated,
    );
    expect(controller.budgetRemainingToAllocate, greaterThan(0));
  });

  test('feeding never creates a negative balance', () {
    final controller = AppController()..balance = 10;
    final petBefore = controller.petState;

    final result = controller.feedPet(FoodType.healthy);

    expect(result, FeedPetResult.insufficientFunds);
    expect(controller.balance, 10);
    expect(controller.petState.satiety, petBefore.satiety);
    expect(controller.budgetUsage.totalSpent, 0);
  });

  test('petting and a mini-game update pet state with a cap of 100', () {
    final controller = AppController();

    controller.petFox();
    expect(controller.petState.mood, 81);
    expect(controller.petState.care, 82);

    controller.completeMiniGame(MiniGameType.ticTacToe, MiniGameResult.won);
    controller.completeMiniGame(
      MiniGameType.ticTacToe,
      MiniGameResult.completed,
    );
    expect(controller.petState.mood, 94);
    expect(controller.petState.care, 82);
    expect(controller.balance, 1250);
  });

  test('mini-game awards XP once without changing coins', () {
    final controller = AppController();

    final first = controller.completeMiniGame(
      MiniGameType.ticTacToe,
      MiniGameResult.won,
    );
    final repeated = controller.completeMiniGame(
      MiniGameType.ticTacToe,
      MiniGameResult.lost,
    );

    expect(first.xp, 2);
    expect(repeated.xp, 0);
    expect(controller.balance, 1250);
    expect(controller.petXp, 682);
  });

  test('satiety decreases only for completed hunger intervals', () {
    final startedAt = DateTime(2026, 9, 20, 12);
    final controller = AppController(now: startedAt);

    controller.refreshPetState(now: startedAt.add(const Duration(minutes: 14)));
    expect(controller.petState.satiety, 65);

    controller.refreshPetState(now: startedAt.add(const Duration(minutes: 30)));
    expect(controller.petState.satiety, 59);
  });

  test('reset restores pet, economy, settings, and budget usage', () {
    final controller = AppController()
      ..balance = 10
      ..setSoundEnabled(false)
      ..setHintsEnabled(false);
    controller.petFox();
    controller.resetDemoData(now: DateTime(2026, 9, 20));

    expect(controller.balance, 1250);
    expect(controller.savings, 2400);
    expect(controller.petState.mood, 75);
    expect(controller.petState.satiety, 65);
    expect(controller.petState.care, 70);
    expect(controller.budgetUsage.totalSpent, 0);
    expect(controller.soundEnabled, isTrue);
    expect(controller.hintsEnabled, isTrue);
  });
}
