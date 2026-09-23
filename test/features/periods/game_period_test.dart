import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/core/storage/app_database.dart';
import 'package:finance_pet/core/storage/app_state_repository.dart';
import 'package:finance_pet/features/budget/domain/budget_usage.dart';
import 'package:finance_pet/features/home/domain/pet_models.dart';
import 'package:finance_pet/features/missions/data/daily_task_templates.dart';
import 'package:finance_pet/features/missions/domain/mission_models.dart';
import 'package:finance_pet/features/periods/domain/game_period.dart';
import 'package:finance_pet/features/play/domain/mini_game_models.dart';

void main() {
  sqfliteFfiInit();

  group('GamePeriod', () {
    test('first period captures starting economy and pet state', () {
      final controller = AppController(now: DateTime(2026, 9, 22, 9));

      final mission = controller.missionForToday(now: DateTime(2026, 9, 22, 9));
      final period = controller.activeGamePeriod!;

      expect(period.status, GamePeriodStatus.active);
      expect(period.startingBalance, 1250);
      expect(period.startingSavings, 2400);
      expect(period.selectedGoalIdAtStart, 'bicycle');
      expect(period.missionId, mission.id);
      expect(period.locationId, mission.locationId);
      expect(period.petStateAtStart.mood, controller.petState.mood);
      expect(controller.budgetUsage.totalSpent, 0);
      expect(controller.budgetPlanConfirmed, isFalse);
    });

    test('earnings, expenses, deposits, and tasks aggregate once', () {
      final controller = AppController();
      controller.missionForToday(now: DateTime(2026, 9, 22));

      expect(
        controller.spendCoins(40, ExpenseCategory.essential),
        SpendCoinsResult.success,
      );
      expect(
        controller.spendCoins(30, ExpenseCategory.want),
        SpendCoinsResult.success,
      );
      expect(controller.addToSavings(100), SavingsDepositResult.success);
      controller.completeMiniGame(MiniGameType.ticTacToe, MiniGameResult.won);

      final period = controller.activeGamePeriod!;
      expect(period.essentialSpent, 40);
      expect(period.wantSpent, 30);
      expect(period.depositedToSavings, 100);
      expect(period.earnedCoins, 0);
    });

    test('simulation task never becomes a real period expense', () {
      final controller = AppController();
      final task = DailyTaskTemplates.build(
        templateId: 'calculate_remaining',
        id: 'simulation',
        difficulty: DifficultyLevel.junior,
        variant: 0,
        availableBalance: controller.balance,
      );
      final mission = DailyMission(
        id: 'simulation_mission',
        date: DateTime(2026, 9, 22),
        locationId: 'school',
        title: 'Simulation',
        theme: MissionTheme.math,
        tasks: [task],
        estimatedMinutes: 1,
        maxReward: task.rewardCoins,
      );

      controller.startMission(mission);
      controller.submitCurrentTask(
        selectedOptionId: task.correctOptionId,
        isCorrectOverride: true,
      );
      controller.advanceAfterResult();

      expect(controller.activeGamePeriod!.essentialSpent, 0);
      expect(controller.activeGamePeriod!.wantSpent, 0);
      expect(controller.budgetUsage.totalSpent, 0);
    });

    test(
      'finishMission keeps normal day completed and does not create another',
      () {
        final controller = AppController();
        final date = DateTime(2026, 9, 22, 10);
        final mission = controller.missionForToday(now: date);
        controller.startMission(mission);
        _finishActiveMission(controller);
        controller.finishMission();
        final completedId = controller.activeGamePeriod!.id;

        final sameDayMission = controller.missionForToday(
          now: DateTime(2026, 9, 22, 18),
        );

        expect(controller.activeGamePeriod!.status, GamePeriodStatus.completed);
        expect(controller.activeGamePeriod!.id, completedId);
        expect(sameDayMission.id, mission.id);
        expect(controller.completedGamePeriods, hasLength(1));
      },
    );

    test(
      'demo has five deterministic, distinct periods and no sixth',
      () async {
        final controller = AppController();
        expect(
          await controller.enterDemoMode(now: DateTime(2026, 9, 22)),
          isTrue,
        );
        final locations = <String>[];

        for (var day = 1; day <= 5; day++) {
          final mission = controller.missionForToday(
            now: DateTime(2026, 9, 22, 9 + day),
          );
          locations.add(mission.locationId);
          expect(controller.demoPeriodIndex, day);
          expect(mission.tasks.length, inInclusiveRange(10, 15));
          controller.startMission(mission);
          _finishActiveMission(controller);
          expect(controller.isCurrentPeriodCompleted, isTrue);

          if (day < 5) {
            final balance = controller.balance;
            final savings = controller.savings;
            final goal = controller.selectedGoalId;
            expect(await controller.startNextDemoPeriod(), isTrue);
            expect(controller.balance, balance);
            expect(controller.savings, savings);
            expect(controller.selectedGoalId, goal);
            expect(controller.budgetUsage.totalSpent, 0);
            expect(controller.budgetUsage.savingsDeposited, 0);
            expect(controller.budgetPlanConfirmed, isFalse);
          }
        }

        expect(locations, [
          'school',
          'game_center',
          'supermarket',
          'museum',
          'science_center',
        ]);
        expect(controller.completedGamePeriods, hasLength(5));
        expect(controller.isDemoComplete, isTrue);
        expect(await controller.startNextDemoPeriod(), isFalse);
        expect(controller.demoPeriodIndex, 5);
      },
    );
  });

  group('GamePeriod persistence and profile isolation', () {
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

    test('demo restart restores period 3 and task 4 of 12', () async {
      final controller = AppController(repository: repository);
      controller.missionForToday(now: DateTime(2026, 9, 22));
      await repository.save(controller.toSnapshot());
      await controller.enterDemoMode(now: DateTime(2026, 9, 22));

      for (var day = 1; day < 3; day++) {
        final mission = controller.missionForToday();
        controller.startMission(mission);
        _finishActiveMission(controller);
        expect(await controller.startNextDemoPeriod(), isTrue);
      }
      final periodThreeMission = controller.missionForToday();
      controller.startMission(periodThreeMission);
      _completeTasks(controller, 4);
      await controller.flushPersistence();

      final loaded = await repository.load();
      final restored = AppController.fromSnapshot(
        snapshot: loaded.snapshot!,
        repository: repository,
      );

      expect(restored.runMode, AppRunMode.demo);
      expect(restored.demoPeriodIndex, 3);
      expect(restored.activeGamePeriod!.locationId, 'supermarket');
      expect(restored.activeMission!.id, periodThreeMission.id);
      expect(restored.currentTaskIndex, 4);
      expect(restored.sessionCompletedTasks, 4);
    });

    test(
      'completed periods and demo index survive repository reload',
      () async {
        final controller = AppController(repository: repository);
        controller.missionForToday(now: DateTime(2026, 9, 22));
        await repository.save(controller.toSnapshot());
        await controller.enterDemoMode(now: DateTime(2026, 9, 22));
        final mission = controller.missionForToday();
        controller.startMission(mission);
        _finishActiveMission(controller);
        await controller.startNextDemoPeriod();
        await controller.flushPersistence();

        final loaded = await repository.load();

        expect(loaded.snapshot!.runMode, AppRunMode.demo);
        expect(loaded.snapshot!.demoPeriodIndex, 2);
        expect(loaded.snapshot!.completedGamePeriods, hasLength(1));
        expect(loaded.snapshot!.activeGamePeriod!.locationId, 'game_center');
      },
    );

    test('demo reset never modifies the normal profile', () async {
      final controller = AppController(repository: repository);
      controller.missionForToday(now: DateTime(2026, 9, 22));
      controller.completeMiniGame(MiniGameType.ticTacToe, MiniGameResult.won);
      final normalBalance = controller.balance;
      await repository.save(controller.toSnapshot());

      await controller.enterDemoMode(now: DateTime(2026, 9, 22));
      controller.completeMiniGame(MiniGameType.ticTacToe, MiniGameResult.won);
      await controller.resetDemoMode(now: DateTime(2026, 9, 22, 12));
      expect(controller.demoPeriodIndex, 1);
      expect(controller.balance, 1250);

      expect(await controller.exitDemoMode(), isTrue);
      expect(controller.runMode, AppRunMode.normal);
      expect(controller.balance, normalBalance);

      final normalStored = await repository.loadProfile(AppRunMode.normal);
      final demoStored = await repository.loadProfile(AppRunMode.demo);
      expect(normalStored.snapshot!.balance, normalBalance);
      expect(demoStored.snapshot!.balance, 1250);
      expect(demoStored.snapshot!.demoPeriodIndex, 1);
    });
  });
}

void _finishActiveMission(AppController controller) {
  final remaining =
      controller.activeMission!.tasks.length - controller.currentTaskIndex;
  _completeTasks(controller, remaining);
}

void _completeTasks(AppController controller, int count) {
  for (var index = 0; index < count; index++) {
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
