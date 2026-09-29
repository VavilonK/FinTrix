import 'dart:convert';

import 'package:finance_pet/app/app.dart';
import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/core/storage/app_state_snapshot.dart';
import 'package:finance_pet/features/adult/domain/parent_access_service.dart';
import 'package:finance_pet/features/events/domain/game_event.dart';
import 'package:finance_pet/features/finance/domain/financial_transaction.dart';
import 'package:finance_pet/features/home/presentation/home_screen.dart';
import 'package:finance_pet/features/periods/domain/game_period.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppController _controller({DateTime? now}) => AppController(
  now: now,
  parentAccessService: ParentAccessService(
    MemoryParentCredentialStore(),
    const UnavailableParentBiometricAuthenticator(),
  ),
);

AppController _demoDay(int day) {
  final c = _controller(now: DateTime(2026, 9, 1, 10))
    ..runMode = AppRunMode.demo
    ..demoPeriodIndex = day;
  return c;
}

void main() {
  final now = DateTime(2026, 9, 1, 10);

  group('schedule', () {
    test('demo shows the scam on day 2 and the vet on day 4', () {
      expect(_demoDay(1).checkDailyEvent(now: now), isNull);
      expect(_demoDay(2).checkDailyEvent(now: now), GameEventId.scamCall);
      expect(_demoDay(3).checkDailyEvent(now: now), isNull);
      expect(_demoDay(4).checkDailyEvent(now: now), GameEventId.vetVisit);
    });

    test('an event starts only once per day', () {
      final c = _demoDay(2);
      expect(c.checkDailyEvent(now: now), GameEventId.scamCall);
      c.resolveEvent('hang_up', now: now);
      expect(c.checkDailyEvent(now: now), isNull);
    });

    test('a new profile gets no random event on its first days', () {
      final c = _controller(now: now);
      for (var day = 0; day < 30; day++) {
        expect(c.checkDailyEvent(now: now.add(Duration(days: day))), isNull);
      }
    });

    test('every option has an explanation and both events have advice', () {
      for (final id in GameEventId.values) {
        final event = GameEvents.of(id);
        expect(event.advice, isNotEmpty);
        expect(event.options.length, 3);
        for (final option in event.options) {
          expect(option.explanation, isNotEmpty, reason: option.id);
        }
      }
    });
  });

  group('scam call', () {
    test('telling the code loses coins and logs a loss', () async {
      final c = _demoDay(2)..checkDailyEvent(now: now);
      final balance = c.balance;
      final outcome = c.resolveEvent('tell_code', now: now)!;
      expect(c.balance, balance - GameEvents.scamLoss);
      expect(outcome.balanceAfter, c.balance);
      expect(c.pendingEvent, isNull);
      final log = await c.financialTransactionsForProfile(AppRunMode.demo);
      final loss = log.firstWhere(
        (entry) => entry.type == FinancialTransactionType.loss,
      );
      expect(loss.source, FinancialTransactionSource.event);
      expect(loss.amount, GameEvents.scamLoss);
    });

    test('the loss never makes the balance negative', () {
      final c = _demoDay(2)
        ..balance = 10
        ..checkDailyEvent(now: now);
      c.resolveEvent('tell_code', now: now);
      expect(c.balance, 0);
    });

    test('calling an adult is rewarded, hanging up changes nothing', () {
      final c = _demoDay(2)..checkDailyEvent(now: now);
      final balance = c.balance;
      c.resolveEvent('call_adult', now: now);
      expect(c.balance, balance + GameEvents.carefulReward);

      final other = _demoDay(2)..checkDailyEvent(now: now);
      final before = (other.balance, other.savings, other.petState.care);
      other.resolveEvent('hang_up', now: now);
      expect((other.balance, other.savings, other.petState.care), before);
    });
  });

  group('vet visit', () {
    test('paying from the wallet is an essential expense', () async {
      final c = _demoDay(4)..checkDailyEvent(now: now);
      final balance = c.balance;
      final savings = c.savings;
      c.resolveEvent('pay_balance', now: now);
      expect(c.balance, balance - GameEvents.vetCost);
      expect(c.savings, savings);
      final log = await c.financialTransactionsForProfile(AppRunMode.demo);
      expect(
        log.where(
          (entry) =>
              entry.type == FinancialTransactionType.essentialExpense &&
              entry.source == FinancialTransactionSource.event,
        ),
        hasLength(1),
      );
    });

    test('paying from savings keeps the wallet', () {
      final c = _demoDay(4)..checkDailyEvent(now: now);
      final balance = c.balance;
      final savings = c.savings;
      c.resolveEvent('pay_savings', now: now);
      expect(c.balance, balance);
      expect(c.savings, savings - GameEvents.vetCost);
    });

    test('unaffordable options are refused', () {
      final c = _demoDay(4)
        ..balance = 10
        ..savings = 5
        ..checkDailyEvent(now: now);
      expect(c.resolveEvent('pay_balance', now: now), isNull);
      expect(c.resolveEvent('pay_savings', now: now), isNull);
      expect(c.pendingEvent, GameEventId.vetVisit);
      expect(c.balance, 10);
      expect(c.savings, 5);
    });

    test('postponing lowers care and the vet comes back next day', () {
      final c = _demoDay(4)..checkDailyEvent(now: now);
      final care = c.petState.care;
      c.resolveEvent('postpone', now: now);
      expect(c.petState.care, care - GameEvents.postponeCareLoss);
      expect(c.pendingEvent, isNull);
      expect(c.checkDailyEvent(now: now), isNull);
      c.demoPeriodIndex = 5;
      expect(c.checkDailyEvent(now: now), GameEventId.vetVisit);
    });
  });

  test('event state survives a restart; old saves have none', () {
    final c = _demoDay(4)..checkDailyEvent(now: now);
    final json =
        jsonDecode(jsonEncode(c.toSnapshot().toJson())) as Map<String, dynamic>;
    final restored = AppStateSnapshot.fromJson(json);
    expect(restored.pendingEvent, 'vetVisit');
    expect(restored.lastEventId, 'vetVisit');
    final legacy = Map<String, dynamic>.of(json)
      ..remove('pendingEvent')
      ..remove('deferredEvent')
      ..remove('eventCheckKey')
      ..remove('lastEventKey')
      ..remove('lastEventId');
    final old = AppStateSnapshot.fromJson(legacy);
    expect(old.pendingEvent, isNull);
    expect(old.deferredEvent, isNull);
  });

  testWidgets('Home shows the event, then the outcome and advice', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = _controller();
    await c.createParentPin('4826');
    await c.completeParentSetup(childName: 'Миша', age: 8);
    c.pendingEvent = GameEventId.scamCall;
    await tester.pumpWidget(App(controller: c));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('event_title')), findsOneWidget);

    // Tapping outside does not close the event.
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('event_title')), findsOneWidget);

    final option = find.byKey(const ValueKey('event_option_call_adult'));
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('event_outcome')), findsOneWidget);
    expect(find.textContaining(GameEvents.scamCall.advice), findsOneWidget);

    final done = find.byKey(const ValueKey('event_done'));
    await tester.ensureVisible(done);
    await tester.tap(done);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('event_title')), findsNothing);
    expect(c.pendingEvent, isNull);
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('without coins for the vet the child is sent to tasks', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = _controller();
    await c.createParentPin('4826');
    await c.completeParentSetup(childName: 'Миша', age: 8);
    c
      ..balance = 10
      ..savings = 0
      ..pendingEvent = GameEventId.vetVisit;
    await tester.pumpWidget(App(controller: c));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('event_cannot_pay')), findsOneWidget);
    expect(find.text('Не хватает 30 монет'), findsOneWidget);
    final tasks = find.byKey(const ValueKey('event_open_tasks'));
    await tester.ensureVisible(tasks);
    await tester.tap(tasks);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('event_title')), findsNothing);
    expect(c.pendingEvent, GameEventId.vetVisit);
    await tester.pumpWidget(const SizedBox());
  });
}
