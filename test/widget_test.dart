import 'package:finance_pet/app/app.dart';
import 'package:finance_pet/features/budget/presentation/budget_screen.dart';
import 'package:finance_pet/features/budget/domain/budget_usage.dart';
import 'package:finance_pet/features/home/presentation/home_screen.dart';
import 'package:finance_pet/core/state/app_scope.dart';
import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/features/adult/domain/parent_access_service.dart';
import 'package:finance_pet/features/goals/presentation/goals_screen.dart';
import 'package:finance_pet/features/missions/domain/mission_models.dart';
import 'package:finance_pet/features/missions/presentation/mission_checkpoint_screen.dart';
import 'package:finance_pet/features/missions/presentation/mission_complete_screen.dart';
import 'package:finance_pet/features/missions/presentation/mission_result_screen.dart';
import 'package:finance_pet/features/tasks/presentation/mission_intro_screen.dart';
import 'package:finance_pet/features/tasks/presentation/tasks_screen.dart';
import 'package:finance_pet/features/tasks/data/location_definitions.dart';
import 'package:finance_pet/features/missions/presentation/mission_task_screen.dart';
import 'package:finance_pet/features/profile/presentation/profile_screen.dart';
import 'package:finance_pet/features/play/presentation/play_hub_screen.dart';
import 'package:finance_pet/features/play/presentation/memory_game_screen.dart';
import 'package:finance_pet/features/play/presentation/odd_one_out_screen.dart';
import 'package:finance_pet/features/play/presentation/rock_paper_scissors_screen.dart';
import 'package:finance_pet/features/play/presentation/sequence_game_screen.dart';
import 'package:finance_pet/features/play/presentation/tic_tac_toe_screen.dart';
import 'package:flutter/material.dart';
import 'package:finance_pet/core/widgets/primary_gradient_button.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home screen has no layout errors on a Pixel 8 viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches between the five main tabs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());

    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(InkWell, 'Бюджет'));
    await tester.pumpAndSettle();

    expect(find.byType(BudgetScreen), findsOneWidget);
  });

  testWidgets('tasks screen has no layout errors on a Pixel 8 viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.tap(find.widgetWithText(InkWell, 'Задания'));
    await tester.pumpAndSettle();

    expect(find.byType(TasksScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('moscow_interactive_map')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('map_location_game_center')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Moscow map pans, zooms, and explains inactive locations', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.tap(find.widgetWithText(InkWell, 'Задания'));
    await tester.pumpAndSettle();

    final mapFinder = find.byKey(const ValueKey('moscow_interactive_map'));
    final viewer = tester.widget<InteractiveViewer>(mapFinder);
    final controller = viewer.transformationController!;
    final translationBefore = controller.value.getTranslation().x;
    await tester.drag(mapFinder, const Offset(-60, -30));
    await tester.pump();
    expect(controller.value.getTranslation().x, isNot(translationBefore));

    final scaleBefore = controller.value.getMaxScaleOnAxis();
    final center = tester.getCenter(mapFinder) - const Offset(0, 80);
    final firstFinger = await tester.createGesture(pointer: 11);
    final secondFinger = await tester.createGesture(pointer: 12);
    await firstFinger.down(center - const Offset(24, 0));
    await secondFinger.down(center + const Offset(24, 0));
    await firstFinger.moveTo(center - const Offset(64, 0));
    await secondFinger.moveTo(center + const Offset(64, 0));
    await tester.pump();
    await firstFinger.up();
    await secondFinger.up();
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(scaleBefore));

    final tasksContext = tester.element(find.byType(TasksScreen));
    final activeId = AppScope.of(tasksContext).missionForToday().locationId;
    final inactive = LocationDefinitions.all.firstWhere(
      (location) => location.id != activeId,
    );
    final mapSize = tester.getSize(mapFinder);
    const focusScale = 0.8;
    final point = Offset(
      inactive.normalizedPosition.dx * 1080,
      inactive.normalizedPosition.dy * 1280,
    );
    controller.value = Matrix4.identity()
      ..translateByDouble(
        mapSize.width / 2 - point.dx * focusScale,
        mapSize.height / 2 - point.dy * focusScale,
        0,
        1,
      )
      ..scaleByDouble(focusScale, focusScale, focusScale, 1);
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('map_location_${inactive.id}')));
    await tester.pumpAndSettle();
    expect(find.text(inactive.title), findsWidgets);
    expect(find.textContaining('Здесь тоже бывают задания'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home task card opens tasks and mission intro route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Посмотреть'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('moscow_interactive_map')),
      findsOneWidget,
    );

    await tester.tap(find.text('Отправиться'));
    await tester.pumpAndSettle();
    expect(find.byType(MissionIntroScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('starts the daily mission from the intro screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.tap(find.widgetWithText(InkWell, 'Задания'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отправиться'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mission_start')));
    await tester.pumpAndSettle();

    expect(find.byType(MissionTaskScreen), findsOneWidget);
    expect(find.text('Задание 1 из 12'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completes all 12 tasks, checkpoints, and returns home', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.tap(find.widgetWithText(InkWell, 'Задания'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отправиться'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mission_start')));
    await tester.pumpAndSettle();

    for (var index = 0; index < 12; index++) {
      final taskContext = tester.element(find.byType(MissionTaskScreen));
      final appState = AppScope.of(taskContext);
      final task = appState.currentTask!;

      if (task.type == MissionTaskType.budgetSplit) {
        final plus = find.byKey(
          ValueKey('budget_plus_${task.options.first.id}'),
        );
        final taps = (task.totalAmount ?? 0) ~/ task.stepAmount;
        for (var tap = 0; tap < taps; tap++) {
          await tester.tap(plus);
          await tester.pump();
        }
      } else if (task.type == MissionTaskType.classification) {
        for (final option in task.options) {
          await tester.tap(
            find.byKey(ValueKey('classify_${option.id}_${option.category}')),
          );
          await tester.pump();
        }
      } else {
        final optionId = task.acceptAnyOption
            ? task.options.first.id
            : task.correctOptionId;
        await tester.tap(find.byKey(ValueKey('mission_option_$optionId')));
        await tester.pump();
      }

      await tester.tap(find.byKey(const ValueKey('mission_submit')));
      await tester.pumpAndSettle();
      expect(find.byType(MissionResultScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('mission_next')));
      await tester.pumpAndSettle();

      if (index == 3 || index == 7) {
        expect(find.byType(MissionCheckpointScreen), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('checkpoint_continue')));
        await tester.pumpAndSettle();
      }
    }

    expect(find.byType(MissionCompleteScreen), findsOneWidget);
    final completeContext = tester.element(find.byType(MissionCompleteScreen));
    final appState = AppScope.of(completeContext);
    expect(appState.sessionCompletedTasks, 12);
    expect(appState.balance, greaterThanOrEqualTo(0));
    expect(appState.savings, greaterThanOrEqualTo(0));
    final updatedBalance = _formatCoins(appState.balance);
    final updatedSavings = _formatCoins(appState.savings);

    await tester.tap(find.byKey(const ValueKey('mission_return_home')));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text(updatedBalance), findsWidgets);
    expect(find.text(updatedSavings), findsWidgets);
    expect(appState.activeMission, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('child profile shows age as read-only information', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.tap(find.widgetWithText(InkWell, 'Профиль'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    final context = tester.element(find.byType(ProfileScreen));
    final appState = AppScope.of(context);
    expect(appState.age, 8);
    expect(appState.difficultyLevel, DifficultyLevel.junior);
    expect(find.byKey(const ValueKey('child_age_read_only')), findsOneWidget);
    expect(find.text('8 лет'), findsOneWidget);
    expect(find.byKey(const ValueKey('age_selector')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('goals sheet saves preset amount and updates shared state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.tap(find.widgetWithText(InkWell, 'Цели'));
    await tester.pumpAndSettle();
    expect(find.byType(GoalsScreen), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open_savings_sheet')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('open_savings_sheet')));
    await tester.pumpAndSettle();
    expect(find.text('Сколько отложим?'), findsOneWidget);

    final sliderFinder = find.byKey(const ValueKey('goal_amount_slider'));
    final valueBeforeDrag = tester.widget<Slider>(sliderFinder).value;
    await tester.drag(sliderFinder, const Offset(70, 0));
    await tester.pump();
    final valueAfterDrag = tester.widget<Slider>(sliderFinder).value;
    expect(valueAfterDrag, greaterThan(valueBeforeDrag));

    await tester.ensureVisible(find.byKey(const ValueKey('goal_preset_300')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goal_preset_300')));
    final saveConfirm = find.byKey(const ValueKey('goal_save_confirm'));
    await tester.ensureVisible(saveConfirm);
    await tester.pumpAndSettle();
    await tester.tap(saveConfirm);
    await tester.pumpAndSettle();
    expect(find.text('Отлично!'), findsOneWidget);

    final context = tester.element(find.byType(GoalsScreen));
    final appState = AppScope.of(context);
    expect(appState.balance, 950);
    expect(appState.savings, 2700);
    expect(appState.budgetUsage.savingsDeposited, 300);

    await tester.tap(find.byKey(const ValueKey('goal_savings_done')));
    await tester.pumpAndSettle();
    expect(find.text('950'), findsWidgets);
    expect(find.text('2 700'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a completed goal is displayed at 100 percent', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.tap(find.widgetWithText(InkWell, 'Цели'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(GoalsScreen));
    final appState = AppScope.of(context);
    appState.savings = appState.goalPrice;
    appState.notifyListeners();
    await tester.pumpAndSettle();

    expect(find.text('🎉 Мечта достигнута!'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.byKey(const ValueKey('complete_goal')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('child can take part of savings after seeing goal impact', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.tap(find.widgetWithText(InkWell, 'Цели'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(GoalsScreen));
    final appState = AppScope.of(context)
      ..balance = 1000
      ..savings = 250;
    appState.notifyListeners();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open_withdrawal_sheet')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('open_withdrawal_sheet')));
    await tester.pumpAndSettle();
    expect(find.text('Сколько возьмём?'), findsOneWidget);
    expect(find.byKey(const ValueKey('withdraw_preset_100')), findsOneWidget);
    expect(find.byKey(const ValueKey('withdraw_preset_300')), findsNothing);
    expect(find.byKey(const ValueKey('withdraw_preset_500')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('withdraw_preset_100')));
    await tester.pump();
    expect(find.text('До цели станет дальше на 100 монет.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('withdraw_confirm')));
    await tester.pumpAndSettle();
    expect(appState.balance, 1100);
    expect(appState.savings, 150);
    expect(tester.takeException(), isNull);
  });

  testWidgets('goal completion preserves remainder and enables a new goal', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.tap(find.widgetWithText(InkWell, 'Цели'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(GoalsScreen));
    final appState = AppScope.of(context)..savings = 5700;
    appState.notifyListeners();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('complete_goal')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('complete_goal')));
    await tester.pumpAndSettle();
    expect(find.text('Мечта достигнута!'), findsOneWidget);
    expect(find.text('Осталось в копилке: 700 монет'), findsOneWidget);
    expect(appState.completedGoalIds, contains('bicycle'));

    await tester.tap(find.byKey(const ValueKey('goal_completion_choose_next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goal_picker_scooter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm_goal_scooter')));
    await tester.pumpAndSettle();

    expect(appState.selectedGoalId, 'scooter');
    expect(appState.savings, 700);
    expect(find.text('Достигнута ✓'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('goals suggests the plan and confirms a larger deposit', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.tap(find.widgetWithText(InkWell, 'Цели'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open_savings_sheet')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('open_savings_sheet')));
    await tester.pumpAndSettle();

    expect(find.text('По плану: 400 монет'), findsOneWidget);
    expect(find.text('По плану — 400'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('goal_preset_500')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goal_preset_500')));
    final saveConfirm = find.byKey(const ValueKey('goal_save_confirm'));
    await tester.ensureVisible(saveConfirm);
    await tester.pumpAndSettle();
    await tester.tap(saveConfirm);
    await tester.pumpAndSettle();
    expect(find.textContaining('Всё равно отложить?'), findsOneWidget);

    final screenContext = tester.element(find.byType(GoalsScreen));
    final state = AppScope.of(screenContext);
    expect(state.balance, 1250);
    final confirm = find.byKey(const ValueKey('goal_overrun_confirm'));
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(state.balance, 750);
    expect(state.savings, 2900);
    expect(state.budgetUsage.savingsDeposited, 500);
    expect(
      find.text('Ты отложил даже больше, чем планировал!'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('budget draft persists and confirmation does not move money', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.tap(find.widgetWithText(InkWell, 'Бюджет'));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetScreen), findsOneWidget);

    final context = tester.element(find.byType(BudgetScreen));
    final appState = AppScope.of(context);
    final balanceBefore = appState.balance;
    final savingsBefore = appState.savings;
    var confirmButton = tester.widget<PrimaryGradientButton>(
      find.byKey(const ValueKey('budget_confirm')),
    );
    expect(confirmButton.onPressed, isNotNull);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('budget_essentials_minus')),
      180,
    );
    await tester.tap(find.byKey(const ValueKey('budget_essentials_minus')));
    await tester.pumpAndSettle();
    expect(appState.budgetPlan.essentialsPlanned, 450);
    confirmButton = tester.widget<PrimaryGradientButton>(
      find.byKey(const ValueKey('budget_confirm')),
    );
    expect(confirmButton.onPressed, isNull);

    await tester.tap(find.widgetWithText(InkWell, 'Цели'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, 'Бюджет'));
    await tester.pumpAndSettle();
    expect(appState.budgetPlan.essentialsPlanned, 450);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('budget_essentials_plus')),
      180,
    );
    await tester.tap(find.byKey(const ValueKey('budget_essentials_plus')));
    await tester.pumpAndSettle();
    confirmButton = tester.widget<PrimaryGradientButton>(
      find.byKey(const ValueKey('budget_confirm')),
    );
    expect(confirmButton.onPressed, isNotNull);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('budget_confirm')),
      180,
    );
    await tester.tap(find.byKey(const ValueKey('budget_confirm')));
    await tester.pump();
    expect(
      find.text('Отлично! Теперь у каждой монетки есть план.'),
      findsWidgets,
    );
    expect(appState.budgetPlanConfirmed, isTrue);
    expect(appState.balance, balanceBefore);
    expect(appState.savings, savingsBefore);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home balance sheet links to budget', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 250').first);
    await tester.pumpAndSettle();

    expect(find.text('Твой баланс'), findsOneWidget);
    expect(find.text('На важное'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('balance_open_budget')));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('feeding and petting update shared pet state', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.pumpAndSettle();
    final homeContext = tester.element(find.byType(HomeScreen));
    final state = AppScope.of(homeContext);
    final balanceBefore = state.balance;

    await tester.tap(find.byKey(const ValueKey('home_feed_pet')));
    await tester.pumpAndSettle();
    expect(find.text('Что купим?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('feed_basic')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('feed_confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('feed_confirm')));
    await tester.pumpAndSettle();
    expect(state.balance, balanceBefore - 20);
    expect(state.budgetUsage.essentialsSpent, 20);
    // Pet taps are ignored while the feeding clip plays; let it end.
    await tester.pump(const Duration(seconds: 15));

    final careBefore = state.petState.care;
    await tester.tap(find.byKey(const ValueKey('home_pet_fox')));
    await tester.pump();
    expect(state.petState.care, careBefore + 12);
    expect(find.byIcon(Icons.favorite_rounded), findsWidgets);
    await tester.pump(const Duration(milliseconds: 1400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('play action opens hub and tic tac toe', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home_play_pet')));
    await tester.pumpAndSettle();

    expect(find.byType(PlayHubScreen), findsOneWidget);
    expect(find.text('Крестики-нолики'), findsOneWidget);
    expect(find.text('Найди пары'), findsOneWidget);
    expect(find.text('Камень-ножницы-бумага'), findsOneWidget);
    expect(find.text('Повтори последовательность'), findsOneWidget);
    expect(find.text('Что лишнее?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open_tic_tac_toe')));
    await tester.pumpAndSettle();
    expect(find.byType(TicTacToeScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('tic_cell_0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all additional mini-games open from the shared catalog', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home_play_pet')));
    await tester.pumpAndSettle();

    final games = <(String, Type)>[
      ('open_memory_game', MemoryGameScreen),
      ('open_rock_paper_scissors', RockPaperScissorsScreen),
      ('open_sequence_game', SequenceGameScreen),
      ('open_odd_one_out', OddOneOutScreen),
    ];
    for (final (key, screenType) in games) {
      final gameCard = find.byKey(ValueKey(key));
      await tester.ensureVisible(gameCard);
      await tester.tap(gameCard);
      await tester.pumpAndSettle();
      expect(find.byType(screenType), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(PlayHubScreen), findsOneWidget);
    }
  });

  testWidgets('home quick actions and goal card use shell navigation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Как получить или распределить монеты?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('quick_open_goals')));
    await tester.pumpAndSettle();
    expect(find.byType(GoalsScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(InkWell, 'Главная'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Накопить на велосипед'));
    await tester.pumpAndSettle();
    expect(find.byType(GoalsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings update state and offer protected adult section', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(HomeScreen));
    final state = AppScope.of(context);
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(state.soundEnabled, isFalse);
    expect(
      find.byKey(const ValueKey('settings_adult_section')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('settings_enter_demo')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('feed sheet handles insufficient balance and links to tasks', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(HomeScreen));
    final state = AppScope.of(context)
      ..balance = 0
      ..notifyListeners();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('home_feed_pet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('feed_treat')));
    await tester.pumpAndSettle();
    // Without coins the item stays visible with the missing amount and
    // options instead of a buy button.
    expect(find.byKey(const ValueKey('feed_confirm')), findsNothing);
    expect(find.textContaining('не хватает 50 монет'), findsOneWidget);
    expect(state.balance, 0);

    final openTasks = find.byKey(const ValueKey('feed_open_tasks'));
    await tester.ensureVisible(openTasks);
    await tester.pumpAndSettle();
    await tester.tap(openTasks);
    await tester.pumpAndSettle();
    expect(find.byType(TasksScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('feed purchase over plan requires friendly confirmation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(HomeScreen));
    final state = AppScope.of(context)
      ..budgetUsage = const BudgetUsage(wantsSpent: 340)
      ..notifyListeners();
    final balanceBefore = state.balance;
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('home_feed_pet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('feed_treat')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('feed_confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('feed_confirm')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Всё равно купить?'), findsOneWidget);
    expect(state.balance, balanceBefore);

    final confirm = find.byKey(const ValueKey('feed_overrun_confirm'));
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(state.balance, balanceBefore - 50);
    expect(state.budgetUsage.wantsSpent, 390);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new income can be allocated without replacing the plan', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _configuredApp());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(HomeScreen));
    final state = AppScope.of(context)
      ..balance += 200
      ..notifyListeners();

    await tester.tap(find.widgetWithText(InkWell, 'Бюджет'));
    await tester.pumpAndSettle();
    expect(find.text('Осталось распределить 200 монет'), findsOneWidget);
    expect(find.textContaining('Появилось ещё'), findsNothing);
    expect(find.textContaining('Распределить ещё'), findsNothing);
    final plus = find.byKey(const ValueKey('budget_essentials_plus'));
    await tester.ensureVisible(plus);
    for (var index = 0; index < 4; index++) {
      await tester.tap(plus);
      await tester.pumpAndSettle();
    }
    expect(find.text('Все монеты распределены ✓'), findsOneWidget);
    expect(find.textContaining('Осталось распределить'), findsNothing);
    expect(state.budgetPlan.essentialsPlanned, 700);
    expect(state.totalBudgetAllocated, 1450);
    expect(state.balance, 1450);
    expect(tester.takeException(), isNull);
  });
}

Future<App> _configuredApp() async {
  final controller = AppController(
    parentAccessService: ParentAccessService(
      MemoryParentCredentialStore(),
      const UnavailableParentBiometricAuthenticator(),
    ),
  );
  await controller.createParentPin('4826');
  await controller.completeParentSetup(childName: 'Миша', age: 8);
  return App(controller: controller);
}

String _formatCoins(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
}
