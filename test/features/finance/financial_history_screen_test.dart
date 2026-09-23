import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/core/state/app_scope.dart';
import 'package:finance_pet/core/theme/app_theme.dart';
import 'package:finance_pet/features/adult/presentation/adult_dashboard_screen.dart';
import 'package:finance_pet/features/adult/presentation/widgets/period_details_sheet.dart';
import 'package:finance_pet/features/budget/domain/budget_plan.dart';
import 'package:finance_pet/features/finance/data/financial_transaction_repository.dart';
import 'package:finance_pet/features/finance/domain/financial_transaction.dart';
import 'package:finance_pet/features/finance/presentation/financial_history_screen.dart';
import 'package:finance_pet/features/periods/domain/game_period.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('history has a friendly empty state', (tester) async {
    final controller = AppController();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    expect(find.text('История пока пуста'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history renders transactions and filters by type', (
    tester,
  ) async {
    final repository = InMemoryFinancialTransactionRepository();
    await repository.add(
      _transaction('earning', FinancialTransactionType.earning),
    );
    await repository.add(
      _transaction('want', FinancialTransactionType.wantExpense),
    );
    await repository.add(
      _transaction('withdrawal', FinancialTransactionType.savingsWithdrawal),
    );
    await repository.add(
      _transaction('goal', FinancialTransactionType.goalPurchase),
    );
    final controller = AppController(financialTransactions: repository);
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    expect(find.text('Награда earning'), findsOneWidget);
    expect(find.text('Покупка want'), findsOneWidget);
    expect(find.text('Покупка withdrawal'), findsOneWidget);
    expect(find.text('Покупка goal'), findsOneWidget);
    await tester.tap(find.text('Получено'));
    await tester.pumpAndSettle();
    expect(find.text('Награда earning'), findsOneWidget);
    expect(find.text('Покупка want'), findsNothing);
    expect(find.text('Покупка withdrawal'), findsNothing);
    expect(find.text('Покупка goal'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adult dashboard shows recent operations and opens all history', (
    tester,
  ) async {
    final repository = InMemoryFinancialTransactionRepository();
    await repository.add(
      _transaction('adult', FinancialTransactionType.earning),
    );
    final controller = AppController(financialTransactions: repository);
    addTearDown(controller.dispose);
    await _pumpHome(tester, controller, const AdultDashboardScreen());

    await tester.scrollUntilVisible(find.text('Последние операции'), 350);
    expect(find.text('Награда adult'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('adult_open_financial_history')),
    );
    await tester.pumpAndSettle();
    expect(find.text('История операций'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('period details loads only operations for that period', (
    tester,
  ) async {
    final repository = InMemoryFinancialTransactionRepository();
    await repository.add(
      _transaction(
        'period',
        FinancialTransactionType.earning,
        gamePeriodId: 'period_1',
      ),
    );
    await repository.add(
      _transaction(
        'other',
        FinancialTransactionType.earning,
        gamePeriodId: 'period_2',
      ),
    );
    final controller = AppController(financialTransactions: repository);
    addTearDown(controller.dispose);
    await _pumpHome(
      tester,
      controller,
      Scaffold(body: PeriodDetailsSheet(period: _period())),
    );

    expect(find.text('Операции за этот день'), findsOneWidget);
    expect(find.text('Награда period'), findsOneWidget);
    expect(find.text('Награда other'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(WidgetTester tester, AppController controller) async {
  await _pumpHome(tester, controller, const FinancialHistoryScreen());
}

Future<void> _pumpHome(
  WidgetTester tester,
  AppController controller,
  Widget home,
) async {
  await tester.binding.setSurfaceSize(const Size(412, 915));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    AppScope(
      controller: controller,
      child: MaterialApp(theme: AppTheme.light, home: home),
    ),
  );
  await tester.pumpAndSettle();
}

FinancialTransaction _transaction(
  String id,
  FinancialTransactionType type, {
  String? gamePeriodId,
}) {
  final earning = type == FinancialTransactionType.earning;
  return FinancialTransaction(
    id: id,
    profileId: 'normal',
    gamePeriodId: gamePeriodId,
    createdAt: DateTime.now(),
    type: type,
    source: FinancialTransactionSource.system,
    title: earning ? 'Награда $id' : 'Покупка $id',
    amount: 10,
    balanceBefore: earning ? 100 : 110,
    balanceAfter: earning ? 110 : 100,
    savingsBefore: 50,
    savingsAfter: 50,
  );
}

GamePeriod _period() {
  const pet = PetStateSnapshot(mood: 70, satiety: 70, care: 70);
  return GamePeriod(
    id: 'period_1',
    sequenceNumber: 1,
    startedAt: DateTime(2026, 9, 23, 10),
    completedAt: DateTime(2026, 9, 23, 11),
    status: GamePeriodStatus.completed,
    startingBalance: 1000,
    startingSavings: 500,
    selectedGoalIdAtStart: 'bicycle',
    goalProgressAtStart: 0.1,
    budgetPlanSnapshot: const BudgetPlan(
      essentialsPlanned: 400,
      wantsPlanned: 300,
      savingsPlanned: 300,
    ),
    budgetWasConfirmed: true,
    earnedCoins: 10,
    essentialSpent: 0,
    wantSpent: 0,
    depositedToSavings: 0,
    completedTaskCount: 1,
    correctTaskCount: 1,
    missionId: 'mission_1',
    locationId: 'museum',
    themeId: 'finance',
    endingBalance: 1010,
    endingSavings: 500,
    goalProgressAtEnd: 0.1,
    petStateAtStart: pet,
    petStateAtEnd: pet,
    isDemoPeriod: false,
  );
}
