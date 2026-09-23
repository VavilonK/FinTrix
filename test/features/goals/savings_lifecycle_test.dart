import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/core/storage/app_database.dart';
import 'package:finance_pet/core/storage/app_state_repository.dart';
import 'package:finance_pet/core/storage/app_state_snapshot.dart';
import 'package:finance_pet/features/budget/domain/budget_usage.dart';
import 'package:finance_pet/features/finance/data/financial_transaction_repository.dart';
import 'package:finance_pet/features/finance/domain/financial_transaction.dart';
import 'package:finance_pet/features/goals/domain/savings_goal.dart';
import 'package:finance_pet/features/home/domain/pet_models.dart';
import 'package:finance_pet/features/periods/domain/game_period.dart';
import 'package:finance_pet/features/play/domain/mini_game_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  group('savings withdrawal', () {
    test(
      'moves existing currency and creates exactly one transaction',
      () async {
        final transactions = InMemoryFinancialTransactionRepository();
        final controller = AppController(financialTransactions: transactions)
          ..balance = 500
          ..savings = 1000;
        controller.missionForToday(now: DateTime(2026, 9, 23, 9));
        final usageBefore = controller.budgetUsage;
        final growthBefore = controller.petGrowthPoints;

        expect(
          controller.withdrawFromSavings(300, now: DateTime(2026, 9, 23, 10)),
          SavingsWithdrawalResult.success,
        );
        await controller.flushPersistence();

        expect(controller.balance, 800);
        expect(controller.savings, 700);
        expect(controller.balance + controller.savings, 1500);
        expect(controller.budgetUsage, same(usageBefore));
        expect(controller.petGrowthPoints, growthBefore);
        final history = await controller.recentFinancialTransactions();
        expect(history, hasLength(1));
        expect(history.single.type, FinancialTransactionType.savingsWithdrawal);
        expect(history.single.amount, 300);
        expect(history.single.balanceBefore, 500);
        expect(history.single.balanceAfter, 800);
        expect(history.single.savingsBefore, 1000);
        expect(history.single.savingsAfter, 700);
        expect(history.single.gamePeriodId, controller.activeGamePeriod?.id);
        controller.dispose();
      },
    );

    test(
      'rejects zero, negative, and excessive amounts without history',
      () async {
        final transactions = InMemoryFinancialTransactionRepository();
        final controller = AppController(financialTransactions: transactions)
          ..balance = 500
          ..savings = 1000;

        expect(
          controller.withdrawFromSavings(0),
          SavingsWithdrawalResult.invalidAmount,
        );
        expect(
          controller.withdrawFromSavings(-10),
          SavingsWithdrawalResult.invalidAmount,
        );
        expect(
          controller.withdrawFromSavings(1001),
          SavingsWithdrawalResult.insufficientSavings,
        );
        expect(controller.balance, 500);
        expect(controller.savings, 1000);
        expect(await controller.recentFinancialTransactions(), isEmpty);
        controller.dispose();
      },
    );
  });

  group('goal completion', () {
    test('is unavailable below target and available at target', () async {
      final transactions = InMemoryFinancialTransactionRepository();
      final controller = AppController(financialTransactions: transactions)
        ..savings = 4999;

      expect(controller.canCompleteSelectedGoal, isFalse);
      expect(
        controller.completeSelectedGoal(),
        GoalCompletionResult.insufficientSavings,
      );
      controller.savings = 5000;
      expect(controller.canCompleteSelectedGoal, isTrue);
      expect(controller.completeSelectedGoal(), GoalCompletionResult.success);
      expect(controller.savings, 0);
      expect(controller.completedGoalIds, contains('bicycle'));
      controller.dispose();
    });

    test(
      'preserves remainder and duplicate completion is idempotent',
      () async {
        final transactions = InMemoryFinancialTransactionRepository();
        final controller = AppController(financialTransactions: transactions)
          ..savings = 5700;
        final completedBefore = controller.achievedGoals;
        controller.missionForToday(now: DateTime(2026, 9, 23, 10));

        expect(
          controller.completeSelectedGoal(now: DateTime(2026, 9, 23, 10, 5)),
          GoalCompletionResult.success,
        );
        expect(controller.savings, 700);
        expect(controller.achievedGoals, completedBefore + 1);
        expect(
          controller.completeSelectedGoal(now: DateTime(2026, 9, 23, 10, 6)),
          GoalCompletionResult.alreadyCompleted,
        );
        expect(controller.savings, 700);
        expect(controller.achievedGoals, completedBefore + 1);
        await controller.flushPersistence();

        final history = await controller.recentFinancialTransactions();
        final purchases = history
            .where(
              (value) => value.type == FinancialTransactionType.goalPurchase,
            )
            .toList();
        expect(purchases, hasLength(1));
        expect(purchases.single.amount, 5000);
        expect(purchases.single.savingsBefore, 5700);
        expect(purchases.single.savingsAfter, 700);
        expect(purchases.single.gamePeriodId, controller.activeGamePeriod?.id);
        expect(controller.selectGoal('bicycle'), isFalse);
        expect(controller.selectGoal('scooter'), isTrue);
        controller.dispose();
      },
    );
  });

  test('currency conservation matches each operation type', () {
    final controller = AppController()
      ..balance = 1000
      ..savings = 1000;
    final initial = controller.balance + controller.savings;
    expect(controller.addToSavings(100), SavingsDepositResult.success);
    expect(controller.balance + controller.savings, initial);
    expect(
      controller.withdrawFromSavings(200),
      SavingsWithdrawalResult.success,
    );
    expect(controller.balance + controller.savings, initial);

    controller.completeMiniGame(MiniGameType.ticTacToe, MiniGameResult.won);
    expect(controller.balance + controller.savings, initial);
    expect(
      controller.spendCoins(50, ExpenseCategory.essential),
      SpendCoinsResult.success,
    );
    expect(controller.balance + controller.savings, initial - 50);

    controller.savings = 5700;
    final beforePurchase = controller.balance + controller.savings;
    expect(controller.completeSelectedGoal(), GoalCompletionResult.success);
    expect(controller.balance + controller.savings, beforePurchase - 5000);
    controller.dispose();
  });

  test('withdrawal and completed goal survive repository restart', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final stateRepository = AppStateRepository(database);
    final transactionRepository = FinancialTransactionRepository(database);
    final controller =
        AppController(
            repository: stateRepository,
            financialTransactions: transactionRepository,
          )
          ..balance = 1000
          ..savings = 5700;

    expect(
      controller.withdrawFromSavings(300),
      SavingsWithdrawalResult.success,
    );
    expect(controller.completeSelectedGoal(), GoalCompletionResult.success);
    await controller.flushPersistence();
    final loaded = await stateRepository.loadProfile(AppRunMode.normal);
    final restored = AppController.fromSnapshot(
      snapshot: loaded.snapshot!,
      repository: stateRepository,
      financialTransactions: transactionRepository,
    );

    expect(restored.balance, 1300);
    expect(restored.savings, 400);
    expect(restored.completedGoalIds, contains('bicycle'));
    final history = await restored.recentFinancialTransactions();
    expect(history, hasLength(2));
    expect(
      history.map((value) => value.type),
      containsAll([
        FinancialTransactionType.savingsWithdrawal,
        FinancialTransactionType.goalPurchase,
      ]),
    );
    controller.dispose();
    restored.dispose();
  });

  test('legacy snapshot does not guess completed goal identities', () {
    final json = AppController().toSnapshot().toJson()
      ..['schemaVersion'] = 5
      ..remove('completedGoalIds');
    final restored = AppStateSnapshot.fromJson(json);

    expect(restored.achievedGoals, 2);
    expect(restored.completedGoalIds, isEmpty);
  });

  test('normal and demo completed goals remain isolated', () async {
    final controller = AppController()..savings = 5000;
    expect(controller.completeSelectedGoal(), GoalCompletionResult.success);
    await controller.enterDemoMode(now: DateTime(2026, 9, 23, 11));
    expect(controller.completedGoalIds, isEmpty);
    controller.savings = 5000;
    expect(controller.completeSelectedGoal(), GoalCompletionResult.success);
    await controller.exitDemoMode(now: DateTime(2026, 9, 23, 12));
    expect(controller.completedGoalIds, contains('bicycle'));

    await controller.enterDemoMode(now: DateTime(2026, 9, 23, 13));
    await controller.resetDemoMode(now: DateTime(2026, 9, 23, 14));
    expect(controller.completedGoalIds, isEmpty);
    await controller.exitDemoMode(now: DateTime(2026, 9, 23, 15));
    expect(controller.completedGoalIds, contains('bicycle'));
    controller.dispose();
  });
}
