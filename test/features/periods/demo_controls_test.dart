import 'package:finance_pet/app/app.dart';
import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/features/adult/domain/parent_access_service.dart';
import 'package:finance_pet/features/events/domain/game_event.dart';
import 'package:finance_pet/features/periods/domain/game_period.dart';
import 'package:finance_pet/features/periods/presentation/demo_control_sheet.dart';
import 'package:finance_pet/features/periods/presentation/period_summary_screen.dart';
import 'package:finance_pet/features/pet_progression/domain/pet_progression.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppController _controller() => AppController(
  parentAccessService: ParentAccessService(
    MemoryParentCredentialStore(),
    const UnavailableParentBiometricAuthenticator(),
  ),
);

Future<AppController> _demo() async {
  final c = _controller();
  await c.enterDemoMode(now: DateTime(2026, 9, 23, 10));
  return c;
}

void main() {
  test('demo tools do nothing outside the demo', () async {
    final c = _controller();
    final balance = c.balance;
    expect(c.setDemoGrowthStage(PetGrowthStage.grown), isFalse);
    expect(await c.jumpToDemoDay(3), isFalse);
    expect(c.setDemoHungry(true), isFalse);
    expect(c.addDemoCoins(500), isFalse);
    expect(c.petGrowthStage, PetGrowthStage.little);
    expect(c.balance, balance);
  });

  test('growth stage can be switched in both directions', () async {
    final c = await _demo();
    for (final stage in [
      PetGrowthStage.grown,
      PetGrowthStage.growing,
      PetGrowthStage.little,
    ]) {
      expect(c.setDemoGrowthStage(stage), isTrue);
      expect(c.petGrowthStage, stage);
    }
  });

  test('jumping to a day starts it fresh and forgets later days', () async {
    final c = await _demo();
    for (var day = 1; day <= 3; day++) {
      c.missionForToday();
      c.completeCurrentPeriod();
      if (day < 3) await c.startNextDemoPeriod();
    }
    expect(c.completedGamePeriods.where((p) => p.isDemoPeriod), hasLength(3));

    expect(await c.jumpToDemoDay(2), isTrue);
    expect(c.demoPeriodIndex, 2);
    expect(c.activeGamePeriod!.status, GamePeriodStatus.active);
    expect(c.activeGamePeriod!.sequenceNumber, 2);
    expect(c.activeGamePeriod!.locationId, 'game_center');
    expect(c.completedGamePeriods.map((p) => p.sequenceNumber), [1]);
    // The day's event plays again.
    expect(c.checkDailyEvent(), GameEventId.scamCall);

    expect(await c.jumpToDemoDay(5), isTrue);
    expect(c.demoPeriodIndex, 5);
    expect(c.pendingEvent, isNull);
    expect(await c.jumpToDemoDay(6), isFalse);
    expect(await c.jumpToDemoDay(0), isFalse);
  });

  test('hunger toggle and test coins', () async {
    final c = await _demo();
    c.setDemoHungry(true);
    expect(c.petState.isHungry, isTrue);
    c.setDemoHungry(false);
    expect(c.petState.isHungry, isFalse);
    final balance = c.balance;
    c.addDemoCoins(500);
    expect(c.balance, balance + 500);
  });

  test('every demo day has a description', () {
    for (var day = 1; day <= 5; day++) {
      expect(demoDayDescription(day), isNotEmpty);
    }
    expect(demoDayDescription(2), contains('Неожиданный звонок'));
    expect(demoDayDescription(4), contains('Рыжик поранил лапку'));
  });

  testWidgets('panel switches stage, day and opens the summary', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = await _demo();
    await tester.pumpWidget(App(controller: c));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    showDemoControlSheet(context);
    await tester.pumpAndSettle();
    expect(find.text('Панель демо'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('demo_stage_grown')));
    await tester.pumpAndSettle();
    expect(c.petGrowthStage, PetGrowthStage.grown);

    await tester.tap(find.byKey(const ValueKey('demo_day_3')));
    await tester.pumpAndSettle();
    expect(c.demoPeriodIndex, 3);
    expect(find.text('Панель демо'), findsNothing);

    showDemoControlSheet(context);
    await tester.pumpAndSettle();
    final finish = find.byKey(const ValueKey('demo_finish_day'));
    await tester.ensureVisible(finish);
    await tester.tap(finish);
    await tester.pumpAndSettle();
    expect(find.byType(PeriodSummaryScreen), findsOneWidget);
    expect(c.activeGamePeriod!.status, GamePeriodStatus.completed);
    await tester.pumpWidget(const SizedBox());
  });
}
