import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/core/storage/app_database.dart';
import 'package:finance_pet/core/storage/app_state_repository.dart';
import 'package:finance_pet/core/storage/app_state_snapshot.dart';
import 'package:finance_pet/features/budget/domain/budget_plan.dart';
import 'package:finance_pet/features/budget/domain/budget_usage.dart';
import 'package:finance_pet/features/home/domain/pet_models.dart';
import 'package:finance_pet/features/missions/domain/mission_models.dart';
import 'package:finance_pet/features/periods/domain/game_period.dart';

void main() {
  sqfliteFfiInit();

  group('App state persistence', () {
    late AppDatabase database;
    late AppStateRepository repository;

    setUp(() {
      database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      repository = AppStateRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('snapshot serialize and deserialize preserves explicit fields', () {
      final controller = AppController(now: DateTime(2026, 9, 21, 10))
        ..updateChildProfile(name: 'Лена', age: 11)
        ..selectGoal('scooter');
      controller.petFox(now: DateTime(2026, 9, 21, 11));

      final encoded = jsonEncode(controller.toSnapshot().toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored = AppStateSnapshot.fromJson(decoded);

      expect(restored.childName, 'Лена');
      expect(restored.age, 11);
      expect(restored.difficultyLevel, DifficultyLevel.senior);
      expect(restored.selectedGoalId, 'scooter');
      expect(restored.petState.mood, controller.petState.mood);
      expect(restored.petState.lastPettedAt, DateTime(2026, 9, 21, 11));
    });

    test('version 1 snapshot remains readable as a normal profile', () {
      final legacyJson =
          AppController(now: DateTime(2026, 9, 21)).toSnapshot().toJson()
            ..['schemaVersion'] = 1
            ..['childName'] = 'Миша'
            ..['age'] = 8
            ..remove('childProfile')
            ..remove('runMode')
            ..remove('activeGamePeriod')
            ..remove('completedGamePeriods')
            ..remove('demoPeriodIndex');

      final restored = AppStateSnapshot.fromJson(legacyJson);

      expect(restored.runMode, AppRunMode.normal);
      expect(restored.activeGamePeriod, isNull);
      expect(restored.completedGamePeriods, isEmpty);
      expect(restored.demoPeriodIndex, 1);
    });

    test(
      'economy, goal, budget, pet, profile, and settings survive reload',
      () async {
        final controller = AppController(
          now: DateTime(2026, 9, 21, 10),
          repository: repository,
        );
        controller.updateChildProfile(name: 'Саша', age: 10);
        controller.selectGoal('scooter');
        expect(
          controller.updateBudgetCategory(BudgetCategory.essentials, -50),
          isTrue,
        );
        expect(
          controller.updateBudgetCategory(BudgetCategory.savings, 50),
          isTrue,
        );
        expect(controller.confirmBudgetPlan(), isTrue);
        expect(controller.addToSavings(100), SavingsDepositResult.success);
        expect(
          controller.feedPet(FoodType.basic, now: DateTime(2026, 9, 21, 10, 5)),
          FeedPetResult.success,
        );
        controller.petFox(now: DateTime(2026, 9, 21, 10, 6));
        controller.setSoundEnabled(false);
        controller.setHintsEnabled(false);
        await controller.flushPersistence();

        final restored = await _reload(repository);

        expect(restored.childName, 'Саша');
        expect(restored.age, 10);
        expect(restored.difficultyLevel, DifficultyLevel.middle);
        expect(restored.balance, controller.balance);
        expect(restored.savings, controller.savings);
        expect(restored.selectedGoalId, 'scooter');
        expect(
          restored.budgetPlan,
          isA<BudgetPlan>()
              .having((value) => value.essentialsPlanned, 'important', 450)
              .having((value) => value.savingsPlanned, 'dream', 450),
        );
        expect(restored.budgetPlanConfirmed, isTrue);
        expect(
          restored.budgetUsage.essentialsSpent,
          controller.budgetUsage.essentialsSpent,
        );
        expect(restored.budgetUsage.savingsDeposited, 100);
        expect(restored.petState.mood, controller.petState.mood);
        expect(restored.petState.satiety, controller.petState.satiety);
        expect(restored.petState.care, controller.petState.care);
        expect(restored.petState.lastFedAt, DateTime(2026, 9, 21, 10, 5));
        expect(restored.petState.lastPettedAt, DateTime(2026, 9, 21, 10, 6));
        expect(restored.soundEnabled, isFalse);
        expect(restored.hintsEnabled, isFalse);
      },
    );

    test('DailyMission and progress 5 of N survive exactly', () async {
      final controller = AppController(
        now: DateTime(2026, 9, 21, 10),
        repository: repository,
      );
      final mission = controller.missionForToday(
        now: DateTime(2026, 9, 21, 10),
      );
      controller.startMission(mission);

      for (var index = 0; index < 5; index++) {
        final task = controller.currentTask!;
        controller.submitCurrentTask(
          selectedOptionId: task.correctOptionId,
          isCorrectOverride: true,
        );
        expect(
          controller.advanceAfterResult(),
          isNot(MissionNextStep.complete),
        );
      }
      final expectedSnapshot = controller.toSnapshot();
      await controller.flushPersistence();

      final restored = await _reload(repository);

      expect(restored.activeMission?.id, mission.id);
      expect(restored.activeMission?.locationId, mission.locationId);
      expect(
        restored.activeMission?.tasks.map((task) => task.id),
        mission.tasks.map((task) => task.id),
      );
      expect(restored.currentTaskIndex, 5);
      expect(restored.sessionCompletedTasks, 5);
      expect(restored.balance, expectedSnapshot.balance);
      expect(restored.sessionEarnedCoins, expectedSnapshot.sessionEarnedCoins);
      expect(restored.currentTask?.id, mission.tasks[5].id);
    });

    test(
      'pending mission result survives reload without duplicate reward',
      () async {
        final controller = AppController(repository: repository);
        final mission = controller.missionForToday(now: DateTime(2026, 9, 21));
        controller.startMission(mission);
        final task = controller.currentTask!;
        final result = controller.submitCurrentTask(
          selectedOptionId: task.correctOptionId,
          isCorrectOverride: true,
        );
        await controller.flushPersistence();

        final restored = await _reload(repository);

        expect(restored.awaitingMissionAdvance, isTrue);
        expect(restored.lastResult?.taskId, result.taskId);
        expect(restored.lastResult?.rewardCoins, result.rewardCoins);
        expect(restored.balance, result.balanceAfter);
      },
    );

    test('reset clears old state and stores initial state', () async {
      final controller = AppController(repository: repository);
      controller.updateChildProfile(name: 'Старое имя', age: 11);
      controller.selectGoal('scooter');
      expect(controller.addToSavings(200), SavingsDepositResult.success);
      await controller.flushPersistence();

      await controller.resetDemoData(now: DateTime(2026, 9, 21, 12));
      await controller.flushPersistence();
      final restored = await _reload(repository);

      expect(restored.childName, 'Миша');
      expect(restored.age, 8);
      expect(restored.balance, 1250);
      expect(restored.savings, 2400);
      expect(restored.selectedGoalId, 'bicycle');
      expect(restored.activeMission, isNull);
      expect(restored.currentTaskIndex, 0);
      expect(restored.budgetUsage.totalSpent, 0);
      expect(restored.soundEnabled, isTrue);
      expect(restored.hintsEnabled, isTrue);
    });

    test('corrupted snapshot is reported without deleting its row', () async {
      final sqlite = await database.database;
      await sqlite.insert(AppDatabase.tableAppState, {
        'id': AppDatabase.singletonStateId,
        'schema_version': AppStateSnapshot.schemaVersion,
        'payload_json': '{not-json',
        'updated_at': DateTime(2026, 9, 21).toIso8601String(),
      });

      final firstLoad = await repository.load();
      final secondLoad = await repository.load();

      expect(firstLoad.isCorrupted, isTrue);
      expect(secondLoad.isCorrupted, isTrue);
      expect(await sqlite.query(AppDatabase.tableAppState), hasLength(1));
    });
  });
}

Future<AppController> _reload(AppStateRepository repository) async {
  final result = await repository.load();
  expect(result.error, isNull);
  expect(result.snapshot, isNotNull);
  return AppController.fromSnapshot(
    snapshot: result.snapshot!,
    repository: repository,
  );
}
