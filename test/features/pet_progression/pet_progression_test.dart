import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/core/storage/app_database.dart';
import 'package:finance_pet/core/storage/app_state_repository.dart';
import 'package:finance_pet/core/storage/app_state_snapshot.dart';
import 'package:finance_pet/features/budget/domain/budget_plan.dart';
import 'package:finance_pet/features/budget/domain/budget_usage.dart';
import 'package:finance_pet/features/home/domain/pet_models.dart';
import 'package:finance_pet/features/missions/data/daily_task_templates.dart';
import 'package:finance_pet/features/missions/domain/mission_models.dart';
import 'package:finance_pet/features/periods/domain/game_period.dart';
import 'package:finance_pet/features/pet_progression/domain/pet_progression.dart';
import 'package:finance_pet/features/pet_progression/domain/pet_progression_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  group('Pet progression policy', () {
    test('no completed actions gives zero growth', () {
      final evaluation = PetProgressionPolicy.evaluate(_period());

      expect(evaluation.totalPoints, 0);
    });

    test('confirmed budget adds planning points', () {
      final evaluation = PetProgressionPolicy.evaluate(
        _period(budgetWasConfirmed: true),
      );

      expect(evaluation.planningPoints, PetProgressionConfig.planningMax);
    });

    test('intentional deposit adds savings points relative to own plan', () {
      final evaluation = PetProgressionPolicy.evaluate(
        _period(intentionalSavingsDeposited: 240, depositedToSavings: 240),
      );

      expect(evaluation.savingsPoints, 6);
    });

    test('goal progress adds goal points', () {
      final evaluation = PetProgressionPolicy.evaluate(
        _period(
          depositedToSavings: 400,
          goalProgressAtStart: 0.4,
          goalProgressAtEnd: 0.48,
        ),
      );

      expect(evaluation.goalPoints, PetProgressionConfig.goalMax);
    });

    test('correct financial tasks add task points', () {
      final evaluation = PetProgressionPolicy.evaluate(
        _period(financialTaskCount: 5, correctFinancialTaskCount: 4),
      );

      expect(
        evaluation.financialTaskPoints,
        PetProgressionConfig.financialTasksMax,
      );
    });

    test('completing the whole mission adds completion points', () {
      final evaluation = PetProgressionPolicy.evaluate(
        _period(missionTaskCount: 10, completedTaskCount: 10),
      );

      expect(evaluation.completionPoints, PetProgressionConfig.completionMax);
    });

    test('maximum evaluation is exactly 30 and never exceeds it', () {
      final evaluation = PetProgressionPolicy.evaluate(
        _period(
          budgetWasConfirmed: true,
          essentialSpent: 300,
          wantSpent: 150,
          intentionalSavingsDeposited: 400,
          depositedToSavings: 400,
          goalProgressAtStart: 0.4,
          goalProgressAtEnd: 0.48,
          financialTaskCount: 10,
          correctFinancialTaskCount: 10,
          missionTaskCount: 10,
          completedTaskCount: 10,
        ),
      );

      expect(evaluation.totalPoints, 30);
      expect(
        evaluation.totalPoints,
        lessThanOrEqualTo(PetProgressionConfig.maxPointsPerPeriod),
      );
    });

    test('mandatory mission expense does not create a budget overrun', () {
      final evaluation = PetProgressionPolicy.evaluate(
        _period(
          budgetWasConfirmed: true,
          essentialSpent: 900,
          missionEssentialSpent: 500,
        ),
      );

      expect(evaluation.budgetPoints, PetProgressionConfig.budgetMax);
    });
  });

  group('Pet growth stages', () {
    test('threshold boundaries map to the expected stages', () {
      expect(PetProgressionConfig.stageForPoints(0), PetGrowthStage.little);
      expect(PetProgressionConfig.stageForPoints(39), PetGrowthStage.little);
      expect(PetProgressionConfig.stageForPoints(40), PetGrowthStage.growing);
      expect(PetProgressionConfig.stageForPoints(89), PetGrowthStage.growing);
      expect(PetProgressionConfig.stageForPoints(90), PetGrowthStage.grown);
    });

    test('adding nonnegative points never decreases the stage', () {
      var points = 0;
      var previous = PetProgressionConfig.stageForPoints(points);
      for (final award in [0, 12, 28, 20, 30, 5]) {
        points += award;
        final next = PetProgressionConfig.stageForPoints(points);
        expect(next.index, greaterThanOrEqualTo(previous.index));
        previous = next;
      }
    });
  });

  group('Pet progression integration', () {
    late AppDatabase database;
    late AppStateRepository repository;

    setUp(() {
      database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      repository = AppStateRepository(database);
    });

    tearDown(() => database.close());

    test('schema 2 profile loads safely with zero normal growth points', () {
      final legacyJson = AppController().toSnapshot().toJson()
        ..['schemaVersion'] = 2
        ..['childName'] = 'Миша'
        ..['age'] = 8
        ..remove('childProfile')
        ..remove('petGrowthPoints');

      final restored = AppStateSnapshot.fromJson(legacyJson);

      expect(restored.petGrowthPoints, 0);
    });

    test(
      'period evaluation is idempotent across summary and restart',
      () async {
        final controller = AppController(repository: repository);
        final mission = _oneTaskMission();
        controller.startMission(mission);
        expect(controller.confirmBudgetPlan(), isTrue);
        expect(controller.addToSavings(300), SavingsDepositResult.success);
        controller.submitCurrentTask(
          selectedOptionId: mission.tasks.single.correctOptionId,
        );
        controller.advanceAfterResult();

        final awarded = controller.activeGamePeriod!.growthPointsAwarded;
        final pointsAfterFinish = controller.petGrowthPoints;
        expect(awarded, greaterThan(0));
        expect(controller.activeGamePeriod!.growthEvaluated, isTrue);

        controller.completeCurrentPeriod();
        controller.finishMission();
        expect(controller.petGrowthPoints, pointsAfterFinish);
        await controller.flushPersistence();

        final loaded = await repository.load();
        final restored = AppController.fromSnapshot(
          snapshot: loaded.snapshot!,
          repository: repository,
        );
        restored.completeCurrentPeriod();

        expect(restored.petGrowthPoints, pointsAfterFinish);
        expect(restored.activeGamePeriod!.growthPointsAwarded, awarded);
      },
    );

    test('55 growth points persist and restore as growing', () async {
      final controller = AppController(repository: repository)
        ..petGrowthPoints = 55;
      await repository.save(controller.toSnapshot());

      final loaded = await repository.load();
      final restored = AppController.fromSnapshot(
        snapshot: loaded.snapshot!,
        repository: repository,
      );

      expect(restored.petGrowthPoints, 55);
      expect(restored.petGrowthStage, PetGrowthStage.growing);
    });

    test(
      'five successful demo periods use policy and can reach stage 3',
      () async {
        final controller = AppController();
        await controller.enterDemoMode(now: DateTime(2026, 9, 22));
        final initialPoints = controller.petGrowthPoints;
        final transitions = <PetGrowthStage>[];
        var previousStage = controller.petGrowthStage;

        for (var day = 1; day <= 5; day++) {
          final mission = controller.missionForToday();
          controller.startMission(mission);
          controller.budgetPlan = BudgetPlan(
            essentialsPlanned: controller.balance - 300,
            wantsPlanned: 100,
            savingsPlanned: 200,
          );
          expect(controller.confirmBudgetPlan(), isTrue);
          expect(controller.addToSavings(200), SavingsDepositResult.success);
          expect(
            controller.spendCoins(20, ExpenseCategory.essential),
            SpendCoinsResult.success,
          );
          _finishMissionCorrectly(controller);

          final period = controller.activeGamePeriod!;
          expect(period.growthEvaluation, isNotNull);
          expect(
            period.growthPointsAwarded,
            period.growthEvaluation!.totalPoints,
          );
          expect(
            period.growthPointsAwarded,
            lessThanOrEqualTo(PetProgressionConfig.maxPointsPerPeriod),
          );
          if (controller.petGrowthStage != previousStage) {
            transitions.add(controller.petGrowthStage);
            previousStage = controller.petGrowthStage;
          }
          if (day < 5) expect(await controller.startNextDemoPeriod(), isTrue);
        }

        expect(controller.petGrowthPoints, greaterThan(initialPoints));
        expect(transitions, isNotEmpty);
        expect(controller.petGrowthStage, PetGrowthStage.grown);
        expect(
          controller.completedGamePeriods
              .map((period) => period.petStageAtEnd)
              .last,
          PetGrowthStage.grown,
        );
      },
    );
  });
}

GamePeriod _period({
  bool budgetWasConfirmed = false,
  int essentialSpent = 0,
  int wantSpent = 0,
  int depositedToSavings = 0,
  int intentionalSavingsDeposited = 0,
  int missionEssentialSpent = 0,
  int financialTaskCount = 0,
  int correctFinancialTaskCount = 0,
  int missionTaskCount = 0,
  int completedTaskCount = 0,
  double goalProgressAtStart = 0.4,
  double goalProgressAtEnd = 0.4,
}) {
  const pet = PetStateSnapshot(mood: 75, satiety: 65, care: 70);
  return GamePeriod(
    id: 'period',
    sequenceNumber: 1,
    startedAt: DateTime(2026, 9, 22),
    completedAt: DateTime(2026, 9, 22, 18),
    status: GamePeriodStatus.completed,
    startingBalance: 1250,
    startingSavings: 2400,
    selectedGoalIdAtStart: 'bicycle',
    goalProgressAtStart: goalProgressAtStart,
    budgetPlanSnapshot: const BudgetPlan(
      essentialsPlanned: 500,
      wantsPlanned: 350,
      savingsPlanned: 400,
    ),
    budgetWasConfirmed: budgetWasConfirmed,
    earnedCoins: 0,
    essentialSpent: essentialSpent,
    wantSpent: wantSpent,
    depositedToSavings: depositedToSavings,
    completedTaskCount: completedTaskCount,
    correctTaskCount: correctFinancialTaskCount,
    missionId: 'mission',
    locationId: 'school',
    themeId: 'math',
    endingBalance: 1250,
    endingSavings: 2400,
    goalProgressAtEnd: goalProgressAtEnd,
    petStateAtStart: pet,
    petStateAtEnd: pet,
    isDemoPeriod: false,
    missionTaskCount: missionTaskCount,
    financialTaskCount: financialTaskCount,
    correctFinancialTaskCount: correctFinancialTaskCount,
    missionEssentialSpent: missionEssentialSpent,
    intentionalSavingsDeposited: intentionalSavingsDeposited,
  );
}

DailyMission _oneTaskMission() {
  final task = DailyTaskTemplates.build(
    templateId: 'calculate_remaining',
    id: 'financial_task',
    difficulty: DifficultyLevel.junior,
    variant: 0,
    availableBalance: 1250,
  );
  return DailyMission(
    id: 'growth_mission',
    date: DateTime(2026, 9, 22),
    locationId: 'school',
    title: 'Финансовое задание',
    theme: MissionTheme.math,
    tasks: [task],
    estimatedMinutes: 1,
    maxReward: task.rewardCoins,
  );
}

void _finishMissionCorrectly(AppController controller) {
  while (controller.currentTask != null) {
    final task = controller.currentTask!;
    controller.submitCurrentTask(
      selectedOptionId:
          task.correctOptionId ??
          (task.options.isEmpty ? null : task.options.first.id),
      isCorrectOverride: true,
    );
    controller.advanceAfterResult();
  }
}
