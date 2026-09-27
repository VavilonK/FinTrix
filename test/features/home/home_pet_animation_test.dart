import 'package:finance_pet/app/app.dart';
import 'package:finance_pet/core/state/app_controller.dart';
import 'package:finance_pet/core/state/app_scope.dart';
import 'package:finance_pet/core/widgets/app_bottom_navigation.dart';
import 'package:finance_pet/features/adult/domain/parent_access_service.dart';
import 'package:finance_pet/features/home/domain/pet_models.dart';
import 'package:finance_pet/features/home/presentation/home_screen.dart';
import 'package:finance_pet/features/home/presentation/pet_animation/pet_animation_coordinator.dart';
import 'package:finance_pet/features/home/presentation/pet_animation/pet_animation_models.dart';
import 'package:finance_pet/features/home/presentation/pet_animation/pet_animation_viewport.dart';
import 'package:finance_pet/features/pet_progression/domain/pet_progression.dart';
import 'package:finance_pet/features/home/presentation/widgets/pet_actions.dart';
import 'package:finance_pet/features/home/presentation/widgets/home_task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<AppController> launch(
    WidgetTester tester, {
    int? satiety,
    int? growthPoints,
  }) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AppController(
      parentAccessService: ParentAccessService(
        MemoryParentCredentialStore(),
        const UnavailableParentBiometricAuthenticator(),
      ),
    );
    await controller.createParentPin('4826');
    await controller.completeParentSetup(childName: 'Миша', age: 8);
    if (satiety != null) {
      // Same as a restart restoring a persisted hungry pet.
      controller.petState = controller.petState.copyWith(satiety: satiety);
    }
    if (growthPoints != null) {
      // Same as a restart restoring persisted growth progress.
      controller.petGrowthPoints = growthPoints;
    }
    await tester.pumpWidget(App(controller: controller));
    await tester.pumpAndSettle();
    return controller;
  }

  PetAnimationCoordinator animation(WidgetTester tester) => tester
      .widget<PetAnimationViewport>(
        find.byType(PetAnimationViewport, skipOffstage: false),
      )
      .coordinator;

  Future<void> feed(WidgetTester tester, FoodType food) async {
    await tester.tap(find.byKey(const ValueKey('home_feed_pet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('feed_${food.name}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('feed_confirm')));
    await tester.pump();
  }

  /// Lets any action clip time out (clips never decode in fake async).
  Future<void> settleClips(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();
  }

  testWidgets('restart with a hungry pet opens on the hungry idle', (
    tester,
  ) async {
    await launch(tester, satiety: 10);
    expect(animation(tester).current, PetAnimationState.hungryIdle);
    await settleClips(tester);
  });

  testWidgets('happy pet opens on the happy idle', (tester) async {
    await launch(tester);
    expect(animation(tester).current, PetAnimationState.happyIdle);
  });

  for (final food in FoodType.values) {
    testWidgets('happy ${food.name} feed plays after the purchase', (
      tester,
    ) async {
      final controller = await launch(tester);
      final balance = controller.balance;
      await feed(tester, food);
      expect(controller.balance, balance - food.cost);
      expect(
        animation(tester).current,
        PetAnimationCatalog.feedFor(PetBaseState.happy, food),
      );
      await settleClips(tester);
      expect(animation(tester).current, PetAnimationState.happyIdle);
    });
  }

  testWidgets('hungry basic feed turns satiety before the transition plays', (
    tester,
  ) async {
    final controller = await launch(tester, satiety: 10);
    await feed(tester, FoodType.basic);
    expect(controller.petState.isHungry, isFalse);
    final coordinator = animation(tester);
    expect(coordinator.current, PetAnimationState.feedHungryBasic);
    expect(coordinator.baseState, PetBaseState.happy);
    await settleClips(tester);
    expect(coordinator.current, PetAnimationState.happyIdle);
  });

  testWidgets('insufficient coins start no feed animation', (tester) async {
    final controller = await launch(tester);
    controller
      ..balance = 0
      ..notifyListeners();
    await tester.pump();
    final coordinator = animation(tester);
    final playId = coordinator.playId;
    await feed(tester, FoodType.treat);
    expect(find.textContaining('Сейчас монет не хватает'), findsOneWidget);
    expect(coordinator.playId, playId);
    expect(coordinator.current, PetAnimationState.happyIdle);
  });

  testWidgets('closing the feed sheet starts no animation', (tester) async {
    await launch(tester);
    final coordinator = animation(tester);
    final playId = coordinator.playId;
    await tester.tap(find.byKey(const ValueKey('home_feed_pet')));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Чем угостим Рыжика?'))).pop();
    await tester.pumpAndSettle();
    expect(coordinator.playId, playId);
  });

  testWidgets('rapid double tap pets once', (tester) async {
    final controller = await launch(tester);
    final care = controller.petState.care;
    await tester.tap(find.byKey(const ValueKey('home_pet_fox')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const ValueKey('home_pet_fox')));
    await tester.pump();
    expect(controller.petState.care, care + 12);
    expect(animation(tester).current, PetAnimationState.petHappy);
    // Feeding is blocked as well while the clip plays.
    await tester.tap(find.byKey(const ValueKey('home_feed_pet')));
    await tester.pumpAndSettle();
    expect(find.text('Чем угостим Рыжика?'), findsNothing);
    await settleClips(tester);
    expect(animation(tester).current, PetAnimationState.happyIdle);
  });

  testWidgets('petting a hungry fox keeps it hungry', (tester) async {
    final controller = await launch(tester, satiety: 10);
    await tester.tap(find.byKey(const ValueKey('home_pet_fox')));
    await tester.pump();
    expect(animation(tester).current, PetAnimationState.petHungry);
    await settleClips(tester);
    expect(controller.petState.isHungry, isTrue);
    expect(animation(tester).current, PetAnimationState.hungryIdle);
  });

  testWidgets('Home rebuilds do not restart the clip', (tester) async {
    final controller = await launch(tester);
    final coordinator = animation(tester);
    final playId = coordinator.playId;
    controller.notifyListeners();
    await tester.pump();
    expect(coordinator.playId, playId);
  });

  testWidgets('leaving Home mid-action returns to the domain idle', (
    tester,
  ) async {
    await launch(tester, satiety: 10);
    await feed(tester, FoodType.healthy);
    final coordinator = animation(tester);
    expect(coordinator.current, PetAnimationState.feedHungryHealthy);
    final destinations = find.descendant(
      of: find.byType(AppBottomNavigation),
      matching: find.byType(InkWell),
    );
    await tester.tap(destinations.at(1));
    await tester.pumpAndSettle();
    expect(coordinator.current, PetAnimationState.happyIdle);
    await tester.tap(destinations.at(0));
    await tester.pumpAndSettle();
    expect(coordinator.current, PetAnimationState.happyIdle);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('backgrounding mid-action returns to the domain idle', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.byKey(const ValueKey('home_pet_fox')));
    await tester.pump();
    final coordinator = animation(tester);
    expect(coordinator.isActionPlaying, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(coordinator.current, PetAnimationState.happyIdle);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));
    expect(coordinator.current, PetAnimationState.happyIdle);
  });

  testWidgets('reduce motion still feeds and pets without clips', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    final controller = await launch(tester, satiety: 10);
    expect(find.byKey(const ValueKey('pet_static_frame')), findsOneWidget);
    await feed(tester, FoodType.basic);
    await tester.pumpAndSettle();
    expect(controller.petState.isHungry, isFalse);
    expect(animation(tester).current, PetAnimationState.happyIdle);
    final care = controller.petState.care;
    await tester.tap(find.byKey(const ValueKey('home_pet_fox')));
    await tester.pump();
    expect(controller.petState.care, care + 12);
    expect(animation(tester).isActionPlaying, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(
      AppScope.of(tester.element(find.byType(HomeScreen))).petState.isHungry,
      isFalse,
    );
  });

  group('growth stages on Home', () {
    String asset(WidgetTester tester) =>
        animation(tester).currentDefinition.asset;

    testWidgets('restart with Stage 3 + hungry opens the Stage 3 hungry idle', (
      tester,
    ) async {
      final controller = await launch(
        tester,
        satiety: 10,
        growthPoints: PetProgressionConfig.grownThreshold,
      );
      expect(controller.petGrowthStage, PetGrowthStage.grown);
      expect(
        asset(tester),
        PetAnimationCatalog.setFor(PetGrowthStage.grown).hungryIdle,
      );
    });

    testWidgets('Stage 1 -> 2 -> 3 switches Home to the new stage idle', (
      tester,
    ) async {
      final controller = await launch(tester);
      expect(
        asset(tester),
        PetAnimationCatalog.setFor(PetGrowthStage.little).happyIdle,
      );
      final layout = {
        for (final type in [PetActions, HomeTaskCard, AppBottomNavigation])
          type: tester.getRect(find.byType(type)),
      };
      for (final (points, stage) in [
        (PetProgressionConfig.growingThreshold, PetGrowthStage.growing),
        (PetProgressionConfig.grownThreshold, PetGrowthStage.grown),
      ]) {
        controller
          ..petGrowthPoints = points
          ..notifyListeners();
        await tester.pump();
        expect(asset(tester), PetAnimationCatalog.setFor(stage).happyIdle);
        // Only the fox grows; the controls around it keep their places.
        for (final entry in layout.entries) {
          expect(tester.getRect(find.byType(entry.key)), entry.value);
        }
      }
    });

    testWidgets('Stage 3 feed blocks a pet tap and ends in Stage 3 idle', (
      tester,
    ) async {
      final controller = await launch(
        tester,
        satiety: 10,
        growthPoints: PetProgressionConfig.grownThreshold,
      );
      await feed(tester, FoodType.treat);
      final set = PetAnimationCatalog.setFor(PetGrowthStage.grown);
      // Treat (+15) from 10 still leaves him hungry: no transition clip.
      expect(asset(tester), set.hungryIdle);
      controller.petState = controller.petState.copyWith(satiety: 80);
      controller.notifyListeners();
      await tester.pump();
      await feed(tester, FoodType.treat);
      expect(asset(tester), set.feedHappyTreat);
      final care = controller.petState.care;
      await tester.tap(find.byKey(const ValueKey('home_pet_fox')));
      await tester.pump();
      expect(controller.petState.care, care);
      expect(asset(tester), set.feedHappyTreat);
      await settleClips(tester);
      expect(asset(tester), set.happyIdle);
    });
  });
}
