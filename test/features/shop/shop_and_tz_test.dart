import 'dart:convert';

import 'package:finance_pet/app/app.dart';
import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/core/storage/app_state_snapshot.dart';
import 'package:finance_pet/features/adult/domain/parent_access_service.dart';
import 'package:finance_pet/features/budget/domain/budget_plan.dart';
import 'package:finance_pet/features/budget/domain/budget_usage.dart';
import 'package:finance_pet/features/budget/presentation/plan_fact_card.dart';
import 'package:finance_pet/features/finance/domain/financial_transaction.dart';
import 'package:finance_pet/features/home/domain/pet_models.dart';
import 'package:finance_pet/features/home/presentation/home_screen.dart';
import 'package:finance_pet/features/home/presentation/pet_messages.dart';
import 'package:finance_pet/features/missions/data/daily_mission_generator.dart';
import 'package:finance_pet/features/missions/data/daily_task_templates.dart';
import 'package:finance_pet/features/missions/domain/mission_models.dart';
import 'package:finance_pet/features/shop/domain/shop_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppController _controller({DateTime? now}) => AppController(
  now: now,
  parentAccessService: ParentAccessService(
    MemoryParentCredentialStore(),
    const UnavailableParentBiometricAuthenticator(),
  ),
);

ShopItem _item(String id) => ShopCatalog.byId(id)!;

void main() {
  group('shop catalog', () {
    test('at least 8 purchases of both kinds (ТЗ 2.6)', () {
      final items = ShopCatalog.items;
      expect(items.length, greaterThanOrEqualTo(8));
      expect(
        items.where((item) => item.category == ExpenseCategory.essential),
        isNotEmpty,
      );
      expect(
        items.where((item) => item.category == ExpenseCategory.want),
        isNotEmpty,
      );
      for (final item in items) {
        expect(item.cost, greaterThan(0));
        expect(item.effectsLabel, isNotEmpty, reason: item.id);
      }
      expect(
        ShopCatalog.section(ShopSection.care).map((item) => item.category),
        everyElement(ExpenseCategory.essential),
      );
      expect(
        ShopCatalog.section(ShopSection.toys),
        everyElement(predicate<ShopItem>((item) => item.isPermanent)),
      );
    });

    test('food keeps its existing prices and effects', () {
      for (final type in FoodType.values) {
        final item = ShopCatalog.foodItem(type);
        expect(item.cost, type.cost);
        expect(item.satietyGain, type.satietyGain);
      }
      expect(
        ShopCatalog.foodItem(FoodType.basic).effectsLabel,
        'Сытость +30 · Настроение +4',
      );
    });
  });

  group('buying', () {
    test('care item raises care, spends coins and is logged', () async {
      final now = DateTime(2026, 9, 1, 10);
      final c = _controller(now: now);
      c.petState = c.petState.copyWith(care: 40);
      final balance = c.balance;
      final (result, receipt) = c.buyItem(_item('care_brush'), now: now);
      expect(result, ShopPurchaseResult.success);
      expect(c.balance, balance - 20);
      expect(c.petState.care, 60);
      expect(c.budgetUsage.essentialsSpent, 20);
      expect(receipt!.careDelta, 20);
      final history = await c.recentFinancialTransactions();
      expect(history.first.title, 'Расчёска');
      expect(history.first.type, FinancialTransactionType.essentialExpense);
    });

    test('room item is bought once, lifts mood and stays', () {
      final now = DateTime(2026, 9, 1, 10);
      final c = _controller(now: now);
      c.budgetPlan = const BudgetPlan(
        essentialsPlanned: 500,
        wantsPlanned: 500,
        savingsPlanned: 250,
      );
      c.petState = c.petState.copyWith(mood: 50);
      final (first, _) = c.buyItem(_item('toy_teddy'), now: now);
      expect(first, ShopPurchaseResult.success);
      expect(c.petState.mood, 65);
      expect(c.ownedRoomItems, contains('toy_teddy'));
      final balance = c.balance;
      final (second, receipt) = c.buyItem(_item('toy_teddy'), now: now);
      expect(second, ShopPurchaseResult.alreadyOwned);
      expect(receipt, isNull);
      expect(c.balance, balance);
    });

    test('no purchase without enough coins, balance never negative', () {
      final now = DateTime(2026, 9, 1, 10);
      final c = _controller(now: now)..balance = 30;
      final (result, _) = c.buyItem(_item('toy_pouf'), now: now);
      expect(result, ShopPurchaseResult.insufficientFunds);
      expect(c.balance, 30);
      expect(c.ownedRoomItems, isEmpty);
    });

    test('a want over plan needs confirmation', () {
      final now = DateTime(2026, 9, 1, 10);
      final c = _controller(now: now);
      c.budgetPlan = const BudgetPlan(
        essentialsPlanned: 500,
        wantsPlanned: 50,
        savingsPlanned: 700,
      );
      final (result, _) = c.buyItem(_item('toy_star_garland'), now: now);
      expect(result, ShopPurchaseResult.requiresConfirmation);
      final (confirmed, _) = c.buyItem(
        _item('toy_star_garland'),
        now: now,
        confirmPlanOverrun: true,
      );
      expect(confirmed, ShopPurchaseResult.success);
    });
  });

  group('pet state over time', () {
    test('care and mood fade slowly; room items slow the mood loss', () {
      final start = DateTime(2026, 9, 1, 10);
      final plain = _controller(now: start);
      final cosy = _controller(now: start)
        ..ownedRoomItems.addAll(['toy_teddy', 'toy_star_garland', 'toy_pouf']);
      for (final c in [plain, cosy]) {
        c.petState = const PetState(mood: 80, satiety: 80, care: 80);
        c.refreshPetState(now: start.add(const Duration(hours: 1)));
      }
      // 4 intervals of 15 minutes.
      expect(plain.petState.satiety, 68);
      expect(plain.petState.care, 72);
      expect(plain.petState.mood, 72);
      expect(cosy.petState.mood, greaterThan(plain.petState.mood));
    });
  });

  group('feedback texts', () {
    test('feeding that leaves the pet hungry says so', () {
      final receipt = PurchaseReceipt(
        item: ShopCatalog.foodItem(FoodType.treat),
        balanceBefore: 100,
        balanceAfter: 50,
        petBefore: const PetState(mood: 50, satiety: 5, care: 50),
        petAfter: const PetState(mood: 65, satiety: 20, care: 50),
      );
      expect(PetMessages.reactionTo(receipt), contains('ещё голоден'));
      expect(PetMessages.summaryOf(receipt), contains('−50 монет'));
      expect(PetMessages.summaryOf(receipt), contains('Сытость +15'));
    });

    test('bubble names the cause of a low status', () {
      final c = _controller();
      c.petState = const PetState(mood: 80, satiety: 12, care: 80);
      expect(PetMessages.forState(c), contains('сытость 12'));
      c.petState = const PetState(mood: 80, satiety: 80, care: 10);
      expect(PetMessages.forState(c), contains('забота 10'));
      c.petState = const PetState(mood: 10, satiety: 80, care: 80);
      expect(PetMessages.forState(c), contains('настроение 10'));
    });

    test('hints switch the advice on and off', () {
      final c = _controller()
        ..petState = const PetState(mood: 80, satiety: 80, care: 80)
        ..budgetPlanConfirmed = false;
      expect(PetMessages.forState(c), contains('Бюджете'));
      c.setHintsEnabled(false);
      expect(PetMessages.forState(c), 'Финансовые приключения вместе!');
    });
  });

  group('plan and fact', () {
    const plan = BudgetPlan(
      essentialsPlanned: 100,
      wantsPlanned: 50,
      savingsPlanned: 100,
    );
    String advice({
      bool confirmed = true,
      int essential = 80,
      int want = 40,
      int saved = 100,
    }) => PlanFactCard.adviceFor(
      plan: plan,
      planConfirmed: confirmed,
      essentialSpent: essential,
      wantSpent: want,
      saved: saved,
    );

    test('advice explains the result and the next step', () {
      expect(advice(), contains('уложился'));
      expect(advice(want: 70), contains('больше плана на 20'));
      expect(advice(essential: 130), contains('важное'));
      expect(advice(saved: 40), contains('меньше плана на 60'));
      expect(advice(confirmed: false), contains('Подтвердить бюджет'));
    });
  });

  group('parent, pet name and intro', () {
    test('parent reward adds coins with a reason in history', () async {
      final c = _controller();
      final balance = c.balance;
      expect(c.awardCoinsFromParent(33, 'нет'), isFalse);
      expect(c.awardCoinsFromParent(50, 'За помощь по дому'), isTrue);
      expect(c.balance, balance + 50);
      final history = await c.recentFinancialTransactions();
      expect(history.first.source, FinancialTransactionSource.parent);
      expect(history.first.description, 'За помощь по дому');
    });

    test('pet name, intro flag and room items persist', () {
      final c = _controller();
      expect(c.setPetName('   '), isFalse);
      expect(c.setPetName('  Лис   Тимка '), isTrue);
      expect(c.petName, 'Лис Тимка');
      c
        ..requestTutorial()
        ..ownedRoomItems.add('toy_pouf');
      final json = jsonDecode(jsonEncode(c.toSnapshot().toJson()));
      final restored = AppStateSnapshot.fromJson(json as Map<String, dynamic>);
      expect(restored.petName, 'Лис Тимка');
      expect(restored.tutorialSeen, isFalse);
      expect(restored.ownedRoomItems, ['toy_pouf']);
      // Older saves: default name, intro already seen, empty room.
      final legacy = Map<String, dynamic>.of(json)
        ..remove('petName')
        ..remove('tutorialSeen')
        ..remove('ownedRoomItems');
      final old = AppStateSnapshot.fromJson(legacy);
      expect(old.petName, AppController.defaultPetName);
      expect(old.tutorialSeen, isTrue);
      expect(old.ownedRoomItems, isEmpty);
    });
  });

  group('missions', () {
    test('every generated mission has a savings scenario', () {
      for (var day = 1; day <= 20; day++) {
        final mission = const DailyMissionGenerator().generate(
          date: DateTime(2026, 3, day),
          childName: 'Миша',
          age: 8,
          difficulty: DifficultyLevel.junior,
          balance: 500,
        );
        expect(
          mission.tasks.map((task) => task.templateId),
          contains(isIn(DailyTaskTemplates.savingsTemplateIds)),
          reason: 'day $day',
        );
      }
    });

    test('reward split changes balance and piggy bank differently', () {
      final task = DailyTaskTemplates.build(
        templateId: 'split_reward',
        id: 't',
        difficulty: DifficultyLevel.junior,
        variant: 0,
        availableBalance: 100,
      );
      expect(task.acceptAnyOption, isTrue);
      final totals = {
        for (final option in task.options)
          option.id: (option.rewardCoins, option.savingsReward),
      };
      expect(totals.values.toSet(), hasLength(3));
      for (final option in task.options) {
        expect(option.feedback, isNotNull);
      }
    });

    test('real purchases show every price and allow postponing a want', () {
      final task = DailyTaskTemplates.build(
        templateId: 'cultural_outing',
        id: 't',
        difficulty: DifficultyLevel.junior,
        variant: 0,
        availableBalance: 35,
      );
      final priced = task.options.where((option) => option.spendCoins > 0);
      expect(priced.map((option) => option.spendCoins), [30, 40, 45]);
      expect(
        task.options.map((option) => option.label),
        contains('Не покупать сейчас'),
      );
    });
  });

  testWidgets('shop opens from Home and buying a toy puts it in the room', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = _controller();
    await c.createParentPin('4826');
    await c.completeParentSetup(childName: 'Миша', age: 8);
    c.budgetPlan = const BudgetPlan(
      essentialsPlanned: 500,
      wantsPlanned: 500,
      savingsPlanned: 250,
    );
    await tester.pumpWidget(App(controller: c));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home_feed_pet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shop_tab_toys')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shop_toy_teddy')));
    await tester.pumpAndSettle();
    final buy = find.byKey(const ValueKey('feed_confirm'));
    await tester.ensureVisible(buy);
    await tester.pumpAndSettle();
    await tester.tap(buy);
    await tester.pump();
    expect(c.ownedRoomItems, contains('toy_teddy'));
    expect(find.byKey(const ValueKey('room_toy_teddy')), findsOneWidget);
    expect(find.byKey(const ValueKey('purchase_feedback')), findsOneWidget);
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpWidget(const SizedBox());
  });
}
