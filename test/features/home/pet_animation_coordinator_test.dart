import 'package:finance_pet/features/home/domain/pet_models.dart';
import 'package:finance_pet/features/home/presentation/pet_animation/pet_animation_coordinator.dart';
import 'package:finance_pet/features/home/presentation/pet_animation/pet_animation_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const happy = PetBaseState.happy;
  const hungry = PetBaseState.hungry;

  /// Plays an action to its last frame the way the viewport reports it.
  void finish(PetAnimationCoordinator coordinator) {
    final id = coordinator.playId;
    coordinator.actionStarted(id);
    coordinator.actionCompleted(id);
  }

  test('base state follows the existing hunger threshold', () {
    PetState pet(int satiety) => PetState(mood: 50, satiety: satiety, care: 50);
    expect(PetBaseState.of(pet(PetState.hungrySatietyThreshold - 1)), hungry);
    expect(PetBaseState.of(pet(PetState.hungrySatietyThreshold)), happy);
    expect(PetBaseState.of(pet(0)), hungry);
    expect(PetBaseState.of(pet(100)), happy);
  });

  test('every clip is anchored between the right idle states', () {
    for (final state in PetAnimationState.values) {
      final definition = state.definition;
      expect(definition.loops, state.isIdle, reason: '$state');
      if (!state.isIdle) {
        expect(definition.duration, greaterThan(Duration.zero));
      }
    }
    for (final food in FoodType.values) {
      expect(
        PetAnimationCatalog.feedFor(happy, food).definition.endState,
        happy,
      );
      final hungryFeed = PetAnimationCatalog.feedFor(hungry, food).definition;
      expect(hungryFeed.startState, hungry);
      expect(hungryFeed.endState, happy);
    }
  });

  group('transitions', () {
    final cases =
        <
          (
            String,
            PetBaseState,
            PetAnimationState,
            PetAnimationState,
            void Function(PetAnimationCoordinator),
          )
        >[
          (
            'happy → pet → happy',
            happy,
            PetAnimationState.petHappy,
            PetAnimationState.happyIdle,
            (c) => c.playPet(),
          ),
          (
            'hungry → pet → hungry',
            hungry,
            PetAnimationState.petHungry,
            PetAnimationState.hungryIdle,
            (c) => c.playPet(),
          ),
          (
            'happy → basic → happy',
            happy,
            PetAnimationState.feedHappyBasic,
            PetAnimationState.happyIdle,
            (c) => c.playFeed(FoodType.basic, after: happy),
          ),
          (
            'happy → healthy → happy',
            happy,
            PetAnimationState.feedHappyHealthy,
            PetAnimationState.happyIdle,
            (c) => c.playFeed(FoodType.healthy, after: happy),
          ),
          (
            'happy → treat → happy',
            happy,
            PetAnimationState.feedHappyTreat,
            PetAnimationState.happyIdle,
            (c) => c.playFeed(FoodType.treat, after: happy),
          ),
          (
            'hungry → basic → happy',
            hungry,
            PetAnimationState.feedHungryBasic,
            PetAnimationState.happyIdle,
            (c) => c.playFeed(FoodType.basic, after: happy),
          ),
          (
            'hungry → healthy → happy',
            hungry,
            PetAnimationState.feedHungryHealthy,
            PetAnimationState.happyIdle,
            (c) => c.playFeed(FoodType.healthy, after: happy),
          ),
          (
            'hungry → treat → happy',
            hungry,
            PetAnimationState.feedHungryTreat,
            PetAnimationState.happyIdle,
            (c) => c.playFeed(FoodType.treat, after: happy),
          ),
        ];
    for (final (name, base, action, end, play) in cases) {
      test(name, () {
        final coordinator = PetAnimationCoordinator(baseState: base);
        addTearDown(coordinator.dispose);
        expect(coordinator.current, PetAnimationCatalog.idleFor(base));
        play(coordinator);
        expect(coordinator.current, action);
        expect(coordinator.isActionPlaying, isTrue);
        expect(action.definition.startState, base);
        finish(coordinator);
        expect(coordinator.current, end);
        expect(coordinator.isActionPlaying, isFalse);
        expect(end.definition.startState, coordinator.baseState);
      });
    }
  });

  test('petting a hungry fox does not end hunger visually', () {
    final coordinator = PetAnimationCoordinator(baseState: hungry);
    addTearDown(coordinator.dispose);
    coordinator.playPet();
    finish(coordinator);
    expect(coordinator.baseState, hungry);
    expect(coordinator.current, PetAnimationState.hungryIdle);
  });

  test('a second action during a clip is ignored, not queued', () {
    final coordinator = PetAnimationCoordinator(baseState: happy);
    addTearDown(coordinator.dispose);
    expect(coordinator.playPet(), isTrue);
    final playId = coordinator.playId;
    for (var i = 0; i < 15; i++) {
      expect(coordinator.playPet(), isFalse);
      expect(coordinator.playFeed(FoodType.treat, after: happy), isFalse);
    }
    expect(coordinator.playId, playId);
    finish(coordinator);
    expect(coordinator.current, PetAnimationState.happyIdle);
    expect(coordinator.isActionPlaying, isFalse);
  });

  test('stale completions from an earlier clip are ignored', () {
    final coordinator = PetAnimationCoordinator(baseState: happy);
    addTearDown(coordinator.dispose);
    coordinator.playPet();
    final stale = coordinator.playId;
    finish(coordinator);
    coordinator.playFeed(FoodType.basic, after: happy);
    coordinator.actionCompleted(stale);
    expect(coordinator.current, PetAnimationState.feedHappyBasic);
  });

  test('feeding that leaves the fox hungry shows no happy transition', () {
    final coordinator = PetAnimationCoordinator(baseState: hungry);
    addTearDown(coordinator.dispose);
    expect(coordinator.playFeed(FoodType.treat, after: hungry), isTrue);
    expect(coordinator.current, PetAnimationState.hungryIdle);
    expect(coordinator.isActionPlaying, isFalse);
  });

  test('domain changes during an action apply when it ends', () {
    final coordinator = PetAnimationCoordinator(baseState: happy);
    addTearDown(coordinator.dispose);
    coordinator.playPet();
    coordinator.syncBaseState(hungry);
    expect(coordinator.current, PetAnimationState.petHappy);
    finish(coordinator);
    expect(coordinator.current, PetAnimationState.hungryIdle);
  });

  test('idle follows the domain immediately when no action plays', () {
    final coordinator = PetAnimationCoordinator(baseState: happy);
    addTearDown(coordinator.dispose);
    final id = coordinator.playId;
    coordinator.syncBaseState(happy);
    expect(coordinator.playId, id, reason: 'same state must not restart');
    coordinator.syncBaseState(hungry);
    expect(coordinator.current, PetAnimationState.hungryIdle);
    coordinator.syncBaseState(happy);
    expect(coordinator.current, PetAnimationState.happyIdle);
  });

  test('interrupt returns to the current domain idle', () {
    final coordinator = PetAnimationCoordinator(baseState: hungry);
    addTearDown(coordinator.dispose);
    coordinator.playFeed(FoodType.basic, after: happy);
    coordinator.interrupt();
    expect(coordinator.current, PetAnimationState.happyIdle);
  });

  test('reduce motion keeps actions functional without clips', () {
    final coordinator = PetAnimationCoordinator(
      baseState: hungry,
      animationsEnabled: false,
    );
    addTearDown(coordinator.dispose);
    expect(coordinator.playPet(), isTrue);
    expect(coordinator.isActionPlaying, isFalse);
    expect(coordinator.playFeed(FoodType.basic, after: happy), isTrue);
    expect(coordinator.current, PetAnimationState.happyIdle);

    coordinator.setAnimationsEnabled(true);
    coordinator.playPet();
    coordinator.setAnimationsEnabled(false);
    expect(coordinator.isActionPlaying, isFalse);
  });

  // testWidgets runs in fake time, so pump advances the watchdog timers.
  testWidgets('watchdog ends a clip after its real duration', (tester) async {
    final coordinator = PetAnimationCoordinator(baseState: happy);
    addTearDown(coordinator.dispose);
    coordinator.playFeed(FoodType.basic, after: happy);
    coordinator.actionStarted(coordinator.playId);
    await tester.pump(const Duration(milliseconds: 5100));
    expect(coordinator.current, PetAnimationState.feedHappyBasic);
    await tester.pump(PetAnimationCoordinator.endGrace);
    expect(coordinator.current, PetAnimationState.happyIdle);
  });

  testWidgets('watchdog abandons a clip that never starts', (tester) async {
    final coordinator = PetAnimationCoordinator(baseState: hungry);
    addTearDown(coordinator.dispose);
    coordinator.playPet();
    await tester.pump(
      const Duration(milliseconds: 3500) + PetAnimationCoordinator.startTimeout,
    );
    expect(coordinator.current, PetAnimationState.hungryIdle);
  });

  test('preload covers every clip reachable from the base state', () {
    expect(PetAnimationCatalog.preloadFor(happy), [
      PetAnimationState.happyIdle,
      PetAnimationState.petHappy,
      PetAnimationState.feedHappyBasic,
      PetAnimationState.feedHappyHealthy,
      PetAnimationState.feedHappyTreat,
    ]);
    expect(PetAnimationCatalog.preloadFor(hungry), [
      PetAnimationState.hungryIdle,
      PetAnimationState.petHungry,
      PetAnimationState.feedHungryBasic,
      PetAnimationState.feedHungryHealthy,
      PetAnimationState.feedHungryTreat,
      PetAnimationState.happyIdle,
    ]);
  });
}
