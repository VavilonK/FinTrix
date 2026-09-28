import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/core/state/app_scope.dart';
import 'package:finance_pet/core/storage/app_database.dart';
import 'package:finance_pet/core/storage/app_state_repository.dart';
import 'package:finance_pet/core/theme/app_theme.dart';
import 'package:finance_pet/features/adult/presentation/adult_dashboard_screen.dart';
import 'package:finance_pet/features/adult/presentation/widgets/period_details_sheet.dart';
import 'package:finance_pet/features/budget/domain/budget_plan.dart';
import 'package:finance_pet/features/periods/domain/game_period.dart';
import 'package:finance_pet/features/pet_progression/domain/pet_progression.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  testWidgets('dashboard shows profile, goal, periods, and pet stage', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AppController()
      ..updateChildProfile(name: 'Лена', age: 9)
      ..savings = 2700
      ..completedTasks = 48
      ..achievedGoals = 1
      ..petGrowthPoints = 55
      ..completedGamePeriods.add(
        _period(
          id: 'normal_1',
          locationId: 'museum',
          stageStart: PetGrowthStage.little,
          stageEnd: PetGrowthStage.growing,
        ),
      );
    addTearDown(controller.dispose);

    await _pumpDashboard(tester, controller);

    expect(find.text('Лена'), findsOneWidget);
    expect(find.text('9 лет'), findsOneWidget);
    expect(find.text('Накопить на велосипед'), findsOneWidget);
    expect(find.text('2 700 / 5 000 монет'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Последний игровой день'), 350);
    expect(find.text('+145'), findsOneWidget);

    await tester.dragUntilVisible(
      find.byKey(const ValueKey('adult_period_normal_1')),
      find.byType(ListView),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('adult_period_normal_1')));
    await tester.pumpAndSettle();
    expect(find.byType(PeriodDetailsSheet), findsOneWidget);
    expect(find.text('Музей'), findsOneWidget);
    expect(find.text('Стадия 1 → Стадия 2'), findsOneWidget);
    Navigator.of(tester.element(find.byType(PeriodDetailsSheet))).pop();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Развитие питомца'), 400);
    expect(find.text('Рыжик подрос'), findsOneWidget);
    expect(find.text('55 / 90'), findsOneWidget);
  });

  testWidgets('demo dashboard shows only demo periods', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AppController()
      ..runMode = AppRunMode.demo
      ..completedGamePeriods.addAll([
        _period(id: 'normal_only', locationId: 'museum'),
        _period(id: 'demo_only', locationId: 'science_center', isDemo: true),
      ]);
    addTearDown(controller.dispose);

    await _pumpDashboard(tester, controller);
    expect(find.text('Демонстрационный профиль'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('adult_period_demo_only')),
      400,
    );

    expect(
      find.byKey(const ValueKey('adult_period_demo_only')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('adult_period_normal_only')),
      findsNothing,
    );
  });

  testWidgets('dashboard lists concrete completed goals', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AppController()..completedGoalIds.add('bicycle');
    addTearDown(controller.dispose);

    await _pumpDashboard(tester, controller);
    await tester.scrollUntilVisible(find.text('Достигнутые цели'), 300);

    expect(find.text('Велосипед'), findsOneWidget);
    expect(find.text('Пока нет завершённых целей.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling profile deletion keeps state unchanged', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AppController()..balance = 777;
    addTearDown(controller.dispose);
    await _pumpDashboard(tester, controller);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('adult_delete_profile')),
      500,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('adult_delete_profile')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('adult_delete_profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('adult_delete_cancel')));
    await tester.pumpAndSettle();

    expect(controller.balance, 777);
    expect(find.byType(AdultDashboardScreen), findsOneWidget);
  });

  testWidgets('parent edits child name and age', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AppController();
    addTearDown(controller.dispose);

    await _pumpDashboard(tester, controller);
    await tester.tap(find.byKey(const ValueKey('adult_edit_child_name')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('adult_child_name_field')),
      'Лена',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('adult_child_age_11')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('adult_child_profile_save')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('adult_child_profile_save')));
    await tester.pumpAndSettle();

    expect(controller.childName, 'Лена');
    expect(controller.age, 11);
  });

  group('adult data isolation', () {
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

    test('deleting normal profile resets it without changing demo', () async {
      final controller = AppController(repository: repository)
        ..balance = 777
        ..updateChildProfile(name: 'Обычный профиль');
      await repository.save(controller.toSnapshot());
      await controller.enterDemoMode(now: DateTime(2026, 9, 23));
      controller.balance = 333;
      await repository.save(controller.toSnapshot());
      await controller.exitDemoMode();

      expect(await controller.deleteCurrentProfileData(), isTrue);
      final normal = await repository.loadProfile(AppRunMode.normal);
      final demo = await repository.loadProfile(AppRunMode.demo);

      expect(normal.snapshot, isNull);
      expect(controller.parentSetupCompleted, isFalse);
      expect(demo.snapshot!.balance, 333);
    });

    test('resetting demo keeps normal profile unchanged', () async {
      final controller = AppController(repository: repository)..balance = 888;
      await repository.save(controller.toSnapshot());
      await controller.enterDemoMode(now: DateTime(2026, 9, 23));
      controller.balance = 222;
      await repository.save(controller.toSnapshot());

      await controller.resetDemoMode(now: DateTime(2026, 9, 23, 12));
      final normal = await repository.loadProfile(AppRunMode.normal);
      final demo = await repository.loadProfile(AppRunMode.demo);

      expect(normal.snapshot!.balance, 888);
      expect(demo.snapshot!.balance, 1250);
      expect(demo.snapshot!.demoPeriodIndex, 1);
    });
  });
}

Future<void> _pumpDashboard(
  WidgetTester tester,
  AppController controller,
) async {
  await tester.pumpWidget(
    AppScope(
      controller: controller,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const AdultDashboardScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

GamePeriod _period({
  required String id,
  required String locationId,
  bool isDemo = false,
  PetGrowthStage stageStart = PetGrowthStage.growing,
  PetGrowthStage stageEnd = PetGrowthStage.growing,
}) {
  const pet = PetStateSnapshot(mood: 75, satiety: 65, care: 70);
  return GamePeriod(
    id: id,
    sequenceNumber: isDemo ? 5 : 4,
    startedAt: DateTime(2026, 9, 22, 9),
    completedAt: DateTime(2026, 9, 22, 18),
    status: GamePeriodStatus.completed,
    startingBalance: 1100,
    startingSavings: 2500,
    selectedGoalIdAtStart: 'bicycle',
    goalProgressAtStart: 0.5,
    budgetPlanSnapshot: const BudgetPlan(
      essentialsPlanned: 500,
      wantsPlanned: 300,
      savingsPlanned: 300,
    ),
    budgetWasConfirmed: true,
    earnedCoins: 145,
    essentialSpent: 55,
    wantSpent: 30,
    depositedToSavings: 40,
    completedTaskCount: 12,
    correctTaskCount: 10,
    missionId: 'mission_$id',
    locationId: locationId,
    themeId: 'mixed',
    endingBalance: 1160,
    endingSavings: 2540,
    goalProgressAtEnd: 0.508,
    petStateAtStart: pet,
    petStateAtEnd: pet,
    isDemoPeriod: isDemo,
    growthPointsAwarded: 18,
    petGrowthPointsAtStart: 37,
    petGrowthPointsAtEnd: 55,
    petStageAtStart: stageStart,
    petStageAtEnd: stageEnd,
    growthEvaluated: true,
    trainedThemeIds: const ['math', 'finance', 'logic', 'memory'],
  );
}
