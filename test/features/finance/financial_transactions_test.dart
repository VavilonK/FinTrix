import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/features/budget/domain/budget_usage.dart';
import 'package:finance_pet/features/finance/data/financial_transaction_repository.dart';
import 'package:finance_pet/features/finance/domain/financial_transaction.dart';
import 'package:finance_pet/features/home/domain/pet_models.dart';
import 'package:finance_pet/features/missions/domain/mission_models.dart';
import 'package:finance_pet/features/periods/domain/game_period.dart';
import 'package:finance_pet/features/play/domain/mini_game_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('financial ledger', () {
    late InMemoryFinancialTransactionRepository repository;
    late AppController controller;

    setUp(() {
      repository = InMemoryFinancialTransactionRepository();
      controller = AppController(
        now: DateTime(2026, 9, 23, 10),
        financialTransactions: repository,
      );
    });

    tearDown(() => controller.dispose());

    test('records expenses and deposit but no mini-game income', () async {
      expect(
        controller.spendCoins(40, ExpenseCategory.essential, title: 'Обед'),
        SpendCoinsResult.success,
      );
      expect(
        controller.feedPet(
          FoodType.treat,
          now: DateTime(2026, 9, 23, 10, 1),
          confirmPlanOverrun: true,
        ),
        FeedPetResult.success,
      );
      controller.completeMiniGame(
        MiniGameType.matchingPairs,
        MiniGameResult.won,
        now: DateTime(2026, 9, 23, 10, 2),
      );
      expect(
        controller.addToSavings(100, confirmPlanOverrun: true),
        SavingsDepositResult.success,
      );
      await controller.flushPersistence();

      final transactions = await controller.recentFinancialTransactions();
      expect(transactions, hasLength(3));
      expect(
        transactions.map((value) => value.type),
        containsAll([
          FinancialTransactionType.essentialExpense,
          FinancialTransactionType.wantExpense,
          FinancialTransactionType.savingsDeposit,
        ]),
      );
      final essential = transactions.singleWhere(
        (value) => value.type == FinancialTransactionType.essentialExpense,
      );
      expect(essential.balanceBefore, 1250);
      expect(essential.balanceAfter, 1210);
      final deposit = transactions.singleWhere(
        (value) => value.type == FinancialTransactionType.savingsDeposit,
      );
      expect(deposit.balanceBefore - deposit.balanceAfter, 100);
      expect(deposit.savingsAfter - deposit.savingsBefore, 100);
    });

    test('failed operations create no transaction', () async {
      expect(
        controller.spendCoins(5000, ExpenseCategory.want),
        SpendCoinsResult.insufficientFunds,
      );
      expect(
        controller.addToSavings(5000),
        SavingsDepositResult.insufficientFunds,
      );
      controller.completeMiniGame(MiniGameType.ticTacToe, MiniGameResult.lost);
      await controller.flushPersistence();

      expect(await controller.recentFinancialTransactions(), isEmpty);
    });

    test('wrong mission answer creates no transaction', () async {
      controller.startMission(_mission(economyType: TaskEconomyType.earning));
      controller.submitCurrentTask(selectedOptionId: 'wrong');
      controller.submitCurrentTask(selectedOptionId: 'wrong');
      await controller.flushPersistence();

      expect(await controller.recentFinancialTransactions(), isEmpty);
    });

    test('simulation has reward but never creates an expense', () async {
      controller.startMission(
        _mission(economyType: TaskEconomyType.simulation, optionSpend: 75),
      );
      controller.submitCurrentTask(selectedOptionId: 'correct');
      await controller.flushPersistence();

      final transactions = await controller.recentFinancialTransactions();
      expect(transactions, hasLength(1));
      expect(transactions.single.type, FinancialTransactionType.earning);
      expect(transactions.single.amount, 20);
    });

    test('real mission expense and reward are idempotent', () async {
      controller.startMission(
        _mission(
          economyType: TaskEconomyType.realExpense,
          optionSpend: 60,
          category: ExpenseCategory.essential,
        ),
      );
      controller.submitCurrentTask(selectedOptionId: 'correct');
      controller.submitCurrentTask(selectedOptionId: 'correct');
      await controller.flushPersistence();

      final transactions = await controller.recentFinancialTransactions();
      expect(transactions, hasLength(2));
      expect(
        transactions.where(
          (value) => value.type == FinancialTransactionType.essentialExpense,
        ),
        hasLength(1),
      );
      expect(
        transactions.where(
          (value) => value.type == FinancialTransactionType.earning,
        ),
        hasLength(1),
      );
      expect(transactions.every((value) => value.gamePeriodId != null), isTrue);
    });

    test(
      'normal and demo histories stay isolated and demo reset is scoped',
      () async {
        controller.spendCoins(10, ExpenseCategory.want);
        await controller.enterDemoMode(now: DateTime(2026, 9, 23, 11));
        controller.spendCoins(20, ExpenseCategory.want);
        await controller.flushPersistence();

        expect(
          await controller.financialTransactionsForProfile(AppRunMode.normal),
          hasLength(1),
        );
        expect(
          await controller.financialTransactionsForProfile(AppRunMode.demo),
          hasLength(1),
        );

        await controller.resetDemoMode(now: DateTime(2026, 9, 23, 12));
        expect(
          await controller.financialTransactionsForProfile(AppRunMode.demo),
          isEmpty,
        );
        expect(
          await controller.financialTransactionsForProfile(AppRunMode.normal),
          hasLength(1),
        );
      },
    );

    test('normal profile deletion leaves demo history untouched', () async {
      controller.spendCoins(10, ExpenseCategory.want);
      await controller.enterDemoMode(now: DateTime(2026, 9, 23, 11));
      controller.spendCoins(20, ExpenseCategory.want);
      await controller.exitDemoMode(now: DateTime(2026, 9, 23, 12));

      expect(await controller.deleteCurrentProfileData(), isTrue);
      expect(
        await controller.financialTransactionsForProfile(AppRunMode.normal),
        isEmpty,
      );
      expect(
        await controller.financialTransactionsForProfile(AppRunMode.demo),
        hasLength(1),
      );
    });
  });
}

DailyMission _mission({
  required TaskEconomyType economyType,
  int optionSpend = 0,
  ExpenseCategory? category,
}) {
  return DailyMission(
    id: 'ledger_mission',
    date: DateTime(2026, 9, 23),
    locationId: 'museum',
    title: 'Проверка истории',
    theme: MissionTheme.shopping,
    estimatedMinutes: 1,
    maxReward: 20,
    tasks: [
      MissionTask(
        id: 'ledger_task',
        templateId: 'ledger_template',
        title: 'Выбери покупку',
        description: 'Учимся принимать решение',
        type: MissionTaskType.choice,
        theme: MissionTheme.shopping,
        taskTheme: TaskTheme.finance,
        economyType: economyType,
        difficulty: MissionDifficulty.easy,
        estimatedSeconds: 10,
        rewardCoins: 20,
        xpReward: 5,
        correctOptionId: 'correct',
        explanation: 'Верно',
        expenseCategory: category,
        options: [
          MissionTaskOption(
            id: 'correct',
            label: 'Подходит',
            spendCoins: optionSpend,
            expenseCategory: category,
          ),
          const MissionTaskOption(id: 'wrong', label: 'Не подходит'),
        ],
      ),
    ],
  );
}
