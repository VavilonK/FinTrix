import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/core/storage/app_database.dart';
import 'package:finance_pet/core/storage/app_state_repository.dart';
import 'package:finance_pet/features/finance/data/financial_transaction_repository.dart';
import 'package:finance_pet/features/home/domain/pet_models.dart';
import 'package:finance_pet/features/periods/domain/game_period.dart';
import 'package:finance_pet/features/play/domain/mini_game_models.dart';
import 'package:finance_pet/features/play/presentation/widgets/mini_game_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  group('mini-game anti-farm policy', () {
    test('every mini-game leaves all financial state unchanged', () async {
      final transactions = InMemoryFinancialTransactionRepository();
      final controller = AppController(financialTransactions: transactions)
        ..balance = 1000;
      controller.missionForToday(now: DateTime(2026, 9, 23));
      final savingsBefore = controller.savings;
      final usageBefore = controller.budgetUsage;

      for (final game in MiniGameType.values) {
        controller.completeMiniGame(game, MiniGameResult.won);
      }
      await controller.flushPersistence();

      expect(controller.balance, 1000);
      expect(controller.savings, savingsBefore);
      expect(controller.budgetUsage, same(usageBefore));
      expect(controller.activeGamePeriod!.earnedCoins, 0);
      expect(await controller.recentFinancialTransactions(), isEmpty);
      controller.dispose();
    });

    test('one game awards exactly two XP once regardless of result', () {
      final controller = AppController()..petXp = 100;

      expect(
        controller
            .completeMiniGame(MiniGameType.ticTacToe, MiniGameResult.lost)
            .xp,
        2,
      );
      for (var attempt = 0; attempt < 9; attempt++) {
        expect(
          controller
              .completeMiniGame(MiniGameType.ticTacToe, MiniGameResult.won)
              .xp,
          0,
        );
      }
      expect(controller.petXp, 102);

      expect(
        controller
            .completeMiniGame(MiniGameType.matchingPairs, MiniGameResult.draw)
            .xp,
        2,
      );
      expect(controller.petXp, 104);
      controller.dispose();
    });

    test('all five games award at most ten XP per period', () {
      final controller = AppController()..petXp = 100;

      for (final game in MiniGameType.values) {
        controller.completeMiniGame(game, MiniGameResult.completed);
      }
      expect(controller.petXp, 110);
      expect(controller.activeGamePeriod!.rewardedMiniGameIds, hasLength(5));

      for (var replay = 0; replay < 4; replay++) {
        for (final game in MiniGameType.values) {
          controller.completeMiniGame(game, MiniGameResult.won);
        }
      }
      expect(controller.petXp, 110);
      controller.dispose();
    });

    test('a new normal period resets eligibility', () {
      final controller = AppController()..petXp = 100;
      final firstDay = DateTime(2026, 9, 23, 9);
      controller.missionForToday(now: firstDay);

      controller.completeMiniGame(
        MiniGameType.ticTacToe,
        MiniGameResult.won,
        now: firstDay,
      );
      controller.completeMiniGame(
        MiniGameType.ticTacToe,
        MiniGameResult.won,
        now: firstDay,
      );
      expect(controller.petXp, 102);
      controller.completeCurrentPeriod(now: firstDay);

      final secondDay = firstDay.add(const Duration(days: 1));
      controller.missionForToday(now: secondDay);
      expect(controller.activeGamePeriod!.rewardedMiniGameIds, isEmpty);
      controller.completeMiniGame(
        MiniGameType.ticTacToe,
        MiniGameResult.lost,
        now: secondDay,
      );
      expect(controller.petXp, 104);
      controller.dispose();
    });

    test(
      'a new demo period resets eligibility without special rewards',
      () async {
        final controller = AppController();
        await controller.enterDemoMode(now: DateTime(2026, 9, 23, 9));
        final initialXp = controller.petXp;

        controller.completeMiniGame(MiniGameType.ticTacToe, MiniGameResult.won);
        controller.completeMiniGame(MiniGameType.ticTacToe, MiniGameResult.won);
        expect(controller.petXp, initialXp + 2);

        controller.completeCurrentPeriod(now: DateTime(2026, 9, 23, 10));
        expect(await controller.startNextDemoPeriod(), isTrue);
        expect(controller.activeGamePeriod!.rewardedMiniGameIds, isEmpty);
        controller.completeMiniGame(
          MiniGameType.ticTacToe,
          MiniGameResult.draw,
        );
        expect(controller.petXp, initialXp + 4);
        controller.dispose();
      },
    );

    test('rewarded games survive repository restart', () async {
      final database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      addTearDown(database.close);
      final repository = AppStateRepository(database);
      final controller = AppController(repository: repository)..petXp = 100;
      controller.completeMiniGame(MiniGameType.ticTacToe, MiniGameResult.won);
      await controller.flushPersistence();

      final loaded = await repository.loadProfile(AppRunMode.normal);
      final restored = AppController.fromSnapshot(
        snapshot: loaded.snapshot!,
        repository: repository,
      );
      final reward = restored.completeMiniGame(
        MiniGameType.ticTacToe,
        MiniGameResult.won,
      );

      expect(restored.petXp, 102);
      expect(reward.xp, 0);
      expect(
        restored.activeGamePeriod!.rewardedMiniGameIds,
        contains(MiniGameType.ticTacToe.persistentId),
      );
      controller.dispose();
      restored.dispose();
    });

    test('mini-games never change growth points or growth stage', () {
      final controller = AppController()..petGrowthPoints = 30;
      final stageBefore = controller.petGrowthStage;

      for (final game in MiniGameType.values) {
        controller.completeMiniGame(game, MiniGameResult.won);
      }

      expect(controller.petGrowthPoints, 30);
      expect(controller.petGrowthStage, stageBefore);
      controller.dispose();
    });

    test('mood uses capped first and replay gains', () {
      final controller = AppController()
        ..petState = const PetState(mood: 88, satiety: 65, care: 70);

      controller.completeMiniGame(
        MiniGameType.oddOneOut,
        MiniGameResult.completed,
      );
      expect(controller.petState.mood, 98);
      controller.completeMiniGame(
        MiniGameType.oddOneOut,
        MiniGameResult.completed,
      );
      expect(controller.petState.mood, 100);
      controller.dispose();
    });
  });

  group('mini-game result UI', () {
    testWidgets('first completion shows XP but never coins', (tester) async {
      await tester.pumpWidget(_resultCard(const MiniGameReward(xp: 2)));

      expect(find.text('+2 XP'), findsOneWidget);
      expect(find.text('Рыжику понравилось играть!'), findsOneWidget);
      expect(find.textContaining('монет'), findsNothing);
    });

    testWidgets('replay shows encouragement instead of zero XP', (
      tester,
    ) async {
      await tester.pumpWidget(_resultCard(const MiniGameReward(xp: 0)));

      expect(find.text('Мне нравится играть с тобой!'), findsOneWidget);
      expect(find.textContaining('+0'), findsNothing);
      expect(find.textContaining('монет'), findsNothing);
    });
  });
}

Widget _resultCard(MiniGameReward reward) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: MiniGameResultCard(
          result: MiniGameSessionResult(
            outcome: MiniGameResult.completed,
            title: 'Отличная игра!',
            message: 'Сыграем ещё?',
            reward: reward,
          ),
          onReplay: () {},
          onChooseAnother: () {},
        ),
      ),
    ),
  );
}
