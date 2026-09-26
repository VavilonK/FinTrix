import '../../../../core/assets/app_assets.dart';
import '../../domain/pet_models.dart';

/// Visual base pose derived from the persisted [PetState]; never stored.
enum PetBaseState {
  happy,
  hungry;

  static PetBaseState of(PetState pet) =>
      pet.isHungry ? PetBaseState.hungry : PetBaseState.happy;
}

/// The clip currently shown on Home. Idle clips loop; the rest play once.
enum PetAnimationState {
  happyIdle,
  hungryIdle,
  petHappy,
  petHungry,
  feedHappyBasic,
  feedHappyHealthy,
  feedHappyTreat,
  feedHungryBasic,
  feedHungryHealthy,
  feedHungryTreat;

  PetAnimationDefinition get definition =>
      PetAnimationCatalog.definitions[this]!;

  bool get isIdle => this == happyIdle || this == hungryIdle;
}

class PetAnimationDefinition {
  const PetAnimationDefinition({
    required this.asset,
    required this.stillAsset,
    required this.duration,
    required this.loops,
    required this.startState,
    required this.endState,
    this.anchorWindow = Duration.zero,
  });

  final String asset;

  /// Anchor frame shown before the first decoded frame and under reduce motion.
  final String stillAsset;

  /// Real playback length of the runtime asset (sum of its frame durations).
  final Duration duration;
  final bool loops;
  final PetBaseState startState;
  final PetBaseState endState;

  /// For looping idles: the opening span whose frames still match the anchor
  /// pose, so an action may cut in there without a visible jump.
  final Duration anchorWindow;

  bool get isStill => asset == stillAsset;
}

abstract final class PetAnimationCatalog {
  static const _happy = PetBaseState.happy;
  static const _hungry = PetBaseState.hungry;

  static const definitions = <PetAnimationState, PetAnimationDefinition>{
    PetAnimationState.happyIdle: PetAnimationDefinition(
      asset: AppAssets.foxHappyIdle,
      stillAsset: AppAssets.foxHappyStill,
      duration: Duration(milliseconds: 4967),
      loops: true,
      startState: _happy,
      endState: _happy,
      // Frames 0-21 stay within codec noise of frame 0; later frames tilt the head.
      anchorWindow: Duration(milliseconds: 733),
    ),
    // No looping hungry idle was delivered: the hungry anchor frame is used.
    PetAnimationState.hungryIdle: PetAnimationDefinition(
      asset: AppAssets.foxHungryStill,
      stillAsset: AppAssets.foxHungryStill,
      duration: Duration.zero,
      loops: true,
      startState: _hungry,
      endState: _hungry,
    ),
    PetAnimationState.petHappy: PetAnimationDefinition(
      asset: AppAssets.foxPetHappy,
      stillAsset: AppAssets.foxHappyStill,
      duration: Duration(milliseconds: 3500),
      loops: false,
      startState: _happy,
      endState: _happy,
    ),
    PetAnimationState.petHungry: PetAnimationDefinition(
      asset: AppAssets.foxPetHungry,
      stillAsset: AppAssets.foxHungryStill,
      duration: Duration(milliseconds: 3500),
      loops: false,
      startState: _hungry,
      endState: _hungry,
    ),
    PetAnimationState.feedHappyBasic: PetAnimationDefinition(
      asset: AppAssets.foxFeedHappyBasic,
      stillAsset: AppAssets.foxHappyStill,
      duration: Duration(milliseconds: 5100),
      loops: false,
      startState: _happy,
      endState: _happy,
    ),
    PetAnimationState.feedHappyHealthy: PetAnimationDefinition(
      asset: AppAssets.foxFeedHappyHealthy,
      stillAsset: AppAssets.foxHappyStill,
      duration: Duration(milliseconds: 5100),
      loops: false,
      startState: _happy,
      endState: _happy,
    ),
    PetAnimationState.feedHappyTreat: PetAnimationDefinition(
      asset: AppAssets.foxFeedHappyTreat,
      stillAsset: AppAssets.foxHappyStill,
      duration: Duration(milliseconds: 5100),
      loops: false,
      startState: _happy,
      endState: _happy,
    ),
    PetAnimationState.feedHungryBasic: PetAnimationDefinition(
      asset: AppAssets.foxFeedHungryBasic,
      stillAsset: AppAssets.foxHungryStill,
      duration: Duration(milliseconds: 5100),
      loops: false,
      startState: _hungry,
      endState: _happy,
    ),
    PetAnimationState.feedHungryHealthy: PetAnimationDefinition(
      asset: AppAssets.foxFeedHungryHealthy,
      stillAsset: AppAssets.foxHungryStill,
      duration: Duration(milliseconds: 5100),
      loops: false,
      startState: _hungry,
      endState: _happy,
    ),
    PetAnimationState.feedHungryTreat: PetAnimationDefinition(
      asset: AppAssets.foxFeedHungryTreat,
      stillAsset: AppAssets.foxHungryStill,
      duration: Duration(milliseconds: 5100),
      loops: false,
      startState: _hungry,
      endState: _happy,
    ),
  };

  static PetAnimationState idleFor(PetBaseState base) => switch (base) {
    PetBaseState.happy => PetAnimationState.happyIdle,
    PetBaseState.hungry => PetAnimationState.hungryIdle,
  };

  static PetAnimationState petFor(PetBaseState base) => switch (base) {
    PetBaseState.happy => PetAnimationState.petHappy,
    PetBaseState.hungry => PetAnimationState.petHungry,
  };

  static PetAnimationState feedFor(
    PetBaseState base,
    FoodType food,
  ) => switch ((base, food)) {
    (PetBaseState.happy, FoodType.basic) => PetAnimationState.feedHappyBasic,
    (PetBaseState.happy, FoodType.healthy) =>
      PetAnimationState.feedHappyHealthy,
    (PetBaseState.happy, FoodType.treat) => PetAnimationState.feedHappyTreat,
    (PetBaseState.hungry, FoodType.basic) => PetAnimationState.feedHungryBasic,
    (PetBaseState.hungry, FoodType.healthy) =>
      PetAnimationState.feedHungryHealthy,
    (PetBaseState.hungry, FoodType.treat) => PetAnimationState.feedHungryTreat,
  };

  /// Clips that may be requested next from [base], idle first.
  static List<PetAnimationState> preloadFor(PetBaseState base) => [
    idleFor(base),
    petFor(base),
    for (final food in FoodType.values) feedFor(base, food),
    // A hungry feed ends in the happy idle, which must be ready at the cut.
    if (base == PetBaseState.hungry) PetAnimationState.happyIdle,
  ];
}
